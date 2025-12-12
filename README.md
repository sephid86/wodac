# wodac (Wofi Default App Chooser)

`wodac`은 Wofi를 이용해 현재 파일의 기본 앱을 시각적으로 선택/설정합니다. Yazi, Ranger 같은 CUI 파일 관리자에서 유용합니다.

`wodac` visually selects/sets the current file's default app using Wofi. It is useful in CUI file managers like Yazi and Ranger.

---

### 요구 사항 / Requirements

이 플러그인은 다음 프로그램들이 시스템에 설치되어 있어야 작동합니다:

This plugin requires the following programs to be installed on your system to work:

*   **`wofi`**: Wayland 호환 애플리케이션 런처 (또는 `dmenu` 모드를 지원하는 유사 도구)
*   **`xdg-utils`**: MIME 타입 감지 및 기본 앱 설정을 위한 표준 XDG 유틸리티
*   **`grep`, `cut`, `find`, `sort`, `comm`, `basename`, `dirname`**: 표준 GNU/Linux 핵심 유틸리티
*   **`notify-send`**: 선택 사항. 설정 완료 알림 메시지를 표시합니다.

---

### 설치 방법 / Installation

    ```bash
    mkdir -p ~/scripts
    cd ~/scripts
    git clone https://github.com/sephid86/wodac
    chmod +x ~/wodac.sh
    ```

설치가 완료되면, 다음 단계에 따라 단축키를 설정해야 합니다.

Once installed, you must configure a shortcut key in the next step.

---

### 사용 방법 / Usage

`wodac`은 단축키를 수동으로 설정해야 사용할 수 있습니다. 권장 단축키는 `Shift` + `A`입니다.

`wodac` requires a manual shortcut key assignment. The recommended shortcut is `Shift` + `A`.

1.  Yazi 설정 파일 `keymap.toml`을 엽니다. / Open your Yazi configuration file `keymap.toml`.

    ```bash
    nano ~/.config/yazi/keymap.toml
    ```

2.   파일에 아래 내용을 추가합니다.: / Append the following to the file.:

    ```toml
    [[mgr.prepend_keymap]]
    on  = "A"
    run = 'shell "~/wodac/wodac.sh $@"'
    ```

3.  Yazi를 다시 시작하거나, `R` 키를 눌러 설정을 새로고침합니다. / Restart Yazi or press `R` to reload configuration.

#### 사용법 / How to Use:

*   파일에 커서를 둔 상태에서 `Shift` + `A`를 누릅니다.
*   Wofi 메뉴가 나타나면 원하는 애플리케이션을 선택합니다.
*   선택된 앱이 해당 파일 형식의 기본 애플리케이션으로 설정됩니다.

*   Press `Shift` + `A` while a file is selected.
*   Select your desired application from the Wofi menu.
*   The chosen app will be set as the default handler for that file type.

---

### 저작권 및 라이선스 / Copyright and License

이 스크립트는 AI on Google Search (Gemini)에 의해 작성되었으며 GPLv3 라이선스 하에 배포됩니다. 자세한 내용은 스크립트 파일을 참조하십시오.

This script was authored by AI on Google Search (Gemini) and is distributed under the GNU General Public License v3.0. See the script file for full details.
