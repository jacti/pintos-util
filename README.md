# Pintos Util

Pintos 프로젝트 폴더에 복사해서 쓰는 테스트 실행/디버깅 유틸 모음입니다.

이 저장소는 Pintos 커널 소스가 아니라, 외부 Pintos 트리의 `threads`, `userprog`,
`vm`, `filesys` 폴더에서 테스트를 고르고 실행하거나 VS Code + GDB 디버깅을 쉽게
하기 위한 보조 파일을 관리합니다.

## 빠른 시작

1. 이 저장소에서 필요한 프로젝트 폴더의 `select_test.sh`와 `.test_config`를
   Pintos 프로젝트의 같은 이름 폴더로 복사합니다.
2. `launch.json`을 VS Code 작업공간의 `.vscode/launch.json`으로 복사하고,
   `program`, `cwd`, `miDebuggerPath`를 본인 환경에 맞게 확인합니다.
3. 복사한 `select_test.sh`에 실행 권한을 줍니다.

   ```bash
   chmod +x ./select_test.sh
   ```

4. Pintos 프로젝트 폴더에서 테스트 메뉴가 뜨는지 확인합니다.

   ```bash
   ./select_test.sh -q -r
   ```

## 포함된 파일

| 대상 프로젝트 | 복사할 파일 | 대상 위치 | 설정 포맷 |
| --- | --- | --- | --- |
| Threads | `threads/select_test.sh`, `threads/.test_config` | `pintos/threads` | legacy `:` 구분 |
| User Program | `userprog/select_test.sh`, `userprog/.test_config` | `pintos/userprog` | `|` 구분 |
| Virtual Memory | `vm/select_test.sh`, `vm/.test_config` | `pintos/vm` | `|` 구분 |
| File System | `filesys/select_test.sh`, `filesys/.test_config` | `pintos/filesys` | `|` 구분 |
| VS Code Debug | `launch.json` | `.vscode/launch.json` | VS Code C++ debug config |
| Config 생성 | `generate_test_config.py` | 필요 위치에서 실행 | `make check` 출력 파싱 |

## 문서

- [설치와 세팅](docs/installation.md)
- [테스트 실행과 디버깅](docs/usage.md)
- [.test_config 관리](docs/test-config.md)
- [개발자 관리 노트](docs/development.md)
- [변경 로그](docs/changelog.md)

## 실행 전 확인할 것

- 이 저장소만으로는 Pintos 테스트를 실행할 수 없습니다. 실제 Pintos 소스 트리와
  빌드 환경이 필요합니다.
- `select_test.sh`는 각 Pintos 프로젝트 폴더에서 실행하는 것을 기준으로 합니다.
- 스크립트는 상위 경로의 `activate` 파일을 `source`합니다. 실행이 바로 실패하면
  Pintos 환경 설정 파일이 있는지 먼저 확인하세요.
- macOS 기본 Bash 3.2에서는 일부 스크립트 기능이 맞지 않을 수 있습니다. 문제가
  나면 최신 Bash로 실행하거나 스크립트 호환성을 점검하세요.

![넝담](https://i.namu.wiki/i/FhMQM_38hoO2uYGBDtn6Ok77Ra2Ul1it1mgdkyoSUHPqX4Y-nr9Dn4LKNToE_g3oRI7AQ_YypphEt_EYFPoKGU36hoPj0M96P72w-ckHs5PUTdKFjEHVC9eNS57lOMG7_2E4bFv4wu4ioQAab4cUig.webp)

> 모두 핀”토”스 파이팅 입니다! 📣

> ~~능이 버섯은 안된다...~~
