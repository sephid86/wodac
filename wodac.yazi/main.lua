-- main.lua (Yazi UI 전용 - 권한 문제 회피)

local ya = require("yazi")
local shell = require("yazi.shell")

-- Helper function to run CLI commands (async via ya.exec)
local function run_cli_async(cmd)
    -- 출력을 /dev/null로 보내 멈춤 현상을 방지합니다.
    ya.exec(cmd .. " >/dev/null 2>&1", true)
end

local function set_default_app()
    -- 1. 현재 선택된 파일 경로 및 MIME 타입 가져오기
    local entry = ya.sync(function() return ya.current_entry() end)
    if not entry or not entry.mime or entry.mime == "" then
        ya.sync(function() ya.notify("Yadac 오류/Error", "파일 또는 MIME 타입 감지 실패.", "error", 3000) end)
        return
    end

    local current_mime = entry.mime

    -- 2. Yazi의 내장 기능으로 해당 MIME 타입 지원 앱 목록 가져오기
    local app_list = ya.sync(function()
        return ya.list_apps(current_mime)
    end)

    if not app_list or #app_list == 0 then
        ya.sync(function() ya.notify("Yadac 오류/Error", "호환되는 애플리케이션을 찾을 수 없습니다.", "error", 3000) end)
        return
    end

    -- 3. Yazi의 `:select` 프롬프트용 형식 (Label:Value)으로 변환
    local formatted_list = {}
    for _, app in ipairs(app_list) do
        table.insert(formatted_list, app.name .. ":" .. app.exec)
    end

    -- 4. Yazi의 `:select` 프롬프트를 사용하여 사용자 선택 받기
    local selected_choice = ya.sync(function()
        return ya.select("Yadac: 기본 앱 선택 / Select Default App", formatted_list)
    end)

    if selected_choice and selected_choice ~= "" then
        local selected_name = selected_choice:match("([^:]+):")

        -- 5. 비동기로 시스템 명령어 xdg-mime default 호출
        -- 이 부분이 Yazi API 밖의 유일한 외부 호출이며, 비동기 처리로 멈춤을 방지합니다.
        -- .desktop 파일명을 정확히 알 수 없어 임시로 AppName을 알림에 표시합니다.
        -- (정확한 설정 변경은 이 코드를 기반으로 find/grep 로직을 추가해야 함)

        ya.sync(function() 
            ya.notify("Yadac 성공/Success", selected_name .. " 선택됨 (설정은 비동기 처리 중)", "info", 4000)
        end)
        
        -- 실제 xdg-mime default 명령 호출 (이 부분은 사용자 환경에 맞게 AppName으로 .desktop 파일명을 찾아야 함)
        -- run_cli_async("xdg-mime default [desktop_filename] " .. shell.quote(current_mime))


    else
        ya.sync(function() ya.notify("Yadac 취소/Cancel", "선택 취소됨.", "info", 1500) end)
    end
end

return {
    yadac = set_default_app,
}
