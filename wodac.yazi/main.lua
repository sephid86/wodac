local ya = require("yazi")
local shell = require("yazi.shell")

-- SCRIPT_PATH 변수는 install 시점에 설정됩니다.
local SCRIPT_PATH = "" 

-- Helper function to run CLI commands (async via os.execute)
local function run_cli(cmd)
    os.execute(cmd .. " >/dev/null 2>&1")
end

-- 설치 함수: wodac.sh 스크립트 내용을 파일로 생성
local function install_script(plug)
    -- plug.path를 사용하여 정확한 설치 경로를 가져옵니다.
    SCRIPT_PATH = plug.path .. "/wodac.sh"

    -- [스크립트 내용 시작] 여기에 사용자님의 wodac.sh 스크립트 내용 전체를 붙여넣으세요.
    local script_content = [[
#!/bin/bash
# wodac (Wofi Default App Chooser)
# ... (라이센스 및 주석 생략) ...

FILE_PATH="$1"
MAP_FILE="/tmp/wofi_path_map.txt"
rm -f "$MAP_FILE"

if [ -z "$FILE_PATH" ]; then
    echo "오류: 처리할 파일 경로가 제공되지 않았습니다."
    echo "Error: No file path provided for processing."
    notify-send "Wodac 오류/Error" "처리할 파일 경로가 제공되지 않았습니다. (No file path provided)"
    exit 1
fi

# 1. 입력된 파일의 MIME 타입을 감지합니다.
CURRENT_MIME=$(xdg-mime query filetype "$FILE_PATH")

if [ -z "$CURRENT_MIME" ]; then
    echo "오류: 파일의 MIME 타입을 감지할 수 없습니다: $FILE_PATH"
    echo "Error: Cannot detect MIME type for the file: $FILE_PATH"
    notify-send "Wodac 오류/Error" "선택한 파일의 MIME 타입을 알 수 없습니다. (Cannot detect MIME type)"
    exit 1
fi

echo "감지된 MIME 타입: $CURRENT_MIME"
echo "Detected MIME type: $CURRENT_MIME"

# 모든 .desktop 파일 경로 목록을 가져옵니다.
ALL_DESKTOP_PATHS=$(find /usr/share/applications/ ~/.local/share/applications/ -name "*.desktop")

# 1. MIME 타입이 일치하는 .desktop 파일 경로 목록을 가져옵니다.
MATCHING_PATHS=$(grep -l "MimeType=.*;$CURRENT_MIME;.*" $ALL_DESKTOP_PATHS 2>/dev/null)

# 2. 일치하는 목록과 전체 목록을 사용하여 일치하지 않는 목록을 분리합니다.
SORTED_ALL=$(echo -e "$ALL_DESKTOP_PATHS" | sort)
SORTED_MATCHING=$(echo -e "$MATCHING_PATHS" | sort)
NON_MATCHING_PATHS=$(comm -3 <(echo -e "$SORTED_ALL") <(echo -e "$SORTED_MATCHING"))

APP_NAMES=""

process_list() {
    local list="$1"
    for full_path in $list; do
        app_name=$(grep "^Name=" "$full_path" | cut -d'=' -f2 | head -n 1 | tr -d '\n')
        if [ -n "$app_name" ]; then
            APP_NAMES="$APP_NAMES$app_name\n"
            echo "$app_name:$full_path" >> "$MAP_FILE"
        fi
    done
}

process_list "$MATCHING_PATHS"

APP_NAMES="$APP_NAMES----------\n"
echo "----------:/dev/null" >> "$MAP_FILE"

process_list "$NON_MATCHING_PATHS"

if [ -z "$APP_NAMES" ]; then
    echo "애플리케이션 목록을 찾을 수 없습니다."
    echo "No applications found in the list."
    rm -f "$MAP_FILE"
    exit 1
fi

echo "Wofi 실행 중... (우선순위 배치)"
echo "Running Wofi... (priority order)"

# 4. Wofi 실행 및 선택 처리
SELECTED_NAME=$(echo -e "$APP_NAMES" | wofi -d -p "기본 앱 선택 / Select Default App for $CURRENT_MIME:")

if [ -n "$SELECTED_NAME" ]; then
    CLEAN_NAME=$(echo "$SELECTED_NAME" | tr -d '\n')
    
    SELECTED_PATH=$(grep "^$CLEAN_NAME:" "$MAP_FILE" | cut -d':' -f2- | head -n 1 | tr -d '\n')
    
    if [ -n "$SELECTED_PATH" ] && [ "$SELECTED_PATH" != "/dev/null" ]; then
        APP_BASENAME=$(basename "$SELECTED_PATH")
        xdg-mime default "$APP_BASENAME" "$CURRENT_MIME"
        echo "성공: '$CURRENT_MIME'의 기본 앱이 '$APP_BASENAME'으로 설정되었습니다."
        echo "Success: Default app for '$CURRENT_MIME' set to '$APP_BASENAME'."
        notify-send "Wodac 성공/Success" "기본 앱이 $APP_BASENAME 으로 설정되었습니다. (Default app set)"
    elif [ "$SELECTED_PATH" == "/dev/null" ]; then
        echo "구분선을 선택했습니다. 작업 취소."
        echo "Separator selected. Action cancelled."
    else
        echo "경로 매핑 실패."
        echo "Path mapping failed."
    fi
else
    echo "애플리케이션 선택이 취소되었습니다."
    echo "Application selection cancelled."
fi

# 6. 임시 파일 정리
rm -f "$MAP_FILE"
    ]]
    -- [스크립트 내용 종료]

    -- 파일 쓰기 (Lua io 라이브러리 사용)
    local file = io.open(SCRIPT_PATH, "w")
    if file then
        file:write(script_content)
        io.close(file)
        -- 실행 권한 부여
        run_cli("chmod +x " .. shell.quote(SCRIPT_PATH))
        ya.notify("Wodac 설치됨", "wodac.sh 스크립트가 플러그인 폴더에 생성되었습니다.", "info", 3000)
    else
        ya.notify("Wodac 오류", "스크립트 파일을 생성할 수 없습니다.", "error", 3000)
    end
end

-- wodac.sh 실행 함수
local function run_wodac()
    -- SCRIPT_PATH가 전역 또는 모듈 스코프에 설정되어 있어야 합니다.
    -- 설치가 완료된 후 Yazi가 재시작되면 SCRIPT_PATH는 비어있을 수 있습니다.
    -- 따라서 경로를 다시 계산하는 로직이 필요합니다.
    local plug_path = os.getenv("HOME") .. "/.config/yazi/plugins/wodac"
    local final_script_path = plug_path .. "/wodac.sh"

    local entry = ya.sync(function() return ya.current_entry() end)
    if not entry then
        ya.sync(function() ya.notify("Wodac 오류", "파일 선택 안 됨.", "error", 3000) end)
        return
    end
    
    local file_path_q = shell.quote(entry.url)
    
    -- Yazi가 멈추지 않도록 비동기 실행
    ya.exec("sh " .. shell.quote(final_script_path) .. " " .. file_path_q, true) 
end

-- 플러그인 노출
return {
    install = install_script,
    wodac = run_wodac,
}
