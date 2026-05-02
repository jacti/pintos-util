# .test_config 관리

`.test_config`는 `select_test.sh`가 메뉴에 보여줄 테스트 목록과 실행 인자를 정의하는
파일입니다.

## 포맷 종류

현재 저장소에는 두 가지 포맷이 공존합니다.

| 대상 | 포맷 | 예시 |
| --- | --- | --- |
| `threads/.test_config` | legacy `:` 구분 | `alarm-single: -- -q: tests/threads` |
| `userprog`, `vm`, `filesys` | `|` 구분 | `args-none | --fs-disk=10 ... | -q -f run | 'args-none' | tests/userprog` |

`threads`는 기존 스크립트와 맞춘 간단한 포맷을 사용합니다. `userprog`, `vm`,
`filesys`는 더 많은 실행 인자를 분리하기 위해 `|` 구분 포맷을 사용합니다.

## legacy `:` 포맷

`threads/.test_config`는 아래 형태입니다.

```text
test_name: args: result_dir
```

- `test_name`: 테스트 이름
- `args`: Pintos 실행 인자
- `result_dir`: `.result`, `.ck` 파일을 찾을 테스트 디렉터리

예시:

```text
alarm-single: -- -q: tests/threads
mlfqs-load-1: -- -mlfqs -q: tests/threads/mlfqs
```

## `|` 구분 포맷

`userprog/.test_config`, `vm/.test_config`, `filesys/.test_config`는 아래 형태입니다.

```text
test_name | pre_args | post_args | prog_args | test_path
```

- `test_name`: 메뉴에 표시하고 결과를 추적할 테스트 이름
- `pre_args`: `pintos` 호출에서 `--` 이전에 들어갈 옵션
- `post_args`: `--` 이후, `run` 이전에 들어갈 옵션
- `prog_args`: 실행할 테스트 프로그램과 인자
- `test_path`: 테스트 바이너리와 checker 파일이 있는 경로

예시:

```text
args-none | --fs-disk=10 -p tests/userprog/args-none:args-none | -q -f run | 'args-none' | tests/userprog
```

## 그룹화

`|` 구분 포맷에서는 테스트 앞에 `[그룹명]`을 적어 메뉴를 그룹화할 수 있습니다.

```text
[userprog]
args-none | --fs-disk=10 -p tests/userprog/args-none:args-none | -q -f run | 'args-none' | tests/userprog

[filesys/base]
lg-create | --fs-disk=10 -p tests/filesys/base/lg-create:lg-create | -q -f run | 'lg-create' | tests/filesys/base
```

<p align="center">
  <img src="https://github.com/user-attachments/assets/22b4bf68-9cd1-4b74-8c82-9600188f2171" width="300" alt=".test_config 그룹 예시" />
  <img src="https://github.com/user-attachments/assets/8bcb7747-4ef3-4192-ae21-ad2defd80fcc" width="300" alt="그룹 출력 예시" />
</p>

## 자동 생성

`generate_test_config.py`는 `make check` 출력에서 `|` 구분 `.test_config` 초안을
생성합니다.

```bash
make check > make-check-out.txt
python3 /path/to/pintos-util/generate_test_config.py < make-check-out.txt > .test_config
```

생성 스크립트는 `-v`, `-k`, `-T <num>`, `-m <num>` 같은 공통 옵션 일부를 정리한 뒤
테스트 경로별로 그룹을 만듭니다.

## 직접 수정할 때 주의할 점

- `|` 포맷에서는 필드 개수를 유지합니다.
- 테스트 이름은 결과 파일과 checker 파일을 찾는 기준이 되므로 임의로 바꾸기 전에
  실제 Pintos 테스트 경로를 확인합니다.
- `pre_args`와 `post_args`의 경계는 Pintos 명령어의 `--` 기준입니다.
- 파일을 크게 바꾼 뒤에는 `./select_test.sh -q`로 메뉴가 정상 파싱되는지 확인합니다.
