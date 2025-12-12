# wodac (Wofi Default App Chooser)

`wodac`은 Yazi 파일 관리자를 위한 플러그인으로, Wofi를 사용하여 현재 파일의 MIME 타입을 기반으로 기본 애플리케이션을 시각적으로 선택하고 설정할 수 있게 해줍니다.

`wodac` is a plugin for the Yazi file manager that lets you visually select and set the default application based on the current file's MIME type using Wofi.

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

Yazi의 내장 플러그인 관리자를 사용하여 쉽게 설치할 수 있습니다.

Use Yazi's built-in plugin manager for easy installation.

1.  Yazi를 엽니다. / Open Yazi.
2.  `:` 키를 눌러 명령 모드로 진입합니다. / Press `:` to enter command mode.
3.  다음 명령어를 입력하고 `Enter`를 누릅니다: / Enter the following command and press `Enter`:

    ```bash
    :plugin add sephid86/wodac
    ```

설치가 완료되면, 다음 단계에 따라 단축키를 설정해야 합니다.

Once installed, you must configure a shortcut key in the next step.

---

### 사용 방법 / Usage

`wodac`은 단축키를 수동으로 설정해야 사용할 수 있습니다. 권장 단축키는 `Shift` + `A`입니다.

`wodac` requires a manual shortcut key assignment. The recommended shortcut is `Shift` + `A`.

1.  Yazi 설정 파일 `keymap.toml`을 엽니다. / Open your Yazi configuration file `keymap.toml`.

    ```bash
    yazi --edit keymap
    ```

2.  `[manager]` 섹션을 찾아 다음 줄을 추가합니다: / Find the `[manager]` section and add the following line:

    ```toml
    [manager]
    # Wodac 플러그인 실행 (Shift + A)
    # Run Wodac plugin (Shift + A)
    A = "plugin run --fork wodac $f"
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
