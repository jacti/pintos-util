# 개발자 관리 노트

이 문서는 `pintos-util` 저장소를 유지보수할 때 확인할 기준을 정리합니다.

## 저장소 역할

`pintos-util`은 Pintos 본체가 아니라 외부 Pintos 프로젝트에 복사해서 쓰는 보조
파일 저장소입니다. 따라서 이 저장소 안에서 `select_test.sh`를 실행해도 실제 Pintos
빌드 트리와 `activate` 파일이 없으면 테스트는 끝까지 돌지 않습니다.

## 파일 책임

| 파일 | 역할 |
| --- | --- |
| `README.md` | 프로젝트 입구, 빠른 시작, 상세 문서 링크 |
| `launch.json` | VS Code C++ 디버그 구성 예시 |
| `generate_test_config.py` | `make check` 출력에서 `.test_config` 생성 |
| `threads/select_test.sh` | Threads용 legacy config 실행 스크립트 |
| `userprog/select_test.sh` | User Program용 테스트 선택/실행 스크립트 |
| `vm/select_test.sh` | Virtual Memory용 테스트 선택/실행 스크립트 |
| `filesys/select_test.sh` | File System용 테스트 선택/실행 스크립트 |
| `*/.test_config` | 프로젝트별 테스트 목록과 실행 인자 |
| `docs/` | 설치, 사용, 설정, 유지보수 문서 |

## 스크립트 계열

`threads/select_test.sh`는 `:` 구분 `.test_config`를 읽는 기존 포맷입니다.

`userprog/select_test.sh`, `vm/select_test.sh`, `filesys/select_test.sh`는 `|` 구분
`.test_config`를 읽는 같은 계열의 스크립트입니다. 세 파일 중 하나를 수정할 때는
동일한 수정이 나머지 프로젝트에도 필요한지 확인합니다.

## 실행 환경 가정

- 각 스크립트는 Pintos 프로젝트 폴더 안에서 실행됩니다.
- 스크립트는 `../activate`를 `source`합니다.
- `make`, `pintos`, `gdb`, QEMU 관련 도구는 외부 Pintos 환경에 의존합니다.
- macOS 기본 Bash 3.2에서는 Bash 4 이상 기능이 문제가 될 수 있습니다.

## 변경 전 점검

1. 수정할 프로젝트의 `.test_config` 포맷을 확인합니다.
2. 테스트 경로가 실제 Pintos 테스트 디렉터리와 맞는지 확인합니다.
3. `select_test.sh` 로직 변경이 다른 프로젝트 스크립트에도 필요한지 확인합니다.
4. 사용자 문서 변경이 필요한 경우 `README.md`와 `docs/` 링크를 함께 갱신합니다.
5. 변경 로그에 사용자에게 보이는 변경을 기록합니다.

## 기본 검증

외부 Pintos 환경 없이도 아래 검증은 수행할 수 있습니다.

```bash
bash -n threads/select_test.sh
bash -n userprog/select_test.sh
bash -n vm/select_test.sh
bash -n filesys/select_test.sh
python3 -m py_compile generate_test_config.py
```

실제 실행 검증은 외부 Pintos 트리에서 수행합니다.

```bash
./select_test.sh -q
./select_test.sh -q -r
./select_test.sh -g -r
```

## 릴리즈 체크리스트

- `README.md` 빠른 시작이 최신 파일 구조와 맞는지 확인
- `docs/installation.md`의 복사 대상 경로 확인
- `docs/usage.md`의 옵션 설명과 실제 스크립트 옵션 확인
- `docs/test-config.md`의 포맷 설명과 `.test_config` 헤더 확인
- `docs/changelog.md`에 버전별 변경 기록 추가
- 스크립트 문법 검증과 Python compile 검증 수행
