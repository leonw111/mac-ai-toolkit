# Mac AI Toolkit - 项目架构文档

## 📋 目录

1. [架构概览](#架构概览)
2. [项目结构](#项目结构)
3. [设计模式](#设计模式)
4. [编码规范](#编码规范)
5. [最佳实践](#最佳实践)
6. [测试策略](#测试策略)

---

## 🏗️ 架构概览

本项目采用 **MVVM + Clean Architecture** 模式，确保代码的可维护性、可测试性和可扩展性。

### 核心原则

- ✅ **关注点分离**：UI、业务逻辑、数据层完全分离
- ✅ **依赖注入**：所有服务通过协议注入，便于测试和替换
- ✅ **单一职责**：每个类/结构体只负责一个功能
- ✅ **开闭原则**：对扩展开放，对修改关闭
- ✅ **Swift Concurrency**：全面使用 async/await，避免回调地狱

---

## 📁 项目结构

```
mac-ai-toolkit/
├── App/
│   ├── AppDelegate.swift
│   └── AppState.swift              # 全局应用状态
│
├── Features/                        # 功能模块
│   ├── TTS/                        # 文字转语音
│   │   ├── Views/
│   │   │   ├── TTSView.swift       # 主视图（纯 UI）
│   │   │   ├── TTSTextInputSection.swift
│   │   │   ├── TTSVoiceSection.swift
│   │   │   ├── TTSParametersSection.swift
│   │   │   └── TTSActionsSection.swift
│   │   ├── ViewModels/
│   │   │   └── TTSViewModel.swift  # 视图模型（业务逻辑）
│   │   ├── Models/
│   │   │   └── TTSModels.swift     # 数据模型
│   │   └── Services/
│   │       └── TTSService.swift    # TTS 核心服务
│   │
│   ├── STT/                        # 语音转文字
│   └── OCR/                        # 图像识别
│
├── Core/                            # 核心功能
│   ├── Services/
│   │   ├── SettingsService.swift   # 设置管理
│   │   ├── HistoryService.swift    # 历史记录
│   │   └── HTTPServer.swift        # API 服务器
│   ├── Utilities/
│   │   ├── AudioUtils.swift
│   │   └── FileManager+Extensions.swift
│   └── Protocols/
│       ├── TTSServiceProtocol.swift
│       ├── SettingsServiceProtocol.swift
│       └── HistoryServiceProtocol.swift
│
├── Shared/                          # 共享组件
│   ├── Models/
│   │   └── HistoryModels.swift
│   └── Views/
│       └── CommonComponents.swift
│
└── Tests/                           # 测试
    ├── TTSViewModelTests.swift
    ├── TTSServiceTests.swift
    └── SettingsServiceTests.swift
```

---

## 🎯 设计模式

### 1. MVVM (Model-View-ViewModel)

#### View（视图层）
- **职责**：纯 UI 渲染，不包含业务逻辑
- **特点**：
  - 使用 SwiftUI 声明式语法
  - 通过 `@StateObject` 持有 ViewModel
  - 通过 `@Binding` 接收子视图参数
  - 视图组件化，每个 Section 独立

```swift
struct TTSView: View {
    @StateObject private var viewModel = TTSViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                TTSTextInputSection(...)
                TTSVoiceSection(...)
                TTSParametersSection(...)
                TTSActionsSection(...)
            }
        }
    }
}
```

#### ViewModel（视图模型层）
- **职责**：处理业务逻辑、状态管理、与服务层交互
- **特点**：
  - 使用 `@MainActor` 确保线程安全
  - 继承 `ObservableObject`
  - 通过 `@Published` 发布状态变化
  - 依赖注入服务

```swift
@MainActor
final class TTSViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isPlaying: Bool = false
    
    private let ttsService: TTSServiceProtocol
    
    init(ttsService: TTSServiceProtocol = TTSService.shared) {
        self.ttsService = ttsService
    }
    
    func playPreview() {
        // 业务逻辑
    }
}
```

#### Model（模型层）
- **职责**：数据结构定义
- **特点**：
  - 遵循 `Codable` 便于序列化
  - 遵循 `Identifiable` 便于列表展示
  - 不包含业务逻辑

```swift
struct TTSSettings: Codable {
    let voiceIdentifier: String?
    let rate: Float
    let pitch: Float
    let volume: Float
}
```

### 2. Protocol-Oriented Programming（面向协议编程）

所有服务都定义协议，便于测试和替换实现：

```swift
protocol TTSServiceProtocol {
    func speak(text: String, ...) async throws
    func stop() async
}

// 生产环境
extension TTSService: TTSServiceProtocol {}

// 测试环境
class MockTTSService: TTSServiceProtocol {
    func speak(...) async throws {
        // Mock 实现
    }
}
```

### 3. Dependency Injection（依赖注入）

通过构造函数注入依赖，默认使用单例：

```swift
init(
    ttsService: TTSServiceProtocol = TTSService.shared,
    settingsService: SettingsServiceProtocol = SettingsService.shared,
    historyService: HistoryServiceProtocol = HistoryService.shared
) {
    self.ttsService = ttsService
    self.settingsService = settingsService
    self.historyService = historyService
}
```

### 4. Service Layer（服务层）

每个功能模块都有对应的服务：

- **TTSService**：TTS 核心功能
- **SettingsService**：设置持久化
- **HistoryService**：历史记录管理
- **HTTPServer**：API 服务

---

## 📝 编码规范

### Swift 代码风格

1. **命名规范**
   ```swift
   // 类型：大驼峰
   class TTSViewModel { }
   struct TTSSettings { }
   
   // 变量/函数：小驼峰
   var inputText: String
   func playPreview() { }
   
   // 常量：小驼峰
   let maxRetryCount = 3
   
   // 私有属性：下划线前缀（可选）
   private let ttsService: TTSServiceProtocol
   ```

2. **文件组织**
   ```swift
   // 文件头部注释
   //
   //  TTSViewModel.swift
   //  mac-ai-toolkit
   //
   //  ViewModel for TTS functionality
   //
   
   import Foundation
   import Combine
   
   // MARK: - Main Class
   
   @MainActor
   final class TTSViewModel: ObservableObject {
       
       // MARK: - Published Properties
       
       @Published var inputText: String = ""
       
       // MARK: - Private Properties
       
       private let ttsService: TTSServiceProtocol
       
       // MARK: - Initialization
       
       init(...) { }
       
       // MARK: - Public Methods
       
       func playPreview() { }
       
       // MARK: - Private Methods
       
       private func handleError(_ error: Error) { }
   }
   
   // MARK: - Supporting Types
   
   struct TTSSettings { }
   ```

3. **注释规范**
   ```swift
   /// 播放 TTS 预览
   ///
   /// - Parameters:
   ///   - text: 要转换的文本
   ///   - voice: 语音标识符（可选）
   /// - Throws: TTSError 如果合成失败
   func playPreview(text: String, voice: String?) async throws {
       // 实现
   }
   ```

### SwiftUI 组件规范

1. **组件拆分**：单个视图不超过 200 行，复杂视图拆分为多个 Section
2. **状态管理**：
   - `@State`：视图内部状态
   - `@StateObject`：视图拥有的对象
   - `@ObservedObject`：外部传入的对象
   - `@EnvironmentObject`：全局共享对象
   - `@Binding`：双向绑定

3. **性能优化**：
   - 使用 `Equatable` 减少不必要的刷新
   - 大列表使用 `LazyVStack`/`LazyHStack`
   - 图片使用异步加载

---

## 🎓 最佳实践

### 1. 错误处理

```swift
// ✅ 定义自定义错误
enum TTSError: LocalizedError {
    case synthesizeFailed(String)
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .synthesizeFailed(let message):
            return "合成失败: \(message)"
        case .exportFailed(let message):
            return "导出失败: \(message)"
        }
    }
}

// ✅ 在 ViewModel 中统一处理
private func handleError(_ error: Error) {
    if let ttsError = error as? TTSError {
        errorMessage = ttsError.localizedDescription
    } else {
        errorMessage = "未知错误: \(error.localizedDescription)"
    }
    showError = true
}
```

### 2. 异步操作

```swift
// ✅ 使用 async/await
func playPreview() {
    Task {
        do {
            try await ttsService.speak(text: inputText)
        } catch {
            handleError(error)
        }
    }
}

// ❌ 避免使用回调
func playPreview(completion: @escaping (Result<Void, Error>) -> Void) {
    // 不推荐
}
```

### 3. 状态管理

```swift
// ✅ 计算属性
var canPerformAction: Bool {
    !inputText.isEmpty && !isExporting
}

// ✅ 使用 Combine 监听变化
$rate
    .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
    .sink { [weak self] rate in
        self?.saveSettings(rate: rate)
    }
    .store(in: &cancellables)
```

### 4. 资源管理

```swift
// ✅ 使用 defer 确保清理
func processAudio() {
    let audioEngine = AVAudioEngine()
    defer {
        audioEngine.stop()
    }
    
    // 处理音频
}

// ✅ 取消长时间任务
private var playbackTask: Task<Void, Never>?

func stopPlayback() {
    playbackTask?.cancel()
    playbackTask = nil
}
```

---

## 🧪 测试策略

### 1. 单元测试

使用 Swift Testing 框架：

```swift
@Suite("TTSViewModel Tests")
@MainActor
struct TTSViewModelTests {
    
    @Test("Play preview calls TTS service")
    func testPlayPreview() async throws {
        let mockService = MockTTSService()
        let viewModel = TTSViewModel(ttsService: mockService)
        
        viewModel.inputText = "Test"
        viewModel.playPreview()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(mockService.speakCalled)
        #expect(!viewModel.isPlaying)
    }
}
```

### 2. Mock 对象

```swift
@MainActor
final class MockTTSService: TTSServiceProtocol {
    var speakCalled = false
    var shouldThrowError = false
    
    func speak(...) async throws {
        speakCalled = true
        if shouldThrowError {
            throw TTSError.synthesizeFailed("Mock error")
        }
    }
}
```

### 3. 测试覆盖率目标

- **ViewModel**: 90%+
- **Service**: 85%+
- **Utility**: 80%+
- **View**: 手动测试 + UI 测试

---

## 🚀 开发工作流

### 1. 新增功能流程

1. **定义协议**
   ```swift
   protocol NewServiceProtocol {
       func performAction() async throws
   }
   ```

2. **创建 Model**
   ```swift
   struct NewModel: Codable, Identifiable {
       let id: UUID
       let data: String
   }
   ```

3. **实现 Service**
   ```swift
   actor NewService: NewServiceProtocol {
       static let shared = NewService()
       // 实现
   }
   ```

4. **创建 ViewModel**
   ```swift
   @MainActor
   final class NewViewModel: ObservableObject {
       private let service: NewServiceProtocol
       // 业务逻辑
   }
   ```

5. **构建 View**
   ```swift
   struct NewView: View {
       @StateObject private var viewModel = NewViewModel()
       // UI
   }
   ```

6. **编写测试**
   ```swift
   @Suite("NewViewModel Tests")
   struct NewViewModelTests {
       @Test func testFeature() { }
   }
   ```

### 2. 代码审查清单

- [ ] 是否遵循 MVVM 模式？
- [ ] 是否使用依赖注入？
- [ ] 是否包含单元测试？
- [ ] 是否处理所有错误情况？
- [ ] 是否使用 async/await？
- [ ] 是否添加必要注释？
- [ ] 是否遵循命名规范？
- [ ] 是否避免强制解包？

---

## 📚 参考资源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Testing](https://developer.apple.com/documentation/testing)

---

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add amazing feature'`
4. 推送到分支：`git push origin feature/amazing-feature`
5. 创建 Pull Request

---

**最后更新**：2026-01-31
**维护者**：Mac AI Toolkit Team
