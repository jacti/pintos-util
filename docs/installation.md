# 설치와 세팅

이 문서는 `pintos-util` 파일을 실제 Pintos 프로젝트에 배치하는 방법을 정리합니다.

## 전제

- 외부 Pintos 소스 트리가 이미 준비되어 있어야 합니다.
- 각 프로젝트 폴더에서 `make`가 동작해야 합니다.
- `select_test.sh`는 실행 위치의 상위 경로에 있는 `activate` 파일을 읽습니다.
  예를 들어 `pintos/userprog/select_test.sh`를 실행하면 `pintos/activate`를
  기대합니다.

## 프로젝트별 파일 복사

필요한 프로젝트에 맞춰 `select_test.sh`와 `.test_config`를 같은 Pintos 프로젝트
폴더로 복사합니다.

```bash
# 예: userprog 유틸을 외부 Pintos 트리에 설치
cp /path/to/pintos-util/userprog/select_test.sh /path/to/pintos/userprog/select_test.sh
cp /path/to/pintos-util/userprog/.test_config /path/to/pintos/userprog/.test_config
chmod +x /path/to/pintos/userprog/select_test.sh
```

프로젝트별 대상은 아래와 같습니다.

| 프로젝트 | 원본 | 대상 |
| --- | --- | --- |
| Threads | `threads/select_test.sh`, `threads/.test_config` | `pintos/threads` |
| User Program | `userprog/select_test.sh`, `userprog/.test_config` | `pintos/userprog` |
| Virtual Memory | `vm/select_test.sh`, `vm/.test_config` | `pintos/vm` |
| File System | `filesys/select_test.sh`, `filesys/.test_config` | `pintos/filesys` |

## VS Code 디버그 설정

`launch.json`을 VS Code 작업공간 루트의 `.vscode/launch.json`으로 복사합니다.

```bash
mkdir -p /path/to/workspace/.vscode
cp /path/to/pintos-util/launch.json /path/to/workspace/.vscode/launch.json
```

복사 후 아래 항목을 본인 환경에 맞게 확인합니다.

- `program`: 디버깅할 `kernel.o` 경로
- `cwd`: 테스트를 실행할 Pintos 프로젝트 폴더
- `miDebuggerPath`: 로컬 `gdb` 경로
- `miDebuggerServerAddress`: 기본값은 `localhost:1234`

현재 제공되는 `launch.json`에는 `threads`, `userprog`, `vm` 설정이 들어 있습니다.
`filesys` 디버깅이 필요하면 같은 형식으로 `program`과 `cwd`를 `pintos/filesys`에
맞춰 추가하세요.

## 설치 확인

대상 Pintos 프로젝트 폴더로 이동한 뒤 빠른 테스트 모드를 실행합니다.

```bash
./select_test.sh -q -r
```

테스트 목록이 출력되면 기본 배치가 된 것입니다. 실행 전에 빌드가 필요하면 `-r`
옵션이 `make`를 먼저 수행합니다.

## 자주 막히는 지점

- `activate` 관련 오류: Pintos 트리의 `activate` 파일 위치를 확인합니다.
- `kernel.o`를 찾지 못함: 해당 프로젝트 폴더에서 `make`를 먼저 실행합니다.
- `gdb`를 찾지 못함: `which gdb`로 경로를 확인한 뒤 `launch.json`의
  `miDebuggerPath`를 수정합니다.
- macOS 기본 Bash 문제: `/bin/bash --version`이 3.2라면 최신 Bash 사용을
  검토합니다.
