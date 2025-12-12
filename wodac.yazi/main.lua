local ya = require("yazi")
local shell = require("yazi.shell") -- shell 모듈 추가 (quote 함수 사용 위함)

-- Helper function to run CLI commands synchronously
local function run_cli(cmd)
    local f = io.popen(cmd)
    local result = f:read("*a")
    f:close()
    return result
end

local function select_default_app()
    local file_path = ya.sync(function() return ya.current_entry().url end)
    if not file_path then
        ya.sync(function() ya.notify("Wodac 오류/Error", "처리할 파일이 선택되지 않았습니다.", "error", 3000) end)
        return
    end

    local current_mime = run_cli("xdg-mime query filetype " .. shell.quote(file_path))
    current_mime = current_mime:gsub("%s+", "") -- Trim whitespace

    if not current_mime or current_mime == "" then
        ya.sync(function() ya.notify("Wodac 오류/Error", "선택한 파일의 MIME 타입을 알 수 없습니다.", "error", 3000) end)
        return
    end
    
    -- 3. Use Yazi/OS function to list matching applications
    local function get_apps_for_mime(mime)
        local apps = run_cli("grep -l \"MimeType=.*;" .. mime .. ";.*\" $(find /usr/share/applications/ ~/.local/share/applications/ -name '*.desktop') 2>/dev/null")
        return apps
    end

    local matching_paths = get_apps_for_mime(current_mime)
    
    if not matching_paths or matching_paths == "" then
        ya.sync(function() ya.notify("Wodac 오류/Error", "호환되는 애플리케이션을 찾을 수 없습니다.", "error", 3000) end)
        return
    end

    local app_list_formatted = {}
    for full_path in matching_paths:gmatch("([^\n]+)") do
        local app_name = run_cli("grep '^Name=' " .. shell.quote(full_path) .. " | cut -d'=' -f2 | head -n 1"):gsub("%s+", "")
        local exec_command = run_cli("grep '^Exec=' " .. shell.quote(full_path) .. " | cut -d'=' -f2- | head -n 1"):gsub("%s+", "")

        if app_name and app_name ~= "" and exec_command and exec_command ~= "" then
             table.insert(app_list_formatted, app_name .. ":" .. exec_command)
        end
    end

    -- Yazi의 `:select` 프롬프트에 Wodac 이름과 MIME 타입 표시
    local selected_app_exec = ya.sync(function()
        -- 프롬프트 메시지를 Wodac의 목적에 맞게 수정
        return ya.select("Wodac: 기본 앱 선택 / Select Default App for " .. current_mime, app_list_formatted)
    end)

    if selected_app_exec and selected_app_exec ~= "" then
        local selected_path = selected_app_exec:match(":(.*)") 
        local app_basename = selected_path:match(".*/([^/%.]+)%.desktop") .. ".desktop"

        run_cli("xdg-mime default " .. shell.quote(app_basename) .. " " .. shell.quote(current_mime))
        
        ya.sync(function() ya.notify("Wodac 성공/Success", "기본 앱이 " .. app_basename .. " 으로 설정되었습니다.", "info", 3000) end)

    else
        ya.sync(function() ya.notify("Wodac 취소/Cancel", "애플리케이션 선택이 취소되었습니다.", "info", 1500) end)
    end
end

-- 플러그인 외부 노출 이름은 계속 'wodac'을 사용합니다.
return {
    wodac = select_default_app,
}
