#!/bin/bash

# 作業ディレクトリを設定
cd /workspaces/hello-vim-plugin

# 環境変数を設定
source /home/codespace/.bashrc

# ログファイルをクリア
rm -f test.log debug.log go_output.log

# デバッグモードを有効化
export VIM_DEBUG=1

# Goプログラムの出力をリダイレクト
export GO_LOG_FILE="go_output.log"

# Vimでテストを実行
vim -u NONE \
    --cmd "set nocp" \
    --cmd "set rtp+=/workspaces/hello-vim-plugin" \
    --cmd "let g:go_log_file = '$GO_LOG_FILE'" \
    -S test/test.vim \
    -V1debug.log

# Goプログラムの出力を表示
echo "=== Go Program Output ==="
cat "$GO_LOG_FILE"