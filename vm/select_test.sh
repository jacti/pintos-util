#!/usr/bin/env bash

# Usage: select_test.sh [-q|-g] [-r]
#   -q|-g : 실행 모드 지정
#   -r    : clean & rebuild
if (( $# < 1 || $# > 2 )); then
  echo "Usage: $0 [-q|-g] [-r]"
  echo "  -q   : run tests quietly (no GDB stub)"
  echo "  -g   : attach via GDB stub (skip build)"
  echo "  -r   : force clean & full rebuild"
  exit 1
fi

MODE="$1"
if [[ "$MODE" != "-q" && "$MODE" != "-g" ]]; then
  echo "Usage: $0 [-q|-g] [-r]"
  exit 1
fi

# 두 번째 인자가 있으면 -r 체크
REBUILD=0
if (( $# == 2 )); then
  if [[ "$2" == "-r" ]]; then
    REBUILD=1
  else
    echo "Unknown option: $2"
    echo "Usage: $0 [-q|-g] [-r]"
    exit 1
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../activate"

CONFIG_FILE="${SCRIPT_DIR}/.test_config"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: .test_config 파일이 없습니다: ${CONFIG_FILE}" >&2
  exit 1
fi

declare -A config_pre_args    
declare -A config_post_args   
declare -A config_prog_args   
declare -A config_result      
declare -A GROUP_TESTS TEST_GROUP MENU_TESTS
declare -a ORDERED_GROUPS
tests=()

current_group=""

# ---- Progress UI utilities ----
SPINNER_PID=""
start_spinner() {
  # 사용법: start_spinner "메시지"
  local msg="$1"
  local chars='|/-\'
  local i=0
  # 커서 숨김
  tput civis 2>/dev/null || true
  # 백그라운드 스피너
  (
    while true; do
      printf "\r%s %s" "$msg" "${chars:i++%${#chars}:1}"
      sleep 0.1
    done
  ) &
  SPINNER_PID=$!
}

stop_spinner() {
  # 사용법: stop_spinner [최종메시지]
  local final="${1:-}"
  if [[ -n "$SPINNER_PID" ]]; then
    kill "$SPINNER_PID" 2>/dev/null || true
    wait "$SPINNER_PID" 2>/dev/null || true
    SPINNER_PID=""
  fi
  # 현재 줄 지우고 커서 복원
  printf "\r\033[2K"
  tput cnorm 2>/dev/null || true
  [[ -n "$final" ]] && echo "$final"
}
# 비정상 종료에도 커서 복원
trap 'stop_spinner >/dev/null 2>&1 || true' EXIT

# ---- Build helper (로그 캡처 + 경고/에러 파싱) ----
BUILD_LOG=""
BUILD_WARNINGS=""
BUILD_ERRORS=""

run_build() {
  # 사용법: run_build "Build" | "Rebuild"
  local label="$1"
  BUILD_LOG="$(mktemp)"
  start_spinner "${label}ing Pintos vm..."
  {
    make -C "${SCRIPT_DIR}" clean
    make -C "${SCRIPT_DIR}" all -j"$(nproc)"
  } &> "$BUILD_LOG"
  local status=$?
  stop_spinner

  # 경고/에러 추출 (중복 제거)
  if grep -qi "warning:" "$BUILD_LOG"; then
    BUILD_WARNINGS="$(grep -i 'warning:' "$BUILD_LOG" | sed 's/^[[:space:]]*//' | sort -u)"
  else
    BUILD_WARNINGS=""
  fi
  if grep -qi "error:" "$BUILD_LOG"; then
    BUILD_ERRORS="$(grep -i 'error:' "$BUILD_LOG" | sed 's/^[[:space:]]*//' | sort -u)"
  else
    BUILD_ERRORS=""
  fi

  return $status
}

# 빌드 실패 시 출력 유틸
print_build_diagnostics_and_exit() {
  echo
  echo "====== MAKE DIAGNOSTICS ======"
  [[ -n "$BUILD_WARNINGS" ]] && { echo "[Warnings]"; echo "$BUILD_WARNINGS"; echo; }
  if [[ -n "$BUILD_ERRORS" ]]; then
    echo "[Errors]"
    echo "$BUILD_ERRORS"
  else
    echo "[Errors] (pattern 'error:'가 없는 실패 — 전체 로그의 마지막 80줄)"
    tail -n 80 "$BUILD_LOG"
  fi
  echo "Full build log: $BUILD_LOG"
  exit 1
}

# --- xargs와 동일한 정규화: 트림 + 공백 접기 + 양끝 작은따옴표 제거 ---
canon() {
  # 1) 숨은 문자 제거
  local s=${1%$'\r'}                                   # CR
  s="${s#$'\xEF\xBB\xBF'}"                             # BOM
  s="${s//$'\xC2\xA0'/ }"                              # NBSP -> space
  s="${s//$'\xE2\x80\x8B'/}"                           # ZWSP 제거

  # 2) xargs처럼: IFS 공백 기준으로 토큰화 후 다시 합치기(앞뒤/연속 공백 접힘)
  local -a a
  IFS=$' \t\n' read -r -a a <<< "$s"
  s="${a[*]}"                                          # 토큰들 사이에 단일 스페이스로 join

  # 3) 양끝 작은따옴표가 둘다 있으면 제거 (xargs는 따옴표를 구분자로 봄)
  if [[ ${#s} -ge 2 && ${s:0:1} == "'" && ${s: -1} == "'" ]]; then
    s="${s:1:-1}"
  fi
  printf '%s' "$s"
}

# --- 파일을 한 번에 읽고(바인드 마운트 I/O 최소화) 동일 로직으로 파싱 ---
mapfile -t _lines < "$CONFIG_FILE"

# 진행표시: 전체 줄 수와 유효 라인 수는 루프에서 세자 (외부 명령 안 씀)
total_lines=${#_lines[@]}
parsed_lines=0
parsed_tests=0
parsed_groups=0
seen_groups=()  # 그룹 수 세기용 (연관배열 안 써도 OK)

# 진행 헤더 한 줄
echo "Parsing .test_config ..."

current_group=""
for raw in "${_lines[@]}"; do
  # 원본과 동일: '#' 이후는 주석으로 잘라냄 (따옴표 안이라도 자름)
  line="${raw%%\#*}"
  line="$(canon "$line")"
  [[ -z "$line" ]] && { ((parsed_lines++)); printf "\rParsing: %d/%d" "$parsed_lines" "$total_lines"; continue; }

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_group="${BASH_REMATCH[1]}"
    ORDERED_GROUPS+=("$current_group")
    GROUP_TESTS["$current_group"]=""
    # 그룹 카운트 (중복 방지 간단 처리)
    found=0
    for g in "${seen_groups[@]}"; do [[ "$g" == "$current_group" ]] && { found=1; break; }; done
    (( found == 0 )) && { seen_groups+=("$current_group"); ((parsed_groups++)); }
  else
    IFS='|' read -r test pre_args post_args prog_args test_path <<< "$line"
    test="$(canon "$test")"
    pre_args="$(canon "$pre_args")"
    post_args="$(canon "$post_args")"
    prog_args="$(canon "$prog_args")"
    test_path="$(canon "$test_path")"
    [[ -z "$test" ]] && { ((parsed_lines++)); printf "\rParsing: %d/%d" "$parsed_lines" "$total_lines"; continue; }

    config_pre_args["$test"]="$pre_args"
    config_post_args["$test"]="$post_args"
    config_prog_args["$test"]="$prog_args"
    config_result["$test"]="$test_path"
    tests+=("$test")

    TEST_GROUP["$test"]="$current_group"
    GROUP_TESTS["$current_group"]+="$test "
    ((parsed_tests++))
  fi

  ((parsed_lines++))
  # 너무 자주 찍으면 느려질 수 있어 5줄마다 한번씩 업데이트
  if (( parsed_lines % 5 == 0 || parsed_lines == total_lines )); then
    printf "\rParsing: %d/%d (groups: %d, tests: %d)" \
      "$parsed_lines" "$total_lines" "$parsed_groups" "$parsed_tests"
  else
    printf "\rParsing: %d/%d" "$parsed_lines" "$total_lines"
  fi
done

# 파싱 완료 라인
printf "\r\033[2K"   # 진행줄 지우기
echo "Parsed groups: $parsed_groups, tests: $parsed_tests"

for test in "${tests[@]}"; do
  grp="${config_result[$test]}"
  GROUP_TESTS["$grp"]+="$test "
done

if [[ ! -d "${SCRIPT_DIR}/build" ]]; then
  if run_build "Build"; then
    echo "Build complete."
    REBUILD=0
  else
    echo "Build failed."
    print_build_diagnostics_and_exit
  fi
fi

if (( REBUILD )); then
  if run_build "Rebuild"; then
    echo "Rebuild complete."
  else
    echo "Rebuild failed."
    print_build_diagnostics_and_exit
  fi
fi


STATE_FILE="${SCRIPT_DIR}/.test_status"
declare -A status_map

if [[ -f "$STATE_FILE" ]]; then
  while read -r test stat; do
    status_map["$test"]="$stat"
  done < "$STATE_FILE"
fi

echo "=== Available Pintos Tests ==="
index=1
for grp in "${ORDERED_GROUPS[@]}"; do
  tests_in_grp="${GROUP_TESTS[$grp]}"
  [[ -z "$tests_in_grp" ]] && continue

  echo
  echo "▶ ${grp^} tests:"
  for test in $tests_in_grp; do
    stat="${status_map[$test]:-untested}"
    case "$stat" in
      PASS) color="\e[32m" ;;
      FAIL) color="\e[31m" ;;
      *)    color="\e[0m"  ;;
    esac
    printf "  ${color}%2d) %s\e[0m\n" "$index" "$test"
    MENU_TESTS[$index]="$test"
    ((index++))
  done
done

read -p "Enter test numbers (e.g. '1 3 5' or '2-4'): " input
tokens=()
for tok in ${input//,/ }; do
  if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    for ((n=${BASH_REMATCH[1]}; n<=${BASH_REMATCH[2]}; n++)); do
      tokens+=("$n")
    done
  else
    tokens+=("$tok")
  fi
done

declare -A seen=()
sel_tests=()
for n in "${tokens[@]}"; do
  if [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#tests[@]} )); then
    idx=$((n-1))
    if [[ -z "${seen[$n]}" ]]; then
      sel_tests+=("${MENU_TESTS[$n]}")
      seen[$n]=1
    fi
  else
    echo "Invalid test number: $n" >&2
    exit 1
  fi
done

echo "Selected tests: ${sel_tests[*]}"

passed=()
failed=()
{
  cd "${SCRIPT_DIR}/build" || exit 1

  count=0
  total=${#sel_tests[@]}
  for test in "${sel_tests[@]}"; do
    echo
    pre_args="${config_pre_args[$test]}"
    post_args="${config_post_args[$test]}"
    prog_args="${config_prog_args[$test]}"
    dir="${config_result[$test]}"
    res="${dir}/${test}.result"

    mkdir -p ${dir}
    
    if [[ "$MODE" == "-q" ]]; then
      cmd="pintos ${pre_args} -- ${post_args} '${prog_args}'"
      echo "Running ${test} in batch mode... "
      echo "\$ ${cmd}"
      echo
      if make -s ${res} \
            ARGS="${pre_args} -- ${post_args} '${prog_args}'"; then
        if grep -q '^PASS' ${res}; then
          echo "PASS"; passed+=("$test")
        else
          echo "FAIL"; failed+=("$test")
        fi
      else
        echo "FAIL"; failed+=("$test")
      fi
    else
      echo -e "=== Debugging \e[33m${test}\e[0m ($(( count + 1 ))/${total}) ==="
      echo -e "\e[33mVSCode의 \"Pintos Debug\" 디버그를 시작하세요.\e[0m"
      echo " * QEMU 창이 뜨고, gdb stub은 localhost:1234 에서 대기합니다."
      echo " * 내부 출력은 터미널에 보이면서 '${dir}/${test}.output'에도 저장됩니다."
      echo

      cmd="pintos --gdb ${pre_args} -- ${post_args} '${prog_args}'"
      echo "\$ ${cmd}"
      eval "${cmd}" 2>&1 | tee "${dir}/${test}.output"

      repo_root="${SCRIPT_DIR}/.."
      ck="${repo_root}/${dir}/${test}.ck"
      if [[ -f "$ck" ]]; then
        perl -I "${repo_root}" \
             "$ck" "${dir}/${test}" "${dir}/${test}.result"
        if grep -q '^PASS' "${dir}/${test}.result"; then
          echo "=> PASS"; passed+=("$test")
        else
          echo "=> FAIL"; failed+=("$test")
        fi
      else
        echo "=> No .ck script, skipping result."; failed+=("$test")
      fi
      echo "=== ${test} session end ==="
    fi

    ((count++))
    echo -e "\e[33mtest ${count}/${total} finish\e[0m"
  done
}

echo
echo "=== Test Summary ==="
echo "Passed: ${#passed[@]}"
for t in "${passed[@]}"; do echo "  - $t"; done
echo "Failed: ${#failed[@]}"
for t in "${failed[@]}"; do echo "  - $t"; done

for t in "${passed[@]}"; do
  status_map["$t"]="PASS"
done
for t in "${failed[@]}"; do
  status_map["$t"]="FAIL"
done

> "$STATE_FILE"
for test in "${!status_map[@]}"; do
  echo "$test ${status_map[$test]}"
done >| "$STATE_FILE"
