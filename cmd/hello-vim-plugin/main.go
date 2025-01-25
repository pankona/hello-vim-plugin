package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"

	openai "github.com/sashabaranov/go-openai"
)

// Message はVimプラグインとの通信に使用するメッセージ構造体
type Message struct {
	Type    string      `json:"type"`
	Content interface{} `json:"content"`
}

// APIRequest はVimプラグインからのAPI要求を表す構造体
type APIRequest struct {
	SystemPrompt string                         `json:"system_prompt"`
	Messages     []openai.ChatCompletionMessage `json:"messages"`
}

// FileOperation はファイル操作要求を表す構造体
type FileOperation struct {
	Operation string `json:"operation"` // "read", "write", "search"
	Path      string `json:"path"`
	Content   string `json:"content,omitempty"`
	Pattern   string `json:"pattern,omitempty"`
}

// FileResponse はファイル操作の結果を表す構造体
type FileResponse struct {
	Success bool     `json:"success"`
	Content string   `json:"content,omitempty"`
	Matches []string `json:"matches,omitempty"`
	Error   string   `json:"error,omitempty"`
}

// OpenAIClient はOpenAI APIとの通信を担当する構造体
type OpenAIClient struct {
	client *openai.Client
	model  string
	logger *os.File
}

// NewOpenAIClient は新しいOpenAIClientインスタンスを作成する
func NewOpenAIClient(apiKey string, model string, logFile string) (*OpenAIClient, error) {
	var logger *os.File
	var err error

	if logFile != "" {
		logger, err = os.OpenFile(logFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err != nil {
			return nil, fmt.Errorf("failed to open log file: %v", err)
		}
	}

	return &OpenAIClient{
		client: openai.NewClient(apiKey),
		model:  model,
		logger: logger,
	}, nil
}

func (c *OpenAIClient) log(format string, args ...interface{}) {
	if c.logger != nil {
		fmt.Fprintf(c.logger, format+"\n", args...)
	}
}

// CreateChatCompletion はチャット補完を作成する
func (c *OpenAIClient) CreateChatCompletion(ctx context.Context, req APIRequest) (*openai.ChatCompletionStream, error) {
	messages := make([]openai.ChatCompletionMessage, 0, len(req.Messages)+1)

	// システムプロンプトを追加
	if req.SystemPrompt != "" {
		messages = append(messages, openai.ChatCompletionMessage{
			Role:    openai.ChatMessageRoleSystem,
			Content: req.SystemPrompt,
		})
	}

	// ユーザーメッセージを追加
	messages = append(messages, req.Messages...)

	c.log("Creating chat completion with messages: %+v", messages)

	stream, err := c.client.CreateChatCompletionStream(
		ctx,
		openai.ChatCompletionRequest{
			Model:       c.model,
			Messages:    messages,
			Temperature: 0,
			Stream:      true,
		},
	)
	if err != nil {
		return nil, fmt.Errorf("chat completion error: %v", err)
	}

	return stream, nil
}

// handleFileOperation はファイル操作を処理する
func handleFileOperation(op FileOperation) FileResponse {
	switch op.Operation {
	case "read":
		return readFile(op.Path)
	case "write":
		return writeFile(op.Path, op.Content)
	case "search":
		return searchFiles(op.Path, op.Pattern)
	default:
		return FileResponse{
			Success: false,
			Error:   fmt.Sprintf("unknown operation: %s", op.Operation),
		}
	}
}

// readFile はファイルを読み込む
func readFile(path string) FileResponse {
	content, err := os.ReadFile(path)
	if err != nil {
		return FileResponse{
			Success: false,
			Error:   fmt.Sprintf("failed to read file: %v", err),
		}
	}

	return FileResponse{
		Success: true,
		Content: string(content),
	}
}

// writeFile はファイルに書き込む
func writeFile(path string, content string) FileResponse {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return FileResponse{
			Success: false,
			Error:   fmt.Sprintf("failed to create directory: %v", err),
		}
	}

	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		return FileResponse{
			Success: false,
			Error:   fmt.Sprintf("failed to write file: %v", err),
		}
	}

	return FileResponse{
		Success: true,
	}
}

// searchFiles はファイルを検索する
func searchFiles(path string, pattern string) FileResponse {
	var matches []string
	err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			content, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			if strings.Contains(string(content), pattern) {
				matches = append(matches, path)
			}
		}
		return nil
	})

	if err != nil {
		return FileResponse{
			Success: false,
			Error:   fmt.Sprintf("failed to search files: %v", err),
		}
	}

	return FileResponse{
		Success: true,
		Matches: matches,
	}
}

// sendMessage はメッセージをJSON形式で標準出力に送信する
func sendMessage(msg Message) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("error encoding message: %v", err)
	}
	fmt.Printf("%s\n", string(data))
	return nil
}

func main() {
	// 環境変数からAPIキーとモデルを取得
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Fprintf(os.Stderr, "OPENAI_API_KEY environment variable is required\n")
		os.Exit(1)
	}

	model := os.Getenv("OPENAI_MODEL")
	if model == "" {
		model = openai.GPT4TurboPreview // デフォルトモデル
	}

	logFile := os.Getenv("GO_LOG_FILE")

	// OpenAIクライアントの初期化
	client, err := NewOpenAIClient(apiKey, model, logFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to initialize OpenAI client: %v\n", err)
		os.Exit(1)
	}
	if client.logger != nil {
		defer client.logger.Close()
	}

	client.log("Starting hello-vim-plugin with model: %s", model)

	// シグナルハンドリングの設定
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 標準入力のスキャナー設定
	scanner := bufio.NewScanner(os.Stdin)

	// 終了通知用チャネル
	done := make(chan bool)

	// 入力処理用ゴルーチン
	go func() {
		for scanner.Scan() {
			text := scanner.Text()
			client.log("Received input: %s", text)

			// JSONメッセージのパース
			var msg Message
			if err := json.Unmarshal([]byte(text), &msg); err != nil {
				fmt.Fprintf(os.Stderr, "Error parsing message: %v\n", err)
				continue
			}

			// メッセージの処理
			switch msg.Type {
			case "chat":
				var req APIRequest
				data, err := json.Marshal(msg.Content)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error marshaling content: %v\n", err)
					continue
				}

				if err := json.Unmarshal(data, &req); err != nil {
					fmt.Fprintf(os.Stderr, "Error parsing API request: %v\n", err)
					continue
				}

				client.log("Processing chat request: %+v", req)

				stream, err := client.CreateChatCompletion(ctx, req)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error creating chat completion: %v\n", err)
					continue
				}

				for {
					response, err := stream.Recv()
					if err != nil {
						if err == io.EOF {
							break
						}
						fmt.Fprintf(os.Stderr, "Error receiving response: %v\n", err)
						break
					}

					// レスポンスの送信
					if len(response.Choices) > 0 && response.Choices[0].Delta.Content != "" {
						client.log("Sending response: %s", response.Choices[0].Delta.Content)
						if err := sendMessage(Message{
							Type:    "response",
							Content: response.Choices[0].Delta.Content,
						}); err != nil {
							fmt.Fprintf(os.Stderr, "Error sending response: %v\n", err)
						}
					}
				}
				stream.Close()

			case "file":
				var op FileOperation
				data, err := json.Marshal(msg.Content)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error marshaling content: %v\n", err)
					continue
				}

				if err := json.Unmarshal(data, &op); err != nil {
					fmt.Fprintf(os.Stderr, "Error parsing file operation: %v\n", err)
					continue
				}

				client.log("Processing file operation: %+v", op)
				response := handleFileOperation(op)

				if err := sendMessage(Message{
					Type:    "file_response",
					Content: response,
				}); err != nil {
					fmt.Fprintf(os.Stderr, "Error sending file response: %v\n", err)
				}

			case "ping":
				if err := sendMessage(Message{
					Type:    "pong",
					Content: msg.Content,
				}); err != nil {
					fmt.Fprintf(os.Stderr, "Error sending pong: %v\n", err)
				}

			default:
				fmt.Fprintf(os.Stderr, "Unknown message type: %s\n", msg.Type)
			}
		}

		if err := scanner.Err(); err != nil {
			fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
		}
		done <- true
	}()

	// 起動メッセージの送信
	if err := sendMessage(Message{
		Type:    "status",
		Content: "hello-vim-plugin started",
	}); err != nil {
		fmt.Fprintf(os.Stderr, "Error sending startup message: %v\n", err)
	}

	// メインループ
	select {
	case <-sigChan:
		client.log("Received shutdown signal")
		fmt.Fprintf(os.Stderr, "Received shutdown signal\n")
		cancel()
	case <-done:
		client.log("Input stream closed")
		fmt.Fprintf(os.Stderr, "Input stream closed\n")
	}
}
