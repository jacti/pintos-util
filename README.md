# [Pintos] vscode 디버그 연동 v 3.0.0

- sh 파일 내부 병목 현상을 해결하여 전체 실행 속도가 높아졌습니다.
- 실행 도중 indicator를 추가하여, 지금 진행사항을 알 수 있도록 하였습니다.

**vm swap test에서 버그가 있어 수정하였습니다. 새 .test_config로 업데이트 하기 바랍니다.**

## 세팅

[launch.json](/launch.json)

- 프로젝트 루트 `.vscode` 폴더 에 넣어줍니다.
- 경로 수정
  - `${workspaceFolder}` 는 vscode에서 열린 작업공간의 루트 폴더입니다.
  - `“program”` 필드의 값이 자신의 kernel.o 파일과 일치하는지 확인합니다.
    - userprog 하위 build 폴더가 안보이면 userprog 폴더에서 make 명령어를 실행하면 생깁니다.
  - `“cwd”` 필드의 값이 자신의 userprog 폴더 경로와 일치하는지 확인합니다.
  - `“miDebuggerPath”`가 자신의 gdb 경로와 맞는지 확인합니다.
    - gdb 경로 확인법
      ```bash
      which gdb
      ```

### Project 1: Threads

- [select_test.sh](threads/select_test.sh)

  - `pintos/threads` 폴더에 넣어줍니다.
  - 권한 부여
    ```bash
    # threads 폴더로 이동한 후
    chmod +x ./select_test.sh
    ```

- [.test_config](threads/.test_config)

  - `pintos/threads` 폴더에 넣어줍니다.

### Project 2: User Program

- [select_test.sh](userprog/select_test.sh)

  - `pintos/userprog` 폴더에 넣어줍니다.
  - 권한 부여
    ```bash
    # userprog 폴더로 이동한 후
    chmod +x ./select_test.sh
    ```

- [.test_config](userprog/.test_config)

  - `pintos/userprog` 폴더에 넣어줍니다.

### Project 3: Virtual Memory

- [select_test.sh](vm/select_test.sh)

  - `pintos/vm` 폴더에 넣어줍니다.
  - 권한 부여
    ```bash
    # vm 폴더로 이동한 후
    chmod +x ./select_test.sh
    ```

- [.test_config](vm/.test_config)

  - `pintos/vm` 폴더에 넣어줍니다.

## 실행 테스트

```bash
./select_test.sh -q -r
```

위 코드가 실행되고 테스트 리스트가 나오면 성공입니다.

## 사용법

### 디버깅 없이 테스트 결과만 알고 싶을 때

```bash
# quick에서 따와서 -q 옵션입니다
./select_test.sh -q
```

<img width="367" height="522" alt="image" src="https://github.com/user-attachments/assets/4cbc9d4f-64ad-4988-a741-0c4b8eaebb98" />

실행하고자 하는 테스트의 번호를 공백으로 구분하여 입력합니다.

ex. 1-5 9 11-13 ⇒ {1, 2, 3, 4, 5, 9, 11, 13} 번 테스트를 진행합니다.

- PASS 한 경우
  <img width="528" height="55" alt="image" src="https://github.com/user-attachments/assets/f0008ac4-c25b-4c74-8a20-69006899527c" />
- FAIL 한 경우

    <img width="524" height="568" alt="image" src="https://github.com/user-attachments/assets/354dbd71-ea56-4e0c-beea-d96abb2b012c" />

  - - 로 내 아웃풋에 없는 부분이 +로 내 아웃풋에만 있는 부분이 출력됩니다.

- 요약

    <img width="187" height="147" alt="image" src="https://github.com/user-attachments/assets/04c73bf3-895e-4089-a4df-f111ed0f72fe" />

  최종 요약이 출력됩니다.

### vscode로 디버깅을 하고 싶을 때

1. 디버깅할 위치에 중단점을 찍습니다
2. 아래 명령어를 userprog 폴더에서 실행

```bash
# gdb에서 따와서 -g 옵션입니다
./select_test.sh -g -r
```

<img width="360" height="493" alt="image" src="https://github.com/user-attachments/assets/d13b5fbd-0cd5-40a9-ba97-570f02713d37" />

> 이전에 통과했던 테스트는 초록, 실패했던 테스트는 빨강으로 출력됩니다.

3. vscode 디버깅 실행

<img width="619" height="59" alt="image" src="https://github.com/user-attachments/assets/0949033a-3956-477e-a2aa-e7f22f7ed277" />

위 출력이 보이면 vscode의 디버그를 실행합니다.

<img width="315" height="231" alt="image" src="https://github.com/user-attachments/assets/14d7aee0-a270-4904-a448-05d37cc94eef" />

디버깅이 진행되면서 하위 터미널 (QEMU)에 한줄씩 출력이 실행됩니다.

<img width="545" height="410" alt="image" src="https://github.com/user-attachments/assets/b8fbeafc-6d01-4a4b-a527-c94a057553ec" />

- 디버그 옵션으로 여러 테스트를 하면 새로운 테스트가 진행될 때마다 vscode의 디버그 버튼을 다시 눌러줍니다.

    <img width="689" height="181" alt="image" src="https://github.com/user-attachments/assets/44eef037-2997-44c1-b3ca-89742eb9cb90" />

  → 이 창이 뜨면 vscode 디버그 한번 더 눌리기

- 결과 요약
  <img width="221" height="110" alt="image" src="https://github.com/user-attachments/assets/178e8015-c956-4f3a-8a72-cef3f9377afb" />

## 소스코드를 재 빌드하고 테스트하고 싶을 때

- -q or -g옵션 뒤에 -r 옵션을 전달합니다
  ```bash
  ./select_test.sh -q -r
  ```
- -r 옵션이 없으면 재빌드하지 않고 바로 테스트를 시도합니다.

### 저장해둔 테스트 통과 결과를 리셋하고 싶을 때

`./userprog/.test_status` 파일을 삭제합니다.

## .test_config 직접 수정

- 테스트케이스별 전달할 옵션을 변경할 수 있습니다.

  - [테스트케이스] : [qemu옵션] — [핀토스옵션] : [result 파일 경로] 형태로 구성되어 있습니다.
    -> 옵션 부분을 수정하여 전달할 옵션을 변경할 수 있습니다.

- 테스트케이스를 그룹화 할 수 있습니다.

  - 테스트 케이스들 앞에 [그룹명]을 적으면 해당 그룹으로 그룹화 되어 출력됩니다.

    <p align="center">
    <img src="https://github.com/user-attachments/assets/22b4bf68-9cd1-4b74-8c82-9600188f2171" width="300" alt=".test_config" />
    <img src="https://github.com/user-attachments/assets/8bcb7747-4ef3-4192-ae21-ad2defd80fcc" width="300" alt="출력 예시" />
    </p>

## .test_config 생성

- 제공된 `generate_test_config.py` 로 `.test_config` 초안을 생성할 수 있습니다.

```bash
    make check > make-check-out.txt # make check 결과를 저장
    python3 generate_test_config.py < make-check-out.txt > .test_config #make check 결과를 바탕으로 자동 생성
```

## 업데이트 로그

- v3.0.0

  - 문자열 파싱 병목 해결
  - 파싱, build 도중 indicator 추가
  - build 실패시 error, warning 출력, tmp파일로 저장

- v2.1.1

  - -r 옵션 시 make 속도 증가
  - vm swap test swap이 일어나지 않고 통과하는 버그 수정

- v2.1.0

  - vm 프로젝트를 위해 .test_config 파일 업데이트
  - 프로젝트 별 폴더 구분

- v2.0.1

  - dup2, multi-oom test config 수정

- v2.0.0

  - 설정 파일 구분자 변경
  - 설정 파일 구분 변수 갯수 추가
  - 설정 파일 생성 코드 추가

- v1.2.0

  - test case 그룹화 기능 추가
  - user program 용 .test_config 배포

- v1.1.0
  - .test_config 파일 추가

![넝담](https://i.namu.wiki/i/FhMQM_38hoO2uYGBDtn6Ok77Ra2Ul1it1mgdkyoSUHPqX4Y-nr9Dn4LKNToE_g3oRI7AQ_YypphEt_EYFPoKGU36hoPj0M96P72w-ckHs5PUTdKFjEHVC9eNS57lOMG7_2E4bFv4wu4ioQAab4cUig.webp)

> 모두 핀”토”스 파이팅 입니다! 📣

> ~~능이 버섯은 안된다...~~
