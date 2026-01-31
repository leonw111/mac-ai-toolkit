# Mac AI Toolkit - 项目架构指南

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📖 项目简介

Mac AI Toolkit 是一个集成了 OCR（文字识别）、TTS（文字转语音）、STT（语音转文字）功能的 macOS 应用。本项目采用现代化的 Swift 开发实践，使用 MVVM 架构模式，确保代码的可维护性和可测试性。

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                 │
│            SwiftUI Views + ViewModels               │
├─────────────────────────────────────────────────────┤
│                 Application Layer                   │
│         AppState + AppEnvironment + Managers        │
├─────────────────────────────────────────────────────┤
│                   Service Layer                     │
│   OCR Service │ TTS Service │ STT Service │ ...    │
├─────────────────────────────────────────────────────┤
│                    Domain Layer                     │
│        Models + Protocols + Business Logic          │
└─────────────────────────────────────────────────────┘
```

### 核心设计原则

1. **MVVM 模式**: 视图、视图模型和模型的清晰分离
2. **协议导向**: 面向接口编程，便于测试和扩展
3. **依赖注入**: 通过 `AppEnvironment` 统一管理依赖
4. **Swift Concurrency**: 全面使用 async/await 和 Actor
5. **单向数据流**: 可预测的状态管理

## 📁 项目结构

```
mac-ai-toolkit/
├── App/                          # 应用入口
│   ├── MacAIToolkitApp.swift
│   ├── AppDelegate.swift
│   └── AppEnvironment.swift      # 依赖注入容器
│
├── Core/                         # 核心层
│   ├── Models/                   # 数据模型
│   │   ├── Domain/               # 业务模型
│   │   └── Settings/             # 设置模型
│   │
│   ├── Services/                 # 服务层
│   │   ├── Protocol/             # 服务协议
│   │   │   ├── OCRServiceProtocol.swift
│   │   │   ├── TTSServiceProtocol.swift
│   │   │   ├── STTServiceProtocol.swift
│   │   │   ├── HistoryServiceProtocol.swift
│   │   │   └── SettingsServiceProtocol.swift
│   │   ├── Implementation/       # 服务实现
│   │   └── API/                  # HTTP API
│   │
│   ├── Managers/                 # 系统管理器
│   │   ├── KeyboardShortcutsManager.swift
│   │   └── NotificationManager.swift
│   │
│   └── State/                    # 全局状态
│       ├── AppState.swift
│       └── ViewStates/           # 视图状态
│
├── Features/                     # 功能模块
│   ├── OCR/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── TTS/
│   │   ├── Views/
│   │   │   └── TTSView.swift
│   │   └── ViewModels/
│   │       └── TTSViewModel.swift
│   ├── STT/
│   ├── History/
│   └── Settings/
│
├── UI/                           # 通用 UI
│   ├── Components/               # 可复用组件
│   ├── Navigation/               # 导航
│   ├── Styles/                   # 样式
│   └── Modifiers/                # ViewModifiers
│
├── Utilities/                    # 工具类
│   ├── Extensions/
│   ├── Helpers/
│   └── Constants/
│
└── Resources/                    # 资源
    ├── Localizations/
    └── Assets.xcassets/
```

## 🚀 快速开始

### 环境要求

- macOS 14.0+
- Xcode 16.0+
- Swift 6.0+

### 构建和运行

```bash
# 克隆项目
git clone https://github.com/yourname/mac-ai-toolkit.git

# 打开 Xcode 项目
cd mac-ai-toolkit
open mac-ai-toolkit.xcodeproj

# 在 Xcode 中按 Cmd+R 运行
```

## 📚 核心概念

### 1. 服务协议 (Service Protocol)

所有服务都通过协议定义接口，便于测试和替换实现：

```swift
protocol TTSServiceProtocol: Actor {
    func speak(text: String, configuration: TTSConfiguration) async throws
    func stop()
    var isPlaying: Bool { get async }
}
```

### 2. ViewModel

ViewModel 负责视图逻辑和状态管理：

```swift
@MainActor
final class TTSViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var state: ViewState = .idle
    
    private let ttsService: TTSServiceProtocol
    
    func playPreview() async {
        state = .loading
        do {
            try await ttsService.speak(text: inputText, configuration: configuration)
            state = .success
        } catch {
            state = .error(error)
        }
    }
}
```

### 3. 依赖注入

通过 `AppEnvironment` 统一管理服务实例：

```swift
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()
    
    let ocrService: OCRServiceProtocol
    let ttsService: TTSServiceProtocol
    let historyService: HistoryServiceProtocol
    // ...
}

// 在视图中使用
struct TTSView: View {
    @Environment(\.appEnvironment) var environment
    @StateObject private var viewModel: TTSViewModel
    
    init() {
        let env = AppEnvironment.shared
        _viewModel = StateObject(wrappedValue: TTSViewModel(
            ttsService: env.ttsService,
            historyService: env.historyService,
            settingsService: env.settingsService
        ))
    }
}
```

### 4. 错误处理

每个模块都有明确的错误类型：

```swift
enum TTSError: LocalizedError {
    case invalidText
    case voiceNotFound
    case synthesizeFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidText:
            return "无效的文本内容"
        case .voiceNotFound:
            return "未找到指定的语音"
        case .synthesizeFailed(let error):
            return "合成失败: \(error.localizedDescription)"
        }
    }
}
```

### 5. 并发安全

使用 Actor 保护共享状态：

```swift
actor TTSService: TTSServiceProtocol {
    private var synthesizer: AVSpeechSynthesizer?
    private var isCurrentlyPlaying = false
    
    func speak(text: String, configuration: TTSConfiguration) async throws {
        // 自动线程安全
        isCurrentlyPlaying = true
        // ...
    }
}
```

## 🧪 测试

项目使用 Swift Testing 框架：

```swift
import Testing

@Suite("TTS ViewModel 测试")
struct TTSViewModelTests {
    
    @Test("输入文本后可以播放")
    @MainActor
    func testCanSpeakAfterInput() {
        let viewModel = TTSViewModel()
        
        #expect(!viewModel.canSpeak)
        
        viewModel.inputText = "Hello"
        
        #expect(viewModel.canSpeak)
    }
}
```

运行测试：
```bash
# 在 Xcode 中按 Cmd+U
# 或使用命令行
xcodebuild test -scheme mac-ai-toolkit
```

## 📖 文档

- [完整架构文档](ARCHITECTURE.md) - 详细的架构设计说明
- [编码规范](CODING_STYLE.md) - Swift 编码规范和最佳实践
- [迁移指南](MIGRATION_GUIDE.md) - 从旧架构迁移到新架构的步骤

## 🔄 开发工作流

### 添加新功能

1. **定义协议**
   ```swift
   // Protocol/NewServiceProtocol.swift
   protocol NewServiceProtocol: Actor {
       func doSomething() async throws -> Result
   }
   ```

2. **实现服务**
   ```swift
   // Implementation/NewService.swift
   actor NewService: NewServiceProtocol {
       func doSomething() async throws -> Result {
           // 实现逻辑
       }
   }
   ```

3. **创建 ViewModel**
   ```swift
   // ViewModels/NewViewModel.swift
   @MainActor
   final class NewViewModel: ObservableObject {
       private let service: NewServiceProtocol
       
       init(service: NewServiceProtocol) {
           self.service = service
       }
   }
   ```

4. **创建视图**
   ```swift
   // Views/NewView.swift
   struct NewView: View {
       @StateObject private var viewModel: NewViewModel
       
       var body: some View {
           // UI 代码
       }
   }
   ```

5. **编写测试**
   ```swift
   // Tests/NewViewModelTests.swift
   @Suite("New ViewModel 测试")
   struct NewViewModelTests {
       @Test func testFeature() async {
           // 测试代码
       }
   }
   ```

### 代码审查检查清单

- [ ] 遵循 MVVM 模式
- [ ] 使用协议定义服务接口
- [ ] 通过依赖注入传递服务
- [ ] 正确使用 @MainActor
- [ ] 完善的错误处理
- [ ] 添加日志记录
- [ ] 编写单元测试
- [ ] 更新文档

## 🎨 编码规范

### 命名约定

```swift
// 类型名: PascalCase
class OCRService { }
struct TTSConfiguration { }
enum ViewState { }

// 变量和函数: camelCase
var inputText: String
func recognizeText(from image: NSImage)

// 协议: PascalCase + Protocol 后缀
protocol OCRServiceProtocol { }
```

### 代码组织

```swift
class MyClass {
    
    // MARK: - Properties
    
    private let service: ServiceProtocol
    
    // MARK: - Initialization
    
    init(service: ServiceProtocol) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func publicMethod() {
        // ...
    }
    
    // MARK: - Private Methods
    
    private func privateMethod() {
        // ...
    }
}

// MARK: - Protocol Conformance

extension MyClass: SomeProtocol {
    // ...
}
```

## 🔍 性能优化

- 使用 `LazyVStack` 处理大列表
- 图片异步加载
- 避免在 `body` 中执行复杂计算
- 使用 `.task` 启动异步任务
- Actor 保护共享状态

## 🐛 调试技巧

### 使用统一日志系统

```swift
import OSLog

extension Logger {
    static let tts = Logger(subsystem: "com.app.mac-ai-toolkit", category: "TTS")
}

// 使用
Logger.tts.info("开始播放")
Logger.tts.error("播放失败: \(error)")
```

### 在 Console.app 中查看日志

1. 打开 Console.app
2. 搜索 `subsystem:com.app.mac-ai-toolkit`
3. 查看实时日志

## 📝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👥 团队

- **架构设计**: 开发团队
- **维护者**: 开发团队

## 📞 联系方式

- 项目主页: [GitHub](https://github.com/yourname/mac-ai-toolkit)
- 问题反馈: [Issues](https://github.com/yourname/mac-ai-toolkit/issues)

---

**最后更新**: 2026-01-31
