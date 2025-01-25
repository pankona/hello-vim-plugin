" hello-vim-plugin.vim - Roo Codeライクな機能を持つVimプラグイン
" Maintainer: Anonymous
" Version: 0.1.0

if exists('g:loaded_hello_vim_plugin')
    finish
endif
let g:loaded_hello_vim_plugin = 1

" vim 8.0以上が必要
if v:version < 800
    echohl ErrorMsg
    echomsg 'hello-vim-plugin requires Vim 8.0 or later'
    echohl None
    finish
endif

" グローバル変数のデフォルト値設定
let g:hello_vim_plugin_debug = 1  " デバッグモードを有効化
let g:hello_vim_plugin_job = v:null
let g:hello_vim_plugin_buffer = -1
let g:hello_vim_plugin_current_message = ''

" メッセージバッファの作成
function! s:create_message_buffer() abort
    " 新しいバッファを作成
    execute 'new'
    let buf = bufnr('%')
    
    " バッファの設定
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    execute 'silent file hello-vim-plugin://chat'
    
    return buf
endfunction

" メッセージの表示
function! s:display_message(role, content) abort
    if g:hello_vim_plugin_buffer == -1 || !bufexists(g:hello_vim_plugin_buffer)
        let g:hello_vim_plugin_buffer = s:create_message_buffer()
    endif

    let lines = []
    call add(lines, '[' . a:role . ']')
    call add(lines, a:content)
    call add(lines, '')

    " バッファが表示されていない場合は表示する
    if bufwinnr(g:hello_vim_plugin_buffer) == -1
        execute 'vsplit'
        execute 'buffer' g:hello_vim_plugin_buffer
    endif

    " バッファに切り替え
    let winnr = bufwinnr(g:hello_vim_plugin_buffer)
    if winnr != -1
        execute winnr . 'wincmd w'
        setlocal modifiable
        
        " メッセージを追加
        call append(line('$') - 1, lines)
        normal! G
        setlocal nomodifiable
        
        call s:debug_print('Added message: role=' . a:role . ', content=' . a:content)
    endif
endfunction

" デバッグログ出力
function! s:debug_print(msg) abort
    if g:hello_vim_plugin_debug
        echomsg '[hello-vim-plugin] ' . a:msg
        call writefile(['[' . strftime('%H:%M:%S') . '] ' . a:msg], 'vim_debug.log', 'a')
    endif
endfunction

" チャネルコールバック
function! s:on_stdout(channel, msg) abort
    call s:debug_print('received raw: ' . string(a:msg))
    try
        let data = json_decode(a:msg)
        call s:debug_print('parsed json: ' . string(data))
        
        if data.type == 'response'
            " レスポンスを現在のメッセージに追加
            let g:hello_vim_plugin_current_message .= data.content
            
            " バッファの最後の行を更新
            let winnr = bufwinnr(g:hello_vim_plugin_buffer)
            if winnr != -1
                execute winnr . 'wincmd w'
                setlocal modifiable
                let last_role_line = search('\[assistant\]', 'b')
                if last_role_line > 0
                    call setline(last_role_line + 1, g:hello_vim_plugin_current_message)
                endif
                normal! G
                setlocal nomodifiable
                call s:debug_print('Updated message: ' . g:hello_vim_plugin_current_message)
            endif
        elseif data.type == 'status'
            call s:debug_print('status: ' . data.content)
        endif
    catch
        call s:debug_print('error parsing message: ' . v:exception . ' at ' . v:throwpoint)
    endtry
endfunction

function! s:on_stderr(channel, msg) abort
    call s:debug_print('stderr: ' . string(a:msg))
endfunction

function! s:on_exit(channel, status) abort
    call s:debug_print('process exited with code: ' . a:status)
    let g:hello_vim_plugin_job = v:null
endfunction

" プラグインの起動
function! s:start() abort
    if g:hello_vim_plugin_job != v:null
        echomsg 'hello-vim-plugin is already running'
        return
    endif

    " OpenAI APIキーの確認
    if empty($OPENAI_API_KEY)
        echohl ErrorMsg
        echomsg 'OPENAI_API_KEY environment variable is required'
        echohl None
        return
    endif

    " カレントディレクトリをプロジェクトルートに変更
    let save_cwd = getcwd()
    execute 'cd ' . '/workspaces/hello-vim-plugin'

    let cmd = ['go', 'run', 'cmd/hello-vim-plugin/main.go']
    let options = {}
    let options.out_cb = function('s:on_stdout')
    let options.err_cb = function('s:on_stderr')
    let options.exit_cb = function('s:on_exit')
    let options.mode = 'nl'
    
    call s:debug_print('starting with command: ' . string(cmd))
    let job = job_start(cmd, options)
    
    call s:debug_print('job status: ' . job_status(job))
    if job_status(job) !=# 'run'
        echohl ErrorMsg
        echomsg 'Failed to start hello-vim-plugin process'
        echohl None
        execute 'cd ' . save_cwd
        return
    endif

    let g:hello_vim_plugin_job = job
    call s:debug_print('started with job: ' . string(job))
    
    " 元のディレクトリに戻る
    execute 'cd ' . save_cwd
endfunction

" プラグインの停止
function! s:stop() abort
    if g:hello_vim_plugin_job == v:null
        echomsg 'hello-vim-plugin is not running'
        return
    endif

    call job_stop(g:hello_vim_plugin_job)
    call s:debug_print('stopped job: ' . string(g:hello_vim_plugin_job))
endfunction

" チャットメッセージの送信
function! s:send_chat_message(content) abort
    if g:hello_vim_plugin_job == v:null
        echomsg 'hello-vim-plugin is not running'
        return
    endif

    " 新しいメッセージを開始
    let g:hello_vim_plugin_current_message = ''
    
    call s:display_message('user', a:content)
    call s:display_message('assistant', '')  " 応答用の空行を追加

    let request = {}
    let request.system_prompt = 'You are a helpful AI assistant.'
    let request.messages = [{'role': 'user', 'content': a:content}]

    let msg = {}
    let msg.type = 'chat'
    let msg.content = request

    let channel = job_getchannel(g:hello_vim_plugin_job)
    call ch_sendraw(channel, json_encode(msg) . "\n")
    call s:debug_print('sent message: ' . json_encode(msg))
endfunction

" コマンドの定義
command! -nargs=0 HelloVimPluginStart call s:start()
command! -nargs=0 HelloVimPluginStop call s:stop()
command! -nargs=+ HelloVimChat call s:send_chat_message(<q-args>)

" キーマッピング
if !hasmapto('<Plug>(hello-vim-plugin-start)')
    nmap <unique> <Leader>hs <Plug>(hello-vim-plugin-start)
endif
if !hasmapto('<Plug>(hello-vim-plugin-stop)')
    nmap <unique> <Leader>hq <Plug>(hello-vim-plugin-stop)
endif

nnoremap <Plug>(hello-vim-plugin-start) :HelloVimPluginStart<CR>
nnoremap <Plug>(hello-vim-plugin-stop) :HelloVimPluginStop<CR>