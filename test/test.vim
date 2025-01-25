" テスト用スクリプト
set nocompatible
set rtp+=/workspaces/hello-vim-plugin
runtime plugin/hello-vim-plugin.vim

" デバッグモードを有効化
let g:hello_vim_plugin_debug = 1

" テストログ出力
function! s:log(msg)
    call writefile([strftime('%H:%M:%S') . ' ' . a:msg], 'test.log', 'a')
endfunction

" テスト実行関数
function! RunTest()
    call s:log('テスト開始')
    
    " プラグインを起動
    call s:log('プラグイン起動')
    HelloVimPluginStart
    
    " プラグインの起動を待機
    sleep 2
    call s:log('起動待機完了')
    
    " チャットメッセージを送信
    call s:log('メッセージ送信: こんにちは、あなたは誰ですか？')
    HelloVimChat こんにちは、あなたは誰ですか？
    
    " レスポンスを待機
    sleep 5
    call s:log('レスポンス待機完了')
    
    " バッファの内容を確認
    let l:bufnr = bufnr('hello-vim-plugin://chat')
    if l:bufnr != -1
        let l:content = getbufline(l:bufnr, 1, '$')
        call s:log('バッファ内容:')
        for l:line in l:content
            call s:log('  ' . l:line)
        endfor
    else
        call s:log('チャットバッファが見つかりません')
    endif
    
    " プラグインを停止
    call s:log('プラグイン停止')
    HelloVimPluginStop
    
    " 終了前に少し待機
    sleep 1
    call s:log('テスト終了')
    
    " テスト終了
    qall!
endfunction

" テストの実行
call RunTest()