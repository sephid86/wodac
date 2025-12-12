#!/bin/bash
# 
# wodac (Wofi Default App Chooser)
#
# Copyright (C) 2025 AI on Google Search (Gemini) (as the developer of the underlying AI model)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <www.gnu.org>.

# 스크립트 본문 시작
FILE_PATH="$1"
MAP_FILE="/tmp/wofi_path_map.txt"
rm -f "$MAP_FILE"

if [ -z "$FILE_PATH" ]; then
    echo "오류: 처리할 파일 경로가 제공되지 않았습니다."
    echo "Error: No file path provided for processing."
    # 사용자에게 알림 표시 (notify-send가 설치된 경우)
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
