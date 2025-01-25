#!/bin/bash

# テストの実行
vim -N -u NONE -n \
    --cmd "set nomore" \
    --cmd "set rtp+=/workspaces/hello-vim-plugin" \
    -S test/test.vim