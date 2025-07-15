# [Pintos] vscode 디버그 연동 v 1.1.0

다시 돌아온 편의성 아저씹니다.

핀토스 코드는 짰는데 make check 말고는 어떻게 테스트 돌려야할지도 모르겠고 한줄한줄 디버깅 하고 싶은데 어떻게 해야할지 막막한 그 상황 한방에 해결해 드립니다.

# 세팅

아래파일 세개를 프로젝트에 넣어줍니다.

[select_test.sh](/select_test.sh)

[launch.json](/launch.json)

[.test._config](/.test_config)

- select_test.sh
    - `pintos/threads` 폴더에 넣어줍니다.
        - [주의] threads 폴더가 프로젝트 하위에 많습니다. (ex. `test/threads`) 우리가 작업하는 `threads.c`가 있는 그 위치에 넣어줍니다.
    - 권한 부여
        
        ```bash
        # threads 폴더로 이동한 후
        chmod +x ./select_test.sh
        ```

- .test_config
    - `pintos/threads` 폴더에 넣어줍니다.
        
- launch.json
    - 프로젝트 루트 `.vscode` 폴더 에 넣어줍니다.
    - 경로 수정
        - `${workspaceFolder}` 는 vscode에서 열린 작업공간의 루트 폴더입니다.
        - `“program”` 필드의 값이 자신의 kernel.o 파일과 일치하는지 확인합니다.
            - threads 하위 build 폴더가 안보이면 threads 폴더에서 make 명령어를 실행하면 생깁니다.
        - `“cwd”` 필드의 값이 자신의 threads 폴더 경로와 일치하는지 확인합니다.
        - `“miDebuggerPath”`가 자신의 gdb 경로와 맞는지 확인합니다.
            - gdb 경로 확인법
                
                ```bash
                which gdb
                ```
                
    
- 실행 테스트
    
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
2. 아래 명령어를 threads 폴더에서 실행

```bash
# gdb에서 따와서 -g 옵션입니다
./select_test.sh -g -r
```

<img width="360" height="493" alt="image" src="https://github.com/user-attachments/assets/d13b5fbd-0cd5-40a9-ba97-570f02713d37" />


> 이전에 통과했던 테스트는 초록, 실패했던 테스트는 빨강으로 출력됩니다.
>

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

`./threads/.test_status` 파일을 삭제합니다.

## .test_config

- 테스트케이스별 줄 옵션을 변경할 수 있습니다.
- [테스트케이스] : [qemu옵션] — [핀토스옵션] : [result 파일 경로] 형태로 구성되어 있습니다.

# 업데이트 로그

- v1.1.0
    - .test_config 파일 추가

> 모두 핀”토”스 파이팅 입니다! 📣
>
