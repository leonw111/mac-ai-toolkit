# 快速参考卡片 - Mac AI Toolkit

## 📦 项目架构速查

### 核心分层
```
Views → ViewModels → Services → Models
  ↓         ↓           ↓         ↓
 UI    →  State   →  Protocol → Domain
```

### 文件放置规则

| 文件类型 | 放置位置 | 示例 |
|---------|---------|------|
| 服务协议 | `Core/Services/Protocol/` | `OCRServiceProtocol.swift` |
| 服务实现 | `Core/Services/Implementation/` | `OCRService.swift` |
| ViewModel | `Features/{Module}/ViewModels/` | `TTSViewModel.swift` |
| View | `Features/{Module}/Views/` | `TTSView.swift` |
| 模型 | `Core/Models/Domain/` | `OCRResult.swift` |
| 工具类 | `Utilities/Helpers/` | `ImageUtils.swift` |
| 扩展 | `Utilities/Extensions/` | `String+Extensions.swift` |

---

## 🎯 常见任务速查

### 创建新功能模块

```swift
// 1. 定义协议 (Core/Services/Protocol/XxxServiceProtocol.swift)
protocol XxxServiceProtocol: Actor {
    func doSomething() async throws -> Result
}

// 2. 实现服务 (Core/Services/Implementation/XxxService.swift)
actor XxxService: XxxServiceProtocol {
    func doSomething() async throws -> Result {
        // 实现
    }
}

// 3. 添加到 AppEnvironment
final class AppEnvironment {
    let xxxService: XxxServiceProtocol
    
    private init() {
        self.xxxService = XxxService()
    }
}

// 4. 创建 ViewModel (Features/Xxx/ViewModels/XxxViewModel.swift)
@MainActor
final class XxxViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    
    private let service: XxxServiceProtocol
    
    init(service: XxxServiceProtocol) {
        self.service = service
    }
    
    func performAction() async {
        state = .loading
        do {
            let result = try await service.doSomething()
            state = .success
        } catch {
            state = .error(error)
        }
    }
}

// 5. 创建视图 (Features/Xxx/Views/XxxView.swift)
struct XxxView: View {
    @StateObject private var viewModel: XxxViewModel
    
    init(viewModel: XxxViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? XxxViewModel(
            service: AppEnvironment.shared.xxxService
        ))
    }
    
    var body: some View {
        VStack {
            Button("执行") {
                Task {
                    await viewModel.performAction()
                }
            }
        }
    }
}
```

---

## 🔧 代码模板

### ViewModel 模板

```swift
import Foundation
import SwiftUI
import OSLog

/// Xxx 视图模型
@MainActor
final class XxxViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var state: ViewState = .idle
    @Published var error: XxxError?
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        state.isLoading
    }
    
    // MARK: - Private Properties
    
    private let service: XxxServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Xxx")
    
    // MARK: - Initialization
    
    init(service: XxxServiceProtocol) {
        self.service = service
    }
    
    convenience init(environment: AppEnvironment = .shared) {
        self.init(service: environment.xxxService)
    }
    
    // MARK: - Public Methods
    
    func performAction() async {
        logger.info("开始执行操作")
        state = .loading
        error = nil
        
        do {
            let result = try await service.doSomething()
            state = .success
            logger.info("操作成功")
        } catch let xxxError as XxxError {
            error = xxxError
            state = .error(xxxError)
            logger.error("操作失败: \(xxxError.localizedDescription)")
        } catch {
            let xxxError = XxxError.unknownError(underlying: error)
            self.error = xxxError
            state = .error(xxxError)
            logger.error("操作失败: \(error.localizedDescription)")
        }
    }
}
```

### Service 模板

```swift
import Foundation

/// Xxx 服务协议
protocol XxxServiceProtocol: Actor {
    func doSomething() async throws -> Result
}

/// Xxx 服务实现
actor XxxService: XxxServiceProtocol {
    
    // MARK: - Properties
    
    private let configuration: XxxConfiguration
    
    // MARK: - Initialization
    
    init(configuration: XxxConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    func doSomething() async throws -> Result {
        // 实现逻辑
        throw XxxError.notImplemented
    }
}

// MARK: - Error Definition

enum XxxError: LocalizedError, Sendable {
    case notImplemented
    case invalidInput
    case processingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "功能未实现"
        case .invalidInput:
            return "输入无效"
        case .processingFailed(let error):
            return "处理失败: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "请检查输入参数"
        default:
            return "请重试"
        }
    }
}
```

### View 模板

```swift
import SwiftUI

/// Xxx 视图
struct XxxView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: XxxViewModel
    
    // MARK: - Initialization
    
    init(viewModel: XxxViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? XxxViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            contentSection
            actionButtonsSection
            
            if viewModel.state != .idle {
                statusSection
            }
        }
        .padding()
        .navigationTitle("Xxx 功能")
        .alert(isPresented: $showingErrorAlert) {
            errorAlert
        }
    }
    
    // MARK: - View Components
    
    private var contentSection: some View {
        VStack {
            Text("内容")
        }
    }
    
    private var actionButtonsSection: some View {
        HStack {
            Button("执行") {
                Task {
                    await viewModel.performAction()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
    }
    
    private var statusSection: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("处理中...")
            case .success:
                Label("完成", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .error(let error):
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var showingErrorAlert: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
    
    private var errorAlert: Alert {
        Alert(
            title: Text("操作失败"),
            message: Text(viewModel.error?.localizedDescription ?? ""),
            primaryButton: .default(Text("重试")) {
                Task {
                    await viewModel.performAction()
                }
            },
            secondaryButton: .cancel()
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        XxxView()
    }
}
```

---

## 🧪 测试模板

```swift
import Testing

@Suite("Xxx 服务测试")
struct XxxServiceTests {
    
    @Test("基本功能测试")
    func testBasicFunctionality() async throws {
        let service = XxxService()
        
        let result = try await service.doSomething()
        
        #expect(result != nil)
    }
    
    @Test("错误处理测试")
    func testErrorHandling() async {
        let service = XxxService()
        
        await #expect(throws: XxxError.invalidInput) {
            try await service.doSomethingInvalid()
        }
    }
}

@Suite("Xxx ViewModel 测试")
struct XxxViewModelTests {
    
    @Test("状态转换测试")
    @MainActor
    func testStateTransition() async {
        let mockService = MockXxxService()
        let viewModel = XxxViewModel(service: mockService)
        
        #expect(viewModel.state == .idle)
        
        await viewModel.performAction()
        
        #expect(viewModel.state == .success)
    }
}

// Mock Service
actor MockXxxService: XxxServiceProtocol {
    func doSomething() async throws -> Result {
        // 返回测试数据
        return Result.mock
    }
}
```

---

## 🎨 SwiftUI 速查

### 常用属性包装器

```swift
@State private var text = ""              // 视图内部状态
@Binding var isPresented: Bool            // 父视图传递的绑定
@StateObject private var vm: VM          // 视图拥有的对象
@ObservedObject var shared: Shared       // 外部传入的对象
@EnvironmentObject var appState: AppState // 环境对象
@Environment(\.colorScheme) var scheme   // 系统环境值
```

### 异步任务

```swift
// 视图出现时执行
.task {
    await viewModel.loadData()
}

// 按钮点击
Button("加载") {
    Task {
        await viewModel.loadData()
    }
}

// 带取消的任务
.task(id: refreshID) {
    await viewModel.loadData()
}
```

### 状态更新

```swift
// ✅ 在 MainActor 上更新
@MainActor
func updateUI() {
    self.text = "Updated"
}

// ✅ 从 Actor 返回到主线程
Task {
    let result = await service.getData()
    await MainActor.run {
        self.data = result
    }
}
```

---

## 📝 日志使用

```swift
import OSLog

// 定义 Logger
extension Logger {
    static let myFeature = Logger(subsystem: "com.app.toolkit", category: "MyFeature")
}

// 使用
Logger.myFeature.info("操作开始")
Logger.myFeature.debug("调试信息: \(value)")
Logger.myFeature.warning("警告: \(warning)")
Logger.myFeature.error("错误: \(error)")
Logger.myFeature.fault("严重错误: \(fault)")
```

---

## 🔍 常见错误和解决方案

### 错误 1: "Call to actor method outside isolated context"

```swift
// ❌ 错误
func test() {
    let result = service.getData()  // service 是 actor
}

// ✅ 正确
func test() async {
    let result = await service.getData()
}
```

### 错误 2: "Publishing changes from background threads"

```swift
// ❌ 错误
Task {
    let data = await fetchData()
    self.data = data  // self 是 ObservableObject
}

// ✅ 正确 - 使用 @MainActor
@MainActor
class ViewModel: ObservableObject {
    @Published var data: Data?
    
    func loadData() async {
        let data = await fetchData()
        self.data = data  // 自动在主线程
    }
}
```

### 错误 3: "Cannot use instance member within property initializer"

```swift
// ❌ 错误
struct MyView: View {
    @StateObject var vm = MyViewModel(service: AppEnvironment.shared.service)
}

// ✅ 正确 - 使用 init
struct MyView: View {
    @StateObject private var vm: MyViewModel
    
    init() {
        _vm = StateObject(wrappedValue: MyViewModel(
            service: AppEnvironment.shared.service
        ))
    }
}
```

---

## 📚 快速链接

- [完整架构文档](ARCHITECTURE.md)
- [编码规范](CODING_STYLE.md)
- [迁移指南](MIGRATION_GUIDE.md)
- [项目 README](PROJECT_README.md)

---

**打印此文档并贴在显眼位置！** 📌
