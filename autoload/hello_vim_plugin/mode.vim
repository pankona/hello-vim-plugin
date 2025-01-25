" モード管理機能
" Author: Anonymous
" License: MIT

let s:mode_config_file = expand('~/.vim/plugin/hello-vim-plugin/settings/modes.json')
let s:default_mode = 'code'
let s:current_mode = s:default_mode

" モード設定の初期化
function! hello_vim_plugin#mode#init() abort
    " 設定ディレクトリの作成
    call s:ensure_config_dir_exists()
    
    " デフォルトのモード設定
    let s:modes = {
        \ 'code': {
            \ 'name': 'Code',
            \ 'role_definition': 'You are Roo, a highly skilled software engineer with extensive knowledge in many programming languages, frameworks, design patterns, and best practices',
            \ 'groups': ['read', 'edit', 'command', 'chat'],
            \ 'file_patterns': []
        \ },
        \ 'architect': {
            \ 'name': 'Architect',
            \ 'role_definition': 'You are Roo, a software architecture expert specializing in analyzing codebases, identifying patterns, and providing high-level technical guidance',
            \ 'groups': ['read', 'chat'],
            \ 'file_patterns': ['\.md$']
        \ }
    \ }
    
    " カスタムモード設定の読み込み
    call s:load_mode_config()
endfunction

" 現在のモードを取得
function! hello_vim_plugin#mode#get_current() abort
    return s:current_mode
endfunction

" モードの切り替え
function! hello_vim_plugin#mode#switch(mode) abort
    if !has_key(s:modes, a:mode)
        throw 'Invalid mode: ' . a:mode
    endif
    let s:current_mode = a:mode
    return s:modes[a:mode]
endfunction

" ファイル編集の権限チェック
function! hello_vim_plugin#mode#can_edit_file(file) abort
    let mode = s:modes[s:current_mode]
    
    " 編集グループがない場合は編集不可
    if index(mode.groups, 'edit') == -1
        return 0
    endif
    
    " ファイルパターンが指定されている場合はチェック
    if !empty(mode.file_patterns)
        for pattern in mode.file_patterns
            if a:file =~# pattern
                return 1
            endif
        endfor
        return 0
    endif
    
    " パターンがない場合は編集可能
    return 1
endfunction

" 設定ディレクトリの存在確認と作成
function! s:ensure_config_dir_exists() abort
    let config_dir = fnamemodify(s:mode_config_file, ':h')
    if !isdirectory(config_dir)
        call mkdir(config_dir, 'p')
    endif
endfunction

" モード設定の読み込み
function! s:load_mode_config() abort
    if filereadable(s:mode_config_file)
        let content = readfile(s:mode_config_file)
        let custom_modes = json_decode(join(content, "\n"))
        call extend(s:modes, custom_modes)
    endif
endfunction

" モード設定の保存
function! s:save_mode_config() abort
    let config_dir = fnamemodify(s:mode_config_file, ':h')
    if !isdirectory(config_dir)
        call mkdir(config_dir, 'p')
    endif
    call writefile([json_encode(s:modes)], s:mode_config_file)
endfunction

" カスタムモードの追加
function! hello_vim_plugin#mode#add_custom_mode(config) abort
    " バリデーション
    if !has_key(a:config, 'slug') || !has_key(a:config, 'name') || 
        \ !has_key(a:config, 'role_definition') || !has_key(a:config, 'groups')
        throw 'Invalid mode configuration'
    endif
    
    " スラッグのバリデーション
    if a:config.slug !~# '^[a-zA-Z0-9-]\+$'
        throw 'Invalid slug format'
    endif
    
    " 既存モードの確認
    if has_key(s:modes, a:config.slug)
        throw 'Mode already exists: ' . a:config.slug
    endif
    
    " モードの追加
    let s:modes[a:config.slug] = {
        \ 'name': a:config.name,
        \ 'role_definition': a:config.role_definition,
        \ 'groups': a:config.groups,
        \ 'file_patterns': get(a:config, 'file_patterns', [])
    \ }
    
    " 設定の保存
    call s:save_mode_config()
endfunction

" カスタムモードの削除
function! hello_vim_plugin#mode#remove_custom_mode(slug) abort
    if !has_key(s:modes, a:slug)
        throw 'Mode not found: ' . a:slug
    endif
    
    " デフォルトモードは削除不可
    if a:slug ==# 'code' || a:slug ==# 'architect'
        throw 'Cannot remove default mode: ' . a:slug
    endif
    
    " 現在のモードを削除する場合はデフォルトモードに切り替え
    if s:current_mode ==# a:slug
        let s:current_mode = s:default_mode
    endif
    
    " モードの削除
    unlet s:modes[a:slug]
    
    " 設定の保存
    call s:save_mode_config()
endfunction

" 利用可能なモードの一覧を取得
function! hello_vim_plugin#mode#list_modes() abort
    return copy(s:modes)
endfunction

" 初期化
call hello_vim_plugin#mode#init()