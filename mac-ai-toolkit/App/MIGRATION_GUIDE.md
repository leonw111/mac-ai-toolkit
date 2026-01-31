# 项目架构迁移指南

## 📋 概述

本文档指导如何将现有代码迁移到新的项目架构。迁移采用渐进式策略，确保每一步都可测试和回滚。

## 🎯 迁移目标

### 当前架构问题
1. ❌ 视图和业务逻辑混合在一起
2. ❌ 服务直接使用单例，难以测试
3. ❌ 状态管理分散，不统一
4. ❌ 缺少明确的协议定义
5. ❌ 错误处理不完善

### 新架构优势
1. ✅ MVVM 分离关注点
2. ✅ 依赖注入，便于测试
3. ✅ 统一的状态管理
4. ✅ 协议导向设计
5. ✅ 完善的错误处理

## 📝 迁移步骤

### 阶段 1: 创建协议层 (1-2 天)

**目标**: 定义所有服务的协议接口

#### 1.1 创建服务协议文件
```
Core/
└── Services/
    └── Protocol/
        ├── OCRServiceProtocol.swift       ✅ 已创建
        ├── TTSServiceProtocol.swift       ✅ 已创建
        ├── STTServiceProtocol.swift       ⏳ 待创建
        ├── HistoryServiceProtocol.swift   ✅ 已创建
        └── SettingsServiceProtocol.swift  ✅ 已创建
```

#### 1.2 更新现有 Service 实现协议
```swift
// 旧代码
class OCRService {
    static let shared = OCRService()
    
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        // ...
    }
}

// 新代码
actor OCRService: OCRServiceProtocol {
    // 移除 shared 单例
    // static let shared = OCRService()  // 删除这行
    
    func recognizeText(
        from image: NSImage,
        languages: [String]?,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult {
        // ...
    }
}
```

**检查点**: 编译通过，所有服务都实现了对应的协议

---

### 阶段 2: 实现依赖注入 (1 天)

**目标**: 创建 AppEnvironment 统一管理依赖

#### 2.1 创建 AppEnvironment
```swift
// ✅ 已创建 AppEnvironment.swift
```

#### 2.2 在 App 中注入环境
```swift
// MacAIToolkitApp.swift
@main
struct MacAIToolkitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    // ✅ 添加环境
    private let environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(appState)
                .withAppEnvironment(environment)  // ✅ 注入环境
        }
        // ...
    }
}
```

**检查点**: 所有视图可以通过 @Environment 访问服务

---

### 阶段 3: 创建 ViewModel 层 (2-3 天)

**目标**: 将视图逻辑提取到 ViewModel

#### 3.1 为每个功能创建 ViewModel

**TTS 示例**:
```swift
// ✅ 已创建 TTSViewModel.swift

// 使用步骤：
// 1. 将 TTSView 中的 @State 迁移到 ViewModel
// 2. 将业务逻辑迁移到 ViewModel
// 3. View 只保留 UI 代码
```

#### 3.2 重构视图使用 ViewModel

**迁移前**:
```swift
struct TTSView: View {
    @State private var inputText = ""
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            TextEditor(text: $inputText)
            
            Button("播放") {
                // 业务逻辑在这里
                Task {
                    try await TTSService.shared.speak(text: inputText)
                }
            }
        }
    }
}
```

**迁移后**:
```swift
struct TTSView: View {
    @StateObject private var viewModel: TTSViewModel
    
    init(viewModel: TTSViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? TTSViewModel())
    }
    
    var body: some View {
        VStack {
            TextEditor(text: $viewModel.inputText)
            
            Button("播放") {
                Task {
                    await viewModel.playPreview()
                }
            }
        }
    }
}
```

#### 3.3 其他功能的 ViewModel

按优先级顺序创建：

1. **TTSViewModel** ✅ 已创建
2. **OCRViewModel** ⏳ 下一步
   ```swift
   @MainActor
   final class OCRViewModel: ObservableObject {
       @Published var image: NSImage?
       @Published var result: OCRResult?
       @Published var state: ViewState = .idle
       
       private let ocrService: OCRServiceProtocol
       
       init(ocrService: OCRServiceProtocol) {
           self.ocrService = ocrService
       }
       
       func recognizeText() async {
           // ...
       }
   }
   ```

3. **STTViewModel** ⏳ 待创建
4. **HistoryViewModel** ⏳ 待创建
5. **SettingsViewModel** ⏳ 待创建

**检查点**: 每个视图都有对应的 ViewModel，业务逻辑从视图中分离

---

### 阶段 4: 优化状态管理 (1-2 天)

**目标**: 统一和简化状态管理

#### 4.1 定义标准的 ViewState

```swift
// ✅ 已在 TTSViewModel 中定义
enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(Error)
}
```

#### 4.2 重构 AppState

```swift
// 旧代码 - 太多职责
@MainActor
class AppState: ObservableObject {
    @Published var isServerRunning: Bool = false
    @Published var settings: AppSettings
    @Published var historyItems: [HistoryItem] = []
    @Published var todayRequestCount: Int = 0
    // ... 太多属性
}

// 新代码 - 只保留全局状态
@MainActor
class AppState: ObservableObject {
    @Published var isServerRunning: Bool = false
    @Published var todayRequestCount: Int = 0
    
    // 其他状态由各自的 Service 和 ViewModel 管理
}
```

**检查点**: AppState 只包含全局必需的状态

---

### 阶段 5: 完善错误处理 (1 天)

**目标**: 统一的错误处理机制

#### 5.1 为每个模块定义错误类型

```swift
// ✅ OCRError 已在 OCRServiceProtocol.swift 中定义
// ✅ TTSError 已在 TTSServiceProtocol.swift 中定义
// ⏳ 创建 STTError
```

#### 5.2 在 ViewModel 中处理错误

```swift
@MainActor
class OCRViewModel: ObservableObject {
    @Published var error: OCRError?
    
    func recognizeText() async {
        do {
            let result = try await ocrService.recognizeText(from: image!)
            self.result = result
            state = .success
        } catch let ocrError as OCRError {
            error = ocrError
            state = .error(ocrError)
        } catch {
            let ocrError = OCRError.recognitionFailed(underlying: error)
            self.error = ocrError
            state = .error(ocrError)
        }
    }
}
```

#### 5.3 在视图中显示错误

```swift
.alert(isPresented: $showingErrorAlert) {
    Alert(
        title: Text("操作失败"),
        message: Text(viewModel.error?.localizedDescription ?? ""),
        primaryButton: .default(Text("重试")) {
            Task { await viewModel.retry() }
        },
        secondaryButton: .cancel()
    )
}
```

**检查点**: 所有错误都有清晰的描述和恢复建议

---

### 阶段 6: 添加日志系统 (0.5 天)

**目标**: 统一的日志记录

#### 6.1 创建日志扩展

```swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.mac-ai-toolkit"
    
    static let ocr = Logger(subsystem: subsystem, category: "OCR")
    static let tts = Logger(subsystem: subsystem, category: "TTS")
    static let stt = Logger(subsystem: subsystem, category: "STT")
    static let history = Logger(subsystem: subsystem, category: "History")
    static let network = Logger(subsystem: subsystem, category: "Network")
}
```

#### 6.2 在代码中使用

```swift
import OSLog

actor OCRService: OCRServiceProtocol {
    private let logger = Logger.ocr
    
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        logger.info("开始识别图像")
        
        do {
            let result = try await performRecognition(image)
            logger.info("识别完成，识别到 \(result.text.count) 个字符")
            return result
        } catch {
            logger.error("识别失败: \(error.localizedDescription)")
            throw error
        }
    }
}
```

**检查点**: 关键操作都有日志记录

---

### 阶段 7: 编写测试 (持续进行)

**目标**: 核心功能有测试覆盖

#### 7.1 创建测试文件结构

```
Tests/
├── ServiceTests/
│   ├── OCRServiceTests.swift
│   ├── TTSServiceTests.swift
│   └── HistoryServiceTests.swift
├── ViewModelTests/
│   ├── OCRViewModelTests.swift
│   ├── TTSViewModelTests.swift
│   └── HistoryViewModelTests.swift
└── UtilityTests/
    ├── ImageUtilsTests.swift
    └── AudioUtilsTests.swift
```

#### 7.2 编写 Service 测试

```swift
import Testing

@Suite("OCR 服务测试")
struct OCRServiceTests {
    
    @Test("识别简单文本")
    func testRecognizeSimpleText() async throws {
        let service = OCRService()
        let image = try #require(loadTestImage("test.png"))
        
        let result = try await service.recognizeText(
            from: image,
            languages: ["en-US"],
            recognitionLevel: .accurate
        )
        
        #expect(result.text.isNotEmpty)
        #expect(result.confidence > 0)
    }
}
```

#### 7.3 编写 ViewModel 测试

```swift
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

**检查点**: 核心功能测试通过率 > 80%

---

## 🗂️ 文件重组清单

### 需要创建的新文件

#### 协议层
- [x] `OCRServiceProtocol.swift`
- [x] `TTSServiceProtocol.swift`
- [ ] `STTServiceProtocol.swift`
- [x] `HistoryServiceProtocol.swift`
- [x] `SettingsServiceProtocol.swift`

#### ViewModel 层
- [x] `TTSViewModel.swift`
- [ ] `OCRViewModel.swift`
- [ ] `STTViewModel.swift`
- [ ] `HistoryViewModel.swift`
- [ ] `SettingsViewModel.swift`

#### 管理器
- [x] `NotificationManager.swift`
- [ ] `KeyboardShortcutsManager.swift` (需重构)

#### 工具类
- [ ] `Logger+Extensions.swift`
- [ ] `View+Extensions.swift`
- [ ] `String+Extensions.swift`

### 需要重构的现有文件

#### 服务实现
- [ ] `OCRService.swift` - 实现 `OCRServiceProtocol`
- [ ] `TTSService.swift` - 实现 `TTSServiceProtocol`
- [ ] `HistoryService.swift` - 实现 `HistoryServiceProtocol`

#### 视图
- [x] `TTSView.swift` - 使用 `TTSViewModel`
- [ ] `OCRView.swift` - 使用 `OCRViewModel`
- [ ] `STTView.swift` - 使用 `STTViewModel`
- [ ] `HistoryView.swift` - 使用 `HistoryViewModel`
- [ ] `SettingsView.swift` - 使用 `SettingsViewModel`

#### 应用核心
- [ ] `MacAIToolkitApp.swift` - 注入 AppEnvironment
- [ ] `AppDelegate.swift` - 使用新的服务协议
- [ ] `AppState.swift` - 简化职责

---

## ⚠️ 注意事项

### 破坏性变更

1. **服务单例移除**
   ```swift
   // 旧代码
   TTSService.shared.speak(text: "Hello")
   
   // 新代码
   let service = environment.ttsService
   await service.speak(text: "Hello", configuration: .default)
   ```

2. **方法签名变更**
   ```swift
   // 旧
   func speak(text: String, voiceIdentifier: String?, rate: Float)
   
   // 新
   func speak(text: String, configuration: TTSConfiguration)
   ```

### 兼容性处理

如果需要保持向后兼容，可以这样做：

```swift
extension TTSService {
    // 提供旧的 API，内部调用新 API
    @available(*, deprecated, message: "使用 speak(text:configuration:) 代替")
    func speak(
        text: String,
        voiceIdentifier: String? = nil,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 0.8
    ) async throws {
        let config = TTSConfiguration(
            voiceIdentifier: voiceIdentifier,
            rate: rate,
            pitch: pitch,
            volume: volume
        )
        try await speak(text: text, configuration: config)
    }
}
```

---

## 📊 进度跟踪

### 整体进度

- [x] 阶段 1: 创建协议层 (80% - 缺 STT)
- [x] 阶段 2: 实现依赖注入 (100%)
- [x] 阶段 3: 创建 ViewModel 层 (20% - 仅 TTS 完成)
- [ ] 阶段 4: 优化状态管理 (0%)
- [ ] 阶段 5: 完善错误处理 (40% - OCR, TTS 完成)
- [ ] 阶段 6: 添加日志系统 (30% - TTS 完成)
- [ ] 阶段 7: 编写测试 (0%)

### 按功能模块

| 模块 | 协议 | ViewModel | 视图重构 | 测试 | 完成度 |
|------|------|-----------|---------|------|--------|
| TTS  | ✅   | ✅        | ✅      | ⏳   | 80%    |
| OCR  | ✅   | ⏳        | ⏳      | ⏳   | 30%    |
| STT  | ⏳   | ⏳        | ⏳      | ⏳   | 10%    |
| History | ✅ | ⏳      | ⏳      | ⏳   | 20%    |
| Settings | ✅ | ⏳     | ⏳      | ⏳   | 20%    |

---

## 🚀 下一步行动

### 立即行动 (本周)
1. ✅ 创建 `TTSViewModel` 并重构 `TTSView`
2. ⏳ 创建 `STTServiceProtocol`
3. ⏳ 创建 `OCRViewModel` 并重构 `OCRView`

### 短期目标 (2 周内)
1. 完成所有 ViewModel 的创建
2. 完成所有视图的重构
3. 添加日志系统

### 长期目标 (1 个月内)
1. 测试覆盖率达到 70%
2. 完善文档和注释
3. 性能优化

---

## 📚 参考资料

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 完整架构文档
- [CODING_STYLE.md](./CODING_STYLE.md) - 编码规范
- [Apple Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI Best Practices](https://developer.apple.com/tutorials/swiftui)

---

**版本**: 1.0  
**最后更新**: 2026-01-31  
**维护者**: 开发团队
