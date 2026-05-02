# 테스트 실행과 디버깅

`select_test.sh`는 Pintos 프로젝트 폴더에서 테스트를 선택해 실행하는 스크립트입니다.

## 옵션 요약

| 옵션 | 의미 |
| --- | --- |
| `-q` | 디버깅 없이 테스트 결과만 빠르게 확인 |
| `-g` | GDB stub을 열고 VS Code 디버깅과 연결 |
| `-r` | 실행 전에 `make`로 다시 빌드 |

`-q`와 `-g` 중 하나를 선택하고, 필요할 때 `-r`을 붙입니다.

```bash
./select_test.sh -q
./select_test.sh -q -r
./select_test.sh -g -r
```

## 빠른 테스트 실행

디버깅 없이 PASS/FAIL 결과만 보고 싶을 때 사용합니다.

```bash
./select_test.sh -q
```

<img width="367" height="522" alt="테스트 선택 화면" src="https://github.com/user-attachments/assets/4cbc9d4f-64ad-4988-a741-0c4b8eaebb98" />

실행할 테스트 번호를 공백, 쉼표, 범위로 입력할 수 있습니다.

```text
1-5 9 11-13
```

위 입력은 `1, 2, 3, 4, 5, 9, 11, 12, 13`번 테스트를 실행합니다.

### PASS 예시

<img width="528" height="55" alt="PASS 출력 예시" src="https://github.com/user-attachments/assets/f0008ac4-c25b-4c74-8a20-69006899527c" />

### FAIL 예시

<img width="524" height="568" alt="FAIL 출력 예시" src="https://github.com/user-attachments/assets/354dbd71-ea56-4e0c-beea-d96abb2b012c" />

FAIL diff에서 `-`는 내 출력에 없는 줄, `+`는 내 출력에만 있는 줄을 뜻합니다.

### 요약

<img width="187" height="147" alt="요약 출력 예시" src="https://github.com/user-attachments/assets/04c73bf3-895e-4089-a4df-f111ed0f72fe" />

실행이 끝나면 선택한 테스트의 최종 요약이 출력됩니다.

## VS Code로 디버깅

1. 디버깅할 위치에 중단점을 찍습니다.
2. Pintos 프로젝트 폴더에서 GDB 모드로 스크립트를 실행합니다.

   ```bash
   ./select_test.sh -g -r
   ```

   <img width="360" height="493" alt="GDB 테스트 선택 화면" src="https://github.com/user-attachments/assets/d13b5fbd-0cd5-40a9-ba97-570f02713d37" />

3. 아래처럼 GDB 연결 대기 출력이 보이면 VS Code 디버그를 실행합니다.

   <img width="619" height="59" alt="GDB 연결 대기 출력" src="https://github.com/user-attachments/assets/0949033a-3956-477e-a2aa-e7f22f7ed277" />

4. VS Code에서 해당 프로젝트의 디버그 구성을 선택해 실행합니다.

   <img width="315" height="231" alt="VS Code 디버그 선택" src="https://github.com/user-attachments/assets/14d7aee0-a270-4904-a448-05d37cc94eef" />

5. 디버깅이 진행되면 하위 터미널의 QEMU 출력이 한 줄씩 진행됩니다.

   <img width="545" height="410" alt="QEMU 출력 예시" src="https://github.com/user-attachments/assets/b8fbeafc-6d01-4a4b-a527-c94a057553ec" />

여러 테스트를 `-g`로 실행하면 새 테스트가 시작될 때마다 VS Code 디버그 버튼을
다시 눌러 연결합니다.

<img width="689" height="181" alt="다음 테스트 디버그 대기" src="https://github.com/user-attachments/assets/44eef037-2997-44c1-b3ca-89742eb9cb90" />

디버그 실행 후에도 결과 요약은 출력됩니다.

<img width="221" height="110" alt="디버그 결과 요약" src="https://github.com/user-attachments/assets/178e8015-c956-4f3a-8a72-cef3f9377afb" />

## 다시 빌드하고 실행

소스코드를 수정한 뒤 테스트 전에 다시 빌드하려면 `-r`을 붙입니다.

```bash
./select_test.sh -q -r
./select_test.sh -g -r
```

`-r`이 없으면 재빌드하지 않고 바로 테스트를 시도합니다.

## 저장된 테스트 결과 초기화

이전 PASS/FAIL 색상 표시는 `.test_status` 파일에 저장됩니다. 초기화하려면 실행한
프로젝트 폴더의 `.test_status` 파일을 삭제합니다.

```bash
rm .test_status
```
