# Mac AI Toolkit 项目架构文档

## 📁 项目结构

```
mac-ai-toolkit/
├── App/
│   ├── MacAIToolkitApp.swift          # 应用入口
│   ├── AppDelegate.swift              # 应用生命周期
│   └── AppEnvironment.swift           # 依赖注入容器
│
├── Core/
│   ├── Models/                        # 数据模型
│   │   ├── Domain/                    # 业务领域模型
│   │   │   ├── OCRResult.swift
│   │   │   ├── TTSConfiguration.swift
│   │   │   ├── STTConfiguration.swift
│   │   │   └── HistoryItem.swift
│   │   └── Settings/                  # 设置相关模型
│   │       ├── AppSettings.swift
│   │       └── KeyboardShortcut.swift
│   │
│   ├── Services/                      # 业务服务层
│   │   ├── Protocol/                  # 服务协议定义
│   │   │   ├── OCRServiceProtocol.swift
│   │   │   ├── TTSServiceProtocol.swift
│   │   │   ├── STTServiceProtocol.swift
│   │   │   └── HistoryServiceProtocol.swift
│   │   ├── Implementation/            # 服务实现
│   │   │   ├── OCRService.swift
│   │   │   ├── TTSService.swift
│   │   │   ├── STTService.swift
│   │   │   ├── HistoryService.swift
│   │   │   └── SettingsService.swift
│   │   └── API/                       # HTTP API 服务
│   │       ├── HTTPServer.swift
│   │       └── APIRouter.swift
│   │
│   ├── Managers/                      # 系统管理器
│   │   ├── KeyboardShortcutsManager.swift
│   │   ├── NotificationManager.swift
│   │   └── FileManager+Extension.swift
│   │
│   └── State/                         # 全局状态管理
│       ├── AppState.swift             # 主应用状态
│       └── ViewStates/                # 视图状态
│           ├── OCRViewState.swift
│           ├── TTSViewState.swift
│           └── STTViewState.swift
│
├── Features/                          # 功能模块
│   ├── OCR/
│   │   ├── Views/
│   │   │   ├── OCRView.swift
│   │   │   └── OCRResultView.swift
│   │   └── ViewModels/
│   │       └── OCRViewModel.swift
│   │
│   ├── TTS/
│   │   ├── Views/
│   │   │   ├── TTSView.swift
│   │   │   └── VoicePickerView.swift
│   │   └── ViewModels/
│   │       └── TTSViewModel.swift
│   │
│   ├── STT/
│   │   ├── Views/
│   │   │   ├── STTView.swift
│   │   │   └── AudioWaveformView.swift
│   │   └── ViewModels/
│   │       └── STTViewModel.swift
│   │
│   ├── History/
│   │   ├── Views/
│   │   │   ├── HistoryView.swift
│   │   │   └── HistoryItemRow.swift
│   │   └── ViewModels/
│   │       └── HistoryViewModel.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   ├── GeneralSettingsView.swift
│       │   ├── APISettingsView.swift
│       │   └── ShortcutsSettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── UI/                                # 通用 UI 组件
│   ├── Components/                    # 可复用组件
│   │   ├── LoadingView.swift
│   │   ├── EmptyStateView.swift
│   │   ├── ErrorView.swift
│   │   └── ProgressIndicator.swift
│   │
│   ├── Navigation/                    # 导航相关
│   │   ├── MainView.swift
│   │   ├── SidebarView.swift
│   │   └── MenuBarView.swift
│   │
│   ├── Styles/                        # 样式定义
│   │   ├── ButtonStyles.swift
│   │   ├── TextFieldStyles.swift
│   │   └── Colors.swift
│   │
│   └── Modifiers/                     # 自定义 ViewModifiers
│       ├── KeyboardShortcutModifier.swift
│       └── ErrorAlertModifier.swift
│
├── Utilities/                         # 工具类
│   ├── Extensions/                    # 扩展
│   │   ├── String+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   ├── Image+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Helpers/                       # 辅助工具
│   │   ├── ImageUtils.swift
│   │   ├── AudioUtils.swift
│   │   ├── FileUtils.swift
│   │   └── ValidationUtils.swift
│   │
│   └── Constants/                     # 常量定义
│       ├── AppConstants.swift
│       └── NotificationNames.swift
│
└── Resources/                         # 资源文件
    ├── Localizations/                 # 多语言
    │   ├── en.lproj/
    │   └── zh-Hans.lproj/
    ├── Assets.xcassets/              # 图片资源
    └── Info.plist                     # 应用配置
```

## 🏗️ 架构原则

### 1. **分层架构 (Layered Architecture)**

```
┌─────────────────────────────────────┐
│         Presentation Layer          │  SwiftUI Views & ViewModels
├─────────────────────────────────────┤
│         Application Layer           │  AppState, Coordinators
├─────────────────────────────────────┤
│          Service Layer              │  Business Logic Services
├─────────────────────────────────────┤
│          Domain Layer               │  Models & Protocols
└─────────────────────────────────────┘
```

### 2. **MVVM 模式**

- **Model**: 纯数据模型，不包含业务逻辑
- **View**: SwiftUI 视图，尽量保持简洁
- **ViewModel**: 视图逻辑和状态管理，连接 View 和 Service

### 3. **依赖注入**

使用协议和环境对象实现依赖注入，便于测试和替换实现：

```swift
// 协议定义
protocol OCRServiceProtocol {
    func recognizeText(from image: NSImage) async throws -> OCRResult
}

// 使用环境注入
struct OCRView: View {
    @EnvironmentObject var viewModel: OCRViewModel
    
    var body: some View {
        // ...
    }
}
```

### 4. **单一职责原则**

每个类/结构体只负责一个明确的功能：

- Service 只处理业务逻辑
- ViewModel 只处理视图状态
- Manager 只处理系统级别的功能
- Utils 只提供纯函数工具

### 5. **Swift Concurrency**

全面采用 async/await 和 Actor 模式：

```swift
actor OCRService: OCRServiceProtocol {
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        // 线程安全的实现
    }
}
```

## 📋 编码规范

### 命名规范

- **文件名**: PascalCase (如 `OCRService.swift`)
- **类型名**: PascalCase (如 `class OCRService`)
- **变量/函数**: camelCase (如 `func recognizeText()`)
- **协议**: 以 Protocol 结尾 (如 `OCRServiceProtocol`)
- **常量**: camelCase 或全大写 (如 `apiEndpoint` 或 `API_ENDPOINT`)

### 代码组织

每个文件使用 MARK 分隔：

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Protocol Conformance
```

### 错误处理

定义清晰的错误类型：

```swift
enum OCRError: LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图像处理失败"
        case .noTextFound:
            return "未识别到文字"
        case .serviceUnavailable:
            return "服务不可用"
        }
    }
}
```

### 并发规范

- UI 更新必须在 MainActor
- 使用 @MainActor 标记需要主线程的类
- 长时间任务使用 Task
- 避免使用 DispatchQueue，优先使用 async/await

## 🔄 数据流

### 单向数据流

```
User Action → ViewModel → Service → Model Update → View Update
    ↑                                                    ↓
    └────────────────────────────────────────────────────┘
```

### 示例流程 (OCR)

1. 用户点击 "识别文字" 按钮
2. OCRView 调用 `viewModel.recognizeText()`
3. ViewModel 更新状态为 loading
4. ViewModel 调用 `ocrService.recognizeText()`
5. Service 执行 OCR 识别
6. Service 返回结果
7. ViewModel 更新状态和结果
8. View 自动刷新显示结果

## 🧪 测试策略

### 单元测试

- 测试所有 Service 层逻辑
- 测试所有 ViewModel 状态转换
- 测试工具函数

### 集成测试

- 测试 Service 与系统 API 集成
- 测试完整的用户流程

### UI 测试

- 测试关键用户交互流程
- 使用 Swift Testing 框架

## 📦 模块依赖关系

```
Features → ViewModels → Services → Models
    ↓          ↓            ↓         ↓
   UI    →  State    →  Managers → Utilities
```

**规则**:
- 上层可以依赖下层，下层不能依赖上层
- 同层之间尽量避免直接依赖
- 通过协议解耦具体实现

## 🚀 最佳实践

### 1. 使用 @Published 管理状态

```swift
@MainActor
class OCRViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var result: OCRResult?
    @Published var error: Error?
}
```

### 2. 使用 Combine 处理复杂状态

```swift
cancellable = $inputText
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] text in
        self?.validateInput(text)
    }
```

### 3. 使用 Environment 注入依赖

```swift
struct OCRView: View {
    @EnvironmentObject var viewModel: OCRViewModel
    @Environment(\.colorScheme) var colorScheme
}
```

### 4. 视图拆分原则

- 超过 100 行的视图应该拆分
- 提取可复用的子视图
- 使用 @ViewBuilder 构建复杂布局

### 5. 性能优化

- 避免在 body 中进行复杂计算
- 使用 `@State` 和 `@Binding` 优化刷新范围
- 大列表使用 `LazyVStack`/`LazyHStack`
- 图片使用异步加载

## 📝 文档规范

### 代码注释

```swift
/// OCR 识别服务
///
/// 提供图像文字识别功能，支持多语言识别
actor OCRService: OCRServiceProtocol {
    
    /// 识别图像中的文字
    ///
    /// - Parameter image: 要识别的图像
    /// - Returns: OCR 识别结果
    /// - Throws: OCRError 如果识别失败
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        // ...
    }
}
```

### 文件头注释

```swift
//
//  OCRService.swift
//  mac-ai-toolkit
//
//  OCR text recognition service
//  Created on 2026-01-31
//
```

## 🔐 安全规范

- API Key 不得硬编码，使用 Keychain 存储
- 用户输入需要验证和清理
- 文件操作需要权限检查
- 网络请求需要 HTTPS

## 🌍 国际化

- 所有用户可见文本使用 `LocalizedStringKey`
- 字符串定义在 `.strings` 文件中
- 日期、数字使用系统格式化器

## 📊 日志规范

使用统一的日志系统：

```swift
import OSLog

extension Logger {
    static let ocr = Logger(subsystem: "com.app.mac-ai-toolkit", category: "OCR")
    static let tts = Logger(subsystem: "com.app.mac-ai-toolkit", category: "TTS")
}

// 使用
Logger.ocr.info("开始识别文字")
Logger.ocr.error("识别失败: \(error)")
```

## 🔄 版本控制

- 使用语义化版本 (Semantic Versioning)
- 每个功能使用独立分支开发
- 合并前必须通过代码审查
- 保持清晰的 commit message

---

**最后更新**: 2026-01-31
**维护者**: 开发团队
