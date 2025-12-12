-- main.lua (Yazi API + Wofi 호출)

local ya = require("yazi")
local shell = require("yazi.shell")

-- Helper function to run CLI commands asynchronously (for final xdg-mime default)
local function run_cli_async(cmd)
    ya.exec(cmd .. " >/dev/null 2>&1", true)
end

-- Helper function to run CLI commands synchronously and return output (minimal use)
local function run_cli_output(cmd)
    local f = io.popen(cmd)
    if not f then return "" end
    local result = f:read("*a")
    f:close()
    return result or ""
end


local function run_wodac_with_wofi()
    local entry = ya.sync(function() return ya.current_entry() end)
    if not entry or not entry.mime or entry.mime == "" then
        ya.sync(function() ya.notify("Wodac 오류/Error", "파일 또는 MIME 타입 감지 실패.", "error", 3000) end)
        return
    end

    local current_mime = entry.mime

    -- Yazi API를 사용하여 지원 앱 목록 가져오기
    local app_list = ya.sync(function()
        return ya.list_apps(current_mime)
    end)

    if not app_list or #app_list == 0 then
        ya.sync(function() ya.notify("Wodac 오류/Error", "호환되는 애플리케이션을 찾을 수 없습니다.", "error", 3000) end)
        return
    end

    -- Wofi 입력을 위해 "AppName:ExecCommand" 형식의 문자열 리스트 생성
    local wofi_input = ""
    for _, app in ipairs(app_list) do
        -- Yazi API는 .desktop 파일명을 제공하지 않으므로, Exec 명령어로 대체하여 Wofi에 전달
        -- Wofi에서 선택된 후 후처리 로직이 필요함 (아래 참조)
        wofi_input = wofi_input .. app.name .. ":" .. app.exec .. "\n"
    end
    
    -- 후처리를 위해 임시 맵 파일 사용 (Bash 스크립트와 동일한 방식)
    local MAP_FILE = "/tmp/wofi_yazi_map.txt"
    run_cli_async("rm -f " .. shell.quote(MAP_FILE))
    -- 모든 app 정보를 맵 파일에 저장 (appName:desktopFileBasename) 유추 필요
    for _, app in ipairs(app_list) do
        -- .desktop 파일명을 유추하기 위해 grep 사용 (외부 명령어 최소화)
        local desktop_file_basename = run_cli_output("grep -l 'Name=" .. app.name .. "' /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop | head -n 1 | xargs basename")

        if desktop_file_basename ~= "" then
            run_cli_async("echo " .. shell.quote(app.name .. ":" .. desktop_file_basename) .. " >> " .. shell.quote(MAP_FILE))
        end
    end


    -- Wofi 실행 명령 (출력을 받기 위해 io.popen 사용, 동기 실행)
    local selected_choice = run_cli_output("echo -e " .. shell.quote(wofi_input) .. " | wofi -d -p '기본 앱 선택 / Select Default App:'")

    if selected_choice ~= "" then
        local app_name = selected_choice:match("([^:]+):")

        -- 맵 파일에서 .desktop 파일명 찾기
        local app_basename = run_cli_output("grep '^" .. app_name .. ":' " .. shell.quote(MAP_FILE) .. " | cut -d':' -f2 | head -n 1")

        if app_basename ~= "" then
            -- xdg-mime default 시스템 명령 비동기 실행
            run_cli_async("xdg-mime default " .. shell.quote(app_basename) .. " " .. shell.quote(current_mime))
            ya.sync(function() 
                ya.notify("Wodac 성공/Success", "기본 앱이 " .. app_basename .. " 으로 설정되었습니다.", "info", 3000)
            end)
        end
    end
    run_cli_async("rm -f " .. shell.quote(MAP_FILE))
end

-- 플러그인 노출
return {
    wodac = run_wodac_with_wofi,
}
