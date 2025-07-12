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

# 스크립트 자신이 있는 디렉터리 (src/threads/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 프로젝트 루트에서 Pintos 환경 활성화
source "${SCRIPT_DIR}/../activate"

# 1) build/ 폴더가 없으면 무조건 처음 빌드
if [[ ! -d "${SCRIPT_DIR}/build" ]]; then
  echo "Build directory not found. Building Pintos threads..."
  make -C "${SCRIPT_DIR}" clean all
fi

# 2) -r 옵션이 있으면 clean & rebuild
if (( REBUILD )); then
  echo "Force rebuilding Pintos threads..."
  make -C "${SCRIPT_DIR}" clean all
fi

STATE_FILE="${SCRIPT_DIR}/.test_status"
declare -A status_map

# 파일이 있으면 한 줄씩 읽어 넣기
if [[ -f "$STATE_FILE" ]]; then
  while read -r test stat; do
    status_map["$test"]="$stat"
  done < "$STATE_FILE"
fi

# 가능한 Pintos 테스트 목록
tests=(
  alarm-single
  alarm-multiple
  alarm-simultaneous
  alarm-priority
  alarm-zero
  alarm-negative
  priority-change
  priority-donate-one
  priority-donate-multiple
  priority-donate-multiple2
  priority-donate-nest
  priority-donate-sema
  priority-donate-lower
  priority-fifo
  priority-preempt
  priority-sema
  priority-condvar
  priority-donate-chain
  mlfqs-load-1
  mlfqs-load-60
  mlfqs-load-avg
  mlfqs-recent-1
  mlfqs-fair-2
  mlfqs-fair-20
  mlfqs-nice-2
  mlfqs-nice-10
  mlfqs-block
)

echo "=== Available Pintos Tests ==="
for i in "${!tests[@]}"; do
  idx=$((i+1))
  test="${tests[i]}"
  stat="${status_map[$test]:-untested}"
  # 색 결정: PASS=녹색, FAIL=빨강, untested=기본
  case "$stat" in
    PASS) color="\e[32m" ;;
    FAIL) color="\e[31m" ;;
    *)    color="\e[0m"  ;;
  esac
  printf " ${color}%2d) %s\e[0m\n" "$idx" "$test"
done

# 2) 사용자 선택 (여러 개 / 범위 허용)
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
    if [[ -z "${seen[$idx]}" ]]; then
      sel_tests+=("${tests[idx]}")
      seen[$idx]=1
    fi
  else
    echo "Invalid test number: $n" >&2
    exit 1
  fi
done

echo "Selected tests: ${sel_tests[*]}"

# 3) 순차 실행 및 결과 집계
passed=()
failed=()
{
  cd "${SCRIPT_DIR}/build" || exit 1

  count=0
  total=${#sel_tests[@]}
  for test in "${sel_tests[@]}"; do
    echo
    if [[ "$MODE" == "-q" ]]; then
      # batch 모드: make 타겟으로 .result 생성
      echo -n "Running ${test} in batch mode... "
      if make -s "tests/threads/${test}.result"; then
        if grep -q '^PASS' "tests/threads/${test}.result"; then
          echo "PASS"; passed+=("$test")
        else
          echo "FAIL"; failed+=("$test")
        fi
      else
        echo "ERROR"; failed+=("$test")
      fi
    else
      # interactive debug 모드: QEMU 포그라운드 실행 + tee 로 .output 캡처 후 .result 생성
      outdir="tests/threads"
      mkdir -p "${outdir}"

      echo -e "=== Debugging \e[33m${test}\e[0m ($(( count + 1 ))/${total}) ==="
      echo " * QEMU 창이 뜨고, gdb stub은 localhost:1234 에서 대기합니다."
      echo " * 내부 출력은 터미널에 보이면서 '${outdir}/${test}.output'에도 저장됩니다."
      echo

      # 터미널과 파일로 동시에 출력
      pintos --gdb -- -q run "${test}" 2>&1 | tee "${outdir}/${test}.output" 

      # 종료 후 체크 스크립트로 .result 생성
      repo_root="${SCRIPT_DIR}/.."   # 리포지터리 루트(pintos/) 경로
      ck="${repo_root}/tests/threads/${test}.ck"
      if [[ -f "$ck" ]]; then
      # -I 로 repo root를 @INC 에 추가해야 tests/tests.pm 을 찾습니다.
      perl -I "${repo_root}" \
           "$ck" "${outdir}/${test}" "${outdir}/${test}.result"
        if grep -q '^PASS' "${outdir}/${test}.result"; then
          echo "=> PASS"; passed+=("$test")
        else
          echo "=> FAIL"; failed+=("$test")
        fi
      else
        echo "=> No .ck script, skipping result."; failed+=("$test")
      fi
      echo "=== ${test} session end ==="
    fi

    # 진행 현황 표시: 노란색으로 total i/n 출력
    ((count++))
    echo -e "\e[33mtest ${count}/${total} finish\e[0m"
  done
}

# 4) 요약 출력
echo
echo "=== Test Summary ==="
echo "Passed: ${#passed[@]}"
for t in "${passed[@]}"; do echo "  - $t"; done
echo "Failed: ${#failed[@]}"
for t in "${failed[@]}"; do echo "  - $t"; done

# 이번에 PASS 된 테스트만 덮어쓰기
for t in "${passed[@]}"; do
  status_map["$t"]="PASS"
done

# 이번에 FAIL 된 테스트만 덮어쓰기
for t in "${failed[@]}"; do
  status_map["$t"]="FAIL"
done


# 5) 상태 파일에 PASS/FAIL 기록 (untested는 기록하지 않음)
> "$STATE_FILE"
for test in "${!status_map[@]}"; do
  echo "$test ${status_map[$test]}"
done >| "$STATE_FILE"
