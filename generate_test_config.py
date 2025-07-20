#!/usr/bin/env python3

# 사용법 : 
# make check > make-check-output.txt
# python3 generate_test_config.py < make-check-output.txt > .test_config

import re
import os
import sys
from collections import defaultdict
from datetime import date

# 제거할 공통 플래그
COMMON_FLAGS = {"-v", "-k"}
COMMON_OPTS_WITH_VAL = {"-T", "-m"}

def clean_pre_args(arg_str):
    """
    - '-v', '-k' 플래그 제거
    - '-T <num>', '-m <num>' 쌍 제거
    """
    tokens = arg_str.split()
    out = []
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t in COMMON_FLAGS:
            i += 1
        elif t in COMMON_OPTS_WITH_VAL and i + 1 < len(tokens):
            i += 2
        else:
            out.append(t)
            i += 1
    return " ".join(out)

def parse_line(line):
    # 일반 테스트 (non-thread) 파싱
    if ' <' in line:
        line = line.split(' <', 1)[0]
    line = line.strip()
    if not line.startswith('pintos'):
        return None
    rest = line[len('pintos'):].strip()
    if ' -- ' not in rest:
        return None
    pre, post = rest.split(' -- ', 1)
    pre = pre.strip()
    post = post.strip()
    m = re.search(r'(-f run)(?:\s+(.*))?$', post)
    if not m:
        return None
    runner = post[:m.end(1)].strip()
    prog = (post[m.end(1):].strip() or '').strip()
    m2 = re.search(r'-p\s+([^:\s]+):([^\s]+)', pre)
    if not m2:
        return None
    full_path, test_name = m2.group(1), m2.group(2)
    test_path = os.path.dirname(full_path)
    clean_pre = clean_pre_args(pre)
    return test_path, test_name, clean_pre, runner, prog

def main():
    lines = [L.rstrip("\n") for L in sys.stdin]
    groups = defaultdict(list)

    # 1) non-thread 테스트 우선 파싱
    for line in lines:
        parsed = parse_line(line)
        if parsed:
            test_path, name, pre, runner, prog = parsed
            if not test_path.startswith('tests/threads'):
                groups[test_path].append((name, pre, runner, prog))

    # 2) summary 섹션에서 thread 테스트 목록 추출
    summary = []
    in_summary = False
    for line in reversed(lines):
        if not in_summary:
            if re.match(r'^\d+ of \d+ tests', line):
                in_summary = True
            continue
        if not line.strip():
            continue
        m = re.match(r'^(?:pass|FAIL)\s+(tests/threads/([^/\s]+))', line)
        if m:
            full_path = m.group(1)
            test_name = m.group(2)
            summary.append((full_path, test_name))
        else:
            break
    summary.reverse()

    # 3) 각 thread 테스트에 대해 pintos 실행 라인 찾아 파싱
    for full_path, name in summary:
        cmd_line = next((L for L in lines
                         if L.startswith('pintos')
                         and '-threads-tests' in L
                         and f' {name}' in L), None)
        if not cmd_line:
            continue
        if ' <' in cmd_line:
            cmd_line = cmd_line.split(' <', 1)[0]
        rest = cmd_line[len('pintos'):].strip()
        pre, post = rest.split(' -- ', 1)
        pre = pre.strip()
        post = post.strip()
        m = re.search(r'(-f run)(?:\s+(.*))?$', post)
        if not m:
            continue
        runner = post[:m.end(1)].strip()
        prog = (post[m.end(1):].strip() or '').strip()
        test_path = os.path.dirname(full_path)
        clean_pre = clean_pre_args(pre)
        groups[test_path].append((name, clean_pre, runner, prog))

    # Header: 파일 포맷 설명
    print("# .test_config format:")
    print("# test_name | pre_args | post_args | prog_args | test_path")
    print("#")
    print("# Fields:")
    print("#   test_name : 테스트 식별용 이름")
    print("#   pre_args  : 'pintos' 호출 시 -- 이전 옵션들")
    print("#   post_args : 'pintos' 호출 시 -- 이후, run 이전 옵션들")
    print("#   prog_args : 작은따옴표로 묶인 테스트 실행 인자 전체")
    print("#   test_path : 테스트 바이너리 경로 (호스트 파일 시스템 내)")
    print()

    total = sum(len(entries) for entries in groups.values())
    for test_path, entries in groups.items():
        group = test_path
        if group.startswith('tests/'):
            group = group[len('tests/'):]
        print(f'[{group}]')
        for name, pre, runner, prog in entries:
            if prog.startswith("'") and prog.endswith("'"):
                prog_field = prog
            elif prog:
                prog_field = f"'{prog}'"
            else:
                prog_field = "''"
            print(f"{name} | {pre} | {runner} | {prog_field} | {test_path}")
        print()

    # Footer: 총 개수 및 생성 날짜
    print(f"# Total testcases: {total}")
    print(f"# Generated on {date.today().isoformat()}")

if __name__ == '__main__':
    main()
