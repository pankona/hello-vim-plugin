" RPC通信管理
" Author: Anonymous
" License: MIT

" リクエストの送信
function! hello_vim_plugin#rpc#send_request(msg) abort
    if g:hello_vim_plugin_job == v:null
        throw 'Plugin is not running'
    endif

    let channel = job_getchannel(g:hello_vim_plugin_job)
    if ch_status(channel) !=# 'open'
        throw 'Channel is not open'
    endif

    call ch_sendraw(channel, json_encode(a:msg) . "\n")
    call s:debug_print('sent message: ' . json_encode(a:msg))
endfunction

" デバッグログ出力
function! s:debug_print(msg) abort
    if hello_vim_plugin#config#is_debug()
        echomsg '[hello-vim-plugin] ' . a:msg
        call writefile(['[' . strftime('%H:%M:%S') . '] ' . a:msg], 'vim_debug.log', 'a')
    endif
endfunction