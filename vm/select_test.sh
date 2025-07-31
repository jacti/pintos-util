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

while IFS= read -r raw; do
  line="${raw%%\#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue

  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_group="${BASH_REMATCH[1]}"
    ORDERED_GROUPS+=("$current_group")
    GROUP_TESTS["$current_group"]=""
  else
    IFS='|' read -r test pre_args post_args prog_args test_path <<< "$line"
    test="$(echo "$test"       | xargs)"
    pre_args="$(echo "$pre_args"   | xargs)"
    post_args="$(echo "$post_args" | xargs)"
    prog_args="$(echo "$prog_args" | xargs)"
    test_path="$(echo "$test_path" | xargs)"

    config_pre_args["$test"]="$pre_args"
    config_post_args["$test"]="$post_args"
    config_prog_args["$test"]="$prog_args"
    config_result["$test"]="$test_path"
    tests+=("$test")

    TEST_GROUP["$test"]="$current_group"
    GROUP_TESTS["$current_group"]+="$test "
  fi
done < "$CONFIG_FILE"

for test in "${tests[@]}"; do
  grp="${config_result[$test]}"
  GROUP_TESTS["$grp"]+="$test "
done

if [[ ! -d "${SCRIPT_DIR}/build" ]]; then
  echo "Build directory not found. Building Pintos vm..."
  make -C "${SCRIPT_DIR}" clean all
fi

if (( REBUILD )); then
  echo "Force rebuilding Pintos vm..."
  make -C "${SCRIPT_DIR}" clean all
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
