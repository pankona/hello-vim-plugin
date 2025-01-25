" テスト用スクリプト
set nocompatible
set rtp+=/workspaces/hello-vim-plugin
runtime plugin/hello-vim-plugin.vim

" デバッグモードを有効化
let g:hello_vim_plugin_debug = 1

" テストファイルの作成
function! s:setup_test_files()
    " テスト用ディレクトリの作成
    call mkdir('test/tmp', 'p')
    " 少量のテストファイルを作成
    call writefile(['Test content 1'], 'test/tmp/test1.txt')
    call writefile(['Test content 2'], 'test/tmp/test2.txt')
endfunction

" テストファイルの削除
function! s:cleanup_test_files()
    " テスト用ディレクトリの削除
    call delete('test/tmp', 'rf')
endfunction

" テスト実行関数
function! RunTest()
    call s:log('テスト開始')
    
    " テストファイルの準備
    call s:setup_test_files()
    call s:log('テストファイル作成完了')
    
    " プラグインを起動
    call s:log('プラグイン起動')
    HelloVimPluginStart
    
    " プラグインの起動を待機
    sleep 2
    call s:log('起動待機完了')
    
    " ファイル読み込みテスト
    call s:log('ファイル読み込みテスト開始')
    execute 'HelloVimRead test/tmp/test1.txt'
    sleep 2
    
    " ファイル書き込みテスト
    call s:log('ファイル書き込みテスト開始')
    execute 'HelloVimWrite test/tmp/output.txt Test content for writing.'
    sleep 2
    
    " ファイル検索テスト（範囲を限定）
    call s:log('ファイル検索テスト開始')
    execute 'HelloVimSearch test/tmp test'
    sleep 2
    
    " コマンド実行テスト（ls）
    call s:log('コマンド実行テスト開始: ls')
    execute 'HelloVimCommand ls test/tmp'
    sleep 2
    
    " コマンド実行テスト（echo）
    call s:log('コマンド実行テスト開始: echo')
    execute 'HelloVimCommand echo "Hello from command test!"'
    sleep 2
    
    " チャットテスト
    call s:log('チャットテスト開始')
    execute 'HelloVimChat こんにちは、コマンド実行機能のテスト中です。'
    sleep 5
    
    " プラグインを停止
    call s:log('プラグイン停止')
    HelloVimPluginStop
    
    " テストファイルの削除
    call s:cleanup_test_files()
    call s:log('テストファイル削除完了')
    
    call s:log('テスト終了')
    
    " テスト終了
    qall!
endfunction

" ログ出力
function! s:log(msg)
    call writefile([strftime('%H:%M:%S') . ' ' . a:msg], 'test.log', 'a')
endfunction

" テストの実行
call RunTest()