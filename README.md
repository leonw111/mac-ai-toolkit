# Mac AI Toolkit

> One App, All Mac AI

将 macOS 系统 AI 能力（Vision、Speech、AVFoundation）封装为 GUI 应用 + 本地 API 服务。

## 功能

- **OCR** - 图片文字识别（支持中/英/日/韩等多语言）
- **TTS** - 文字转语音（支持导出 MP3/WAV）
- **STT** - 语音转文字（支持实时录音和文件转写）

## 架构

```
mac-ai-toolkit/
├── App/           # 应用入口 & 状态管理
├── Views/         # SwiftUI 界面（主窗口 + 菜单栏）
├── Services/      # 核心服务（OCR/TTS/STT）
├── Server/        # HTTP API（Vapor, localhost:19527）
├── Models/        # 数据模型
├── Utils/         # 工具类
└── Resources/     # 资源文件
```

## 技术栈

| 组件 | 技术 |
|------|------|
| UI | SwiftUI |
| HTTP Server | Vapor |
| OCR | Vision |
| TTS | AVSpeechSynthesizer |
| STT | SFSpeechRecognizer |

## 开发

```bash
# 1. 打开项目
open mac-ai-toolkit.xcodeproj

# 2. 添加依赖
# File → Add Package Dependencies → https://github.com/vapor/vapor.git

# 3. 编译运行
# ⌘ + R
```

## API

| 端点 | 功能 |
|------|------|
| `GET /health` | 健康检查 |
| `POST /ocr` | 文字识别 |
| `POST /tts` | 文字转语音 |
| `GET /tts/voices` | 可用语音列表 |
| `POST /stt` | 语音转文字 |

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧O` | 截图 OCR |
| `⌘⇧T` | 快速 TTS |
| `⌘⇧S` | 快速 STT |

## 系统要求

- macOS 13.0+
- Xcode 15+

## License

MIT
