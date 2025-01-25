" ツール管理機能
" Author: Anonymous
" License: MIT

" ツール実行前の権限チェック
function! hello_vim_plugin#tools#check_permission(tool) abort
    if !hello_vim_plugin#config#can_use_tool(a:tool)
        let current_mode = hello_vim_plugin#mode#get_current()
        throw 'Tool ' . a:tool . ' is not allowed in mode ' . current_mode
    endif
endfunction

" ファイル編集前の権限チェック
function! hello_vim_plugin#tools#check_file_permission(file) abort
    if !hello_vim_plugin#mode#can_edit_file(a:file)
        let current_mode = hello_vim_plugin#mode#get_current()
        throw 'File ' . a:file . ' cannot be edited in mode ' . current_mode
    endif
endfunction

" ファイル読み込み
function! hello_vim_plugin#tools#read_file(path) abort
    call hello_vim_plugin#tools#check_permission('read_file')
    
    let msg = {}
    let msg.type = 'file'
    let msg.content = {'operation': 'read', 'path': a:path}
    
    return hello_vim_plugin#rpc#send_request(msg)
endfunction

" ファイル書き込み
function! hello_vim_plugin#tools#write_file(args) abort
    call hello_vim_plugin#tools#check_permission('write_to_file')
    
    " 引数を解析
    let parts = split(a:args, '\s\+', 1)
    if len(parts) < 2
        echohl ErrorMsg
        echomsg 'Usage: HelloVimWrite <path> <content>'
        echohl None
        return
    endif

    let path = parts[0]
    let content = join(parts[1:], ' ')
    
    call hello_vim_plugin#tools#check_file_permission(path)
    
    let msg = {}
    let msg.type = 'file'
    let msg.content = {
        \ 'operation': 'write',
        \ 'path': path,
        \ 'content': content
    \ }
    
    return hello_vim_plugin#rpc#send_request(msg)
endfunction

" ファイル検索
function! hello_vim_plugin#tools#search_files(path, pattern) abort
    call hello_vim_plugin#tools#check_permission('search_files')
    
    let msg = {}
    let msg.type = 'file'
    let msg.content = {
        \ 'operation': 'search',
        \ 'path': a:path,
        \ 'pattern': a:pattern
    \ }
    
    return hello_vim_plugin#rpc#send_request(msg)
endfunction

" コマンド実行
function! hello_vim_plugin#tools#execute_command(command, ...) abort
    call hello_vim_plugin#tools#check_permission('execute_command')
    
    let msg = {}
    let msg.type = 'command'
    let msg.content = {
        \ 'command': a:command,
        \ 'args': a:000,
        \ 'dir': getcwd()
    \ }
    
    return hello_vim_plugin#rpc#send_request(msg)
endfunction

" チャットメッセージ送信
function! hello_vim_plugin#tools#send_chat_message(content) abort
    call hello_vim_plugin#tools#check_permission('send_chat_message')
    
    let msg = {}
    let msg.type = 'chat'
    let msg.content = {
        \ 'system_prompt': 'You are a helpful AI assistant.',
        \ 'messages': [{'role': 'user', 'content': a:content}]
    \ }
    
    return hello_vim_plugin#rpc#send_request(msg)
endfunction

" モード切り替え
function! hello_vim_plugin#tools#switch_mode(mode) abort
    try
        let mode_config = hello_vim_plugin#mode#switch(a:mode)
        echo 'Switched to ' . mode_config.name . ' mode'
        return 1
    catch
        echohl ErrorMsg
        echomsg 'Failed to switch mode: ' . v:exception
        echohl None
        return 0
    endtry
endfunction

" ツールのヘルプ表示
function! hello_vim_plugin#tools#show_help() abort
    let current_mode = hello_vim_plugin#mode#get_current()
    let mode_config = hello_vim_plugin#mode#list_modes()[current_mode]
    
    echo 'Current mode: ' . mode_config.name
    echo 'Available tools:'
    
    let tool_groups = hello_vim_plugin#config#get_tool_groups()
    for group in mode_config.groups
        let tools = hello_vim_plugin#config#get_tools_in_group(group)
        echo '  ' . group . ':'
        for tool in tools
            echo '    - ' . tool
        endfor
    endfor
endfunction

" コマンド補完
function! hello_vim_plugin#tools#complete_command(arg_lead, cmd_line, cursor_pos) abort
    let current_mode = hello_vim_plugin#mode#get_current()
    let mode_config = hello_vim_plugin#mode#list_modes()[current_mode]
    
    let available_commands = []
    for group in mode_config.groups
        let tools = hello_vim_plugin#config#get_tools_in_group(group)
        call extend(available_commands, tools)
    endfor
    
    return filter(available_commands, 'v:val =~ "^" . a:arg_lead')
endfunction

" モード補完
function! hello_vim_plugin#tools#complete_mode(arg_lead, cmd_line, cursor_pos) abort
    let modes = keys(hello_vim_plugin#mode#list_modes())
    return filter(modes, 'v:val =~ "^" . a:arg_lead')
endfunction