# hello-vim-plugin

Roo Codeライクな機能を提供するVimプラグイン

## 機能

- 自然言語でのコミュニケーション（OpenAI APIを使用）
- ワークスペース内のファイル読み書き（実装予定）
- ターミナルコマンドの実行（実装予定）
- OpenAI互換/カスタムAPI・モデルとの統合（実装予定）
- カスタムモードによる柔軟な対応（実装予定）

## 要件

- Vim 8.0以上（チャネル機能をサポート）
- Go 1.16以上
- OpenAI APIキー

## インストール

### 1. 依存関係のインストール

```bash
cd cmd/hello-vim-plugin
go mod tidy
```

### 2. OpenAI APIキーの設定

環境変数に`OPENAI_API_KEY`を設定してください：

```bash
export OPENAI_API_KEY='your-api-key-here'
```

オプションで、使用するモデルを指定することもできます：

```bash
export OPENAI_MODEL='gpt-4-turbo-preview'  # デフォルト値
```

### 3. Vimプラグインのインストール

お好みのプラグインマネージャーを使用してインストールできます。

例：vim-plug を使用する場合：

```viml
Plug 'your-username/hello-vim-plugin'
```

## 使い方

### プラグインの起動/停止

1. プラグインの起動：
```vim
:HelloVimPluginStart
```

2. プラグインの停止：
```vim
:HelloVimPluginStop
```

### チャット機能の使用

メッセージの送信：
```vim
:HelloVimChat こんにちは、今日の天気はどうですか？
```

### キーマッピング

デフォルトのキーマッピング：
- `<Leader>hs` - プラグインの起動
- `<Leader>hq` - プラグインの停止

カスタムキーマッピングの設定例：
```viml
" プラグインの起動
nmap <Leader>ss <Plug>(hello-vim-plugin-start)

" プラグインの停止
nmap <Leader>sq <Plug>(hello-vim-plugin-stop)
```

### デバッグモード

デバッグログを有効にする場合：

```vim
let g:hello_vim_plugin_debug = 1
```

## アーキテクチャ

このプラグインは以下のコンポーネントで構成されています：

1. Vimプラグイン（plugin/hello-vim-plugin.vim）
   - チャネル通信の管理
   - UIの制御
   - コマンドとキーマッピングの提供

2. GoバックエンドCLI（cmd/hello-vim-plugin）
   - OpenAI APIとの通信
   - メッセージの処理
   - ストリーミングレスポンスの管理

通信は標準入出力を介したJSONメッセージングで行われます。

## 開発

詳細な設計ドキュメントは [DESIGN.md](docs/DESIGN.md) を参照してください。

### プロジェクト構造

```
.
├── plugin/
│   └── hello-vim-plugin.vim  # プラグインのメインエントリーポイント
├── cmd/
│   └── hello-vim-plugin/     # Go CLIツール
│       ├── main.go
│       └── go.mod
└── docs/
    └── DESIGN.md            # 設計ドキュメント
```

## ライセンス

MIT

## 貢献

Issue や Pull Request は歓迎します。