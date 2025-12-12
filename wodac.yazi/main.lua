-- main.lua (Wodac: Yazi Default App Chooser)

local ya = require("yazi")
local shell = require("yazi.shell")

-- Helper function to run CLI commands synchronously and return output
local function run_cli_output(cmd)
    local f = io.popen(cmd)
    if not f then return "" end
    local result = f:read("*a")
    f:close()
    return result or ""
end

-- Helper function to run CLI commands (async, no output needed)
local function run_cli(cmd)
    os.execute(cmd .. " >/dev/null 2>&1")
end

local function select_default_app()
    -- 1. 현재 선택된 파일 경로 및 MIME 타입 가져오기
    local entry = ya.sync(function() return ya.current_entry() end)
    if not entry or not entry.mime or entry.mime == "" then
        ya.sync(function() ya.notify("Wodac 오류/Error", "파일 또는 MIME 타입 감지 실패.", "error", 3000) end)
        return
    end

    local current_mime = entry.mime
    local file_path_q = shell.quote(entry.url)
    
    -- 2. Bash 스크립트 로직을 사용하여 .desktop 파일 목록 및 이름 파싱
    local all_desktop_paths_cmd = "find /usr/share/applications/ ~/.local/share/applications/ -name '*.desktop'"
    local matching_paths_cmd = "grep -l 'MimeType=.*;" .. current_mime .. ";.*' $(" .. all_desktop_paths_cmd .. ") 2>/dev/null"
    
    local matching_paths_str = run_cli_output(matching_paths_cmd)
    
    -- 3. Yazi 프롬프트용 형식 (AppName:DesktopFilePath)으로 변환
    local app_list_formatted = {}
    local map_file_path = os.getenv("HOME") .. "/.config/yazi/wodac_map.txt"
    run_cli("rm -f " .. shell.quote(map_file_path)) -- 임시 맵 파일 정리
    
    local function process_list(list_str, separator)
        for full_path in list_str:gmatch("([^\n]+)") do
            local app_name = run_cli_output("grep '^Name=' " .. shell.quote(full_path) .. " | cut -d'=' -f2 | head -n 1")
            if app_name ~= "" then
                table.insert(app_list_formatted, app_name .. ":" .. full_path)
                run_cli("echo " .. shell.quote(app_name .. ":" .. full_path) .. " >> " .. shell.quote(map_file_path))
            end
        end
        if separator then
             table.insert(app_list_formatted, "----------:/dev/null")
             run_cli("echo " .. shell.quote("----------:/dev/null") .. " >> " .. shell.quote(map_file_path))
        end
    end

    -- 일치하는 목록 우선 처리
    process_list(matching_paths_str, true)

    -- 일치하지 않는 나머지 목록 처리 (comm -3 로직은 Lua에서 복잡하여 생략, 전체 목록에서 grep -L 사용)
    local non_matching_paths_cmd = "grep -L 'MimeType=.*;" .. current_mime .. ";.*' $(" .. all_desktop_paths_cmd .. ") 2>/dev/null"
    local non_matching_paths_str = run_cli_output(non_matching_paths_cmd)
    process_list(non_matching_paths_str, false)


    -- 4. Yazi의 `:select` 프롬프트를 사용하여 사용자 선택 받기
    local selected_choice = ya.sync(function()
        return ya.select("Wodac: 기본 앱 선택 / Select Default App", app_list_formatted)
    end)

    if selected_choice and selected_choice ~= "" and selected_choice:find(":/dev/null") == nil then
        -- 5. 선택된 앱의 .desktop 파일명을 추출하여 xdg-mime default 설정
        local selected_path = selected_choice:match(":(.*)")
        local app_basename = selected_path:match("[^/]+$") -- 파일 이름(basename)만 추출 (예: firefox.desktop)

        -- xdg-mime default 시스템 명령 비동기 실행
        run_cli("xdg-mime default " .. shell.quote(app_basename) .. " " .. shell.quote(current_mime))
        
        ya.sync(function() 
            ya.notify("Wodac 성공/Success", "기본 앱이 " .. app_basename .. " 으로 설정되었습니다.", "info", 3000)
        end)
    else
        ya.sync(function() ya.notify("Wodac 취소/Cancel", "애플리케이션 선택이 취소되었습니다.", "info", 1500) end)
    end

    -- 임시 파일 정리
    run_cli("rm -f " .. shell.quote(map_file_path))

end

-- install 함수는 이 버전에서는 필요 없습니다 (스크립트 파일을 별도 설치하지 않기 때문)
return {
    wodac = select_default_app,
}
