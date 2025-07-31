#!/usr/bin/env bash

# 📂 위치한 pest 파일 경로 (현재 파일 기준)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEST_SRC="$SCRIPT_DIR/pest"

# ⚙️ 설치 대상 경로 우선 순위
BIN_TARGET="/usr/local/bin/pest"
USER_BIN="$HOME/.local/bin"
USER_LINK="$USER_BIN/pest"

# ✅ fzf 설치 여부 검사
install_fzf() {
  if ! command -v fzf > /dev/null 2>&1; then
    echo "🔍 fzf not found. Installing..."
    # Ubuntu, Debian, Amazon Linux 기반 (Docker, EC2 공통)
    sudo apt-get update && sudo apt-get install -y fzf
  else
    echo "✅ fzf is already installed."
  fi
}

# 🛠 pest 설치
install_pest() {
  echo "📦 Installing pest..."

  if [[ -w "/usr/local/bin" ]]; then
    echo "🔗 Linking pest to /usr/local/bin"
    sudo ln -sf "$PEST_SRC" /usr/local/bin/pest
    chmod +x "$PEST_SRC"
  else
    echo "🛠️ 일반 사용자 모드: $USER_BIN"
    mkdir -p "$USER_BIN"
    cp "$PEST_SRC" "$USER_LINK"
    chmod +x "$USER_LINK"

    # PATH에 안 들어있다면 추가
    if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
      echo '👉 export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
      echo '✅ ~/.bashrc 에 PATH 설정을 추가했습니다. 다음 로그인부터 사용 가능하거나 source ~/.bashrc 를 실행해주세요.'
    fi
  fi
}

# 👉 결과 안내
print_completion() {
  echo
  echo "✅ pest 설치 완료!"
  echo
  echo "👉 명령어 실행: ${YELLOW}pest${RESET}"
  echo "🧪 예: pintos 프로젝트 디렉터리 내에서 pest 를 입력하면 상호작용 메뉴 실행"
}

# ANSI 컬러
YELLOW="\e[33m"
RESET="\e[0m"

### === 실제 실행 === ###
install_fzf
install_pest
print_completion
