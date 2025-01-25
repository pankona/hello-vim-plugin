" 設定管理機能
" Author: Anonymous
" License: MIT

let s:config_dir = expand('~/.vim/plugin/hello-vim-plugin/settings')
let s:config_file = s:config_dir . '/config.json'

" デフォルト設定
let s:default_config = {
    \ 'debug': 1,
    \ 'tool_groups': {
        \ 'read': ['read_file', 'search_files', 'list_files', 'list_code_definition_names'],
        \ 'edit': ['write_to_file', 'apply_diff'],
        \ 'command': ['execute_command'],
        \ 'chat': ['send_chat_message']
    \ }
\ }

" 現在の設定
let s:config = deepcopy(s:default_config)

" 設定の初期化
function! hello_vim_plugin#config#init() abort
    " 設定ディレクトリの作成
    if !isdirectory(s:config_dir)
        call mkdir(s:config_dir, 'p')
    endif
    
    " 設定ファイルの読み込み
    if filereadable(s:config_file)
        let content = readfile(s:config_file)
        let loaded_config = json_decode(join(content, "\n"))
        call extend(s:config, loaded_config, 'force')
    else
        " デフォルト設定の保存
        call s:save_config()
    endif
endfunction

" 設定の保存
function! s:save_config() abort
    call writefile([json_encode(s:config)], s:config_file)
endfunction

" 設定値の取得
function! hello_vim_plugin#config#get(key) abort
    return get(s:config, a:key, get(s:default_config, a:key, v:null))
endfunction

" 設定値の設定
function! hello_vim_plugin#config#set(key, value) abort
    let s:config[a:key] = a:value
    call s:save_config()
endfunction

" ツールグループの取得
function! hello_vim_plugin#config#get_tool_groups() abort
    return deepcopy(s:config.tool_groups)
endfunction

" ツールグループのツール一覧を取得
function! hello_vim_plugin#config#get_tools_in_group(group) abort
    return get(s:config.tool_groups, a:group, [])
endfunction

" ツールが指定されたグループに属しているか確認
function! hello_vim_plugin#config#is_tool_in_group(tool, group) abort
    let tools = hello_vim_plugin#config#get_tools_in_group(a:group)
    return index(tools, a:tool) != -1
endfunction

" モードで使用可能なツールかどうかを確認
function! hello_vim_plugin#config#can_use_tool(tool) abort
    let current_mode = hello_vim_plugin#mode#get_current()
    let mode_config = hello_vim_plugin#mode#list_modes()[current_mode]
    
    " モードで許可されているグループを確認
    for group in mode_config.groups
        if hello_vim_plugin#config#is_tool_in_group(a:tool, group)
            return 1
        endif
    endfor
    
    return 0
endfunction

" デバッグモードの状態を取得
function! hello_vim_plugin#config#is_debug() abort
    return hello_vim_plugin#config#get('debug')
endfunction

" デバッグモードの切り替え
function! hello_vim_plugin#config#toggle_debug() abort
    let current = hello_vim_plugin#config#is_debug()
    call hello_vim_plugin#config#set('debug', !current)
    return !current
endfunction

" 設定のリセット
function! hello_vim_plugin#config#reset() abort
    let s:config = deepcopy(s:default_config)
    call s:save_config()
endfunction

" 初期化
call hello_vim_plugin#config#init()