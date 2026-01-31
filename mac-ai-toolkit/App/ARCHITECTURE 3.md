# Mac AI Toolkit 项目架构

## 📐 架构设计

### 核心原则
- **MVVM 模式**: View → ViewModel → Service → Model
- **协议导向**: 面向接口编程，便于测试
- **依赖注入**: 通过构造函数注入，避免硬编码
- **Swift Concurrency**: 使用 async/await 和 Actor

### 项目结构

```
mac-ai-toolkit/
├── App/
│   ├── MacAIToolkitApp.swift
│   ├── AppDelegate.swift
│   └── AppState.swift              # 全局状态
│
├── Features/                        # 按功能模块组织
│   ├── OCR/
│   │   ├── OCRView.swift
│   │   ├── OCRViewModel.swift
│   │   └── OCRService.swift
│   ├── TTS/
│   │   ├── TTSView.swift
│   │   ├── TTSViewModel.swift
│   │   └── TTSService.swift
│   └── STT/
│
├── Shared/                          # 共享代码
│   ├── Models/                      # 数据模型
│   ├── Services/                    # 通用服务
│   │   ├── HistoryService.swift
│   │   └── SettingsService.swift
│   └── Extensions/                  # 扩展
│
└── Resources/
```

---

## 📝 编码规范

### 1. 命名规范

```swift
// 类型名: PascalCase
class OCRService { }
struct TTSConfiguration { }
protocol ServiceProtocol { }

// 变量/函数: camelCase
var inputText: String
func recognizeText()

// 常量
let maxRetryCount = 3
static let shared = Instance()
```

### 2. 代码组织

```swift
class MyClass {
    // MARK: - Properties
    private let service: ServiceType
    
    // MARK: - Initialization
    init(service: ServiceType) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func publicMethod() { }
    
    // MARK: - Private Methods
    private func privateMethod() { }
}
```

### 3. MVVM 模式

#### Service（业务逻辑）
```swift
protocol TTSServiceProtocol {
    func speak(text: String, rate: Float, pitch: Float) async throws
}

actor TTSService: TTSServiceProtocol {
    func speak(text: String, rate: Float, pitch: Float) async throws {
        // 实现 TTS 逻辑
    }
}
```

#### ViewModel（视图逻辑）
```swift
@MainActor
final class TTSViewModel: ObservableObject {
    // 发布的状态
    @Published var inputText: String = ""
    @Published var isPlaying: Bool = false
    @Published var errorMessage: String?
    
    // 依赖的服务
    private let ttsService: TTSServiceProtocol
    
    // 依赖注入
    init(ttsService: TTSServiceProtocol = TTSService()) {
        self.ttsService = ttsService
    }
    
    // 业务方法
    func playPreview() async {
        isPlaying = true
        do {
            try await ttsService.speak(text: inputText, rate: 0.5, pitch: 1.0)
            isPlaying = false
        } catch {
            errorMessage = error.localizedDescription
            isPlaying = false
        }
    }
}
```

#### View（UI）
```swift
struct TTSView: View {
    @StateObject private var viewModel = TTSViewModel()
    
    var body: some View {
        VStack {
            TextEditor(text: $viewModel.inputText)
            
            Button("播放") {
                Task {
                    await viewModel.playPreview()
                }
            }
            .disabled(viewModel.isPlaying)
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

### 4. Swift Concurrency

```swift
// ✅ 使用 async/await
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// ✅ 使用 @MainActor 确保主线程
@MainActor
class ViewModel: ObservableObject {
    @Published var data: String = ""
    
    func loadData() async {
        // 自动在主线程执行
        data = await fetchData()
    }
}

// ✅ 使用 Actor 保证线程安全
actor DataCache {
    private var cache: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        cache[key]
    }
}

// ✅ 在 View 中启动异步任务
Button("加载") {
    Task {
        await viewModel.loadData()
    }
}
```

### 5. 错误处理

```swift
// 定义清晰的错误类型
enum TTSError: LocalizedError {
    case invalidText
    case synthesizeFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidText:
            return "文本无效"
        case .synthesizeFailed(let error):
            return "合成失败: \(error.localizedDescription)"
        }
    }
}

// 在代码中使用
do {
    try await service.speak(text: text)
} catch let error as TTSError {
    // 处理特定错误
} catch {
    // 处理通用错误
}
```

### 6. SwiftUI 最佳实践

```swift
// ✅ 视图拆分
struct ContentView: View {
    var body: some View {
        VStack {
            headerSection
            contentSection
            footerSection
        }
    }
    
    private var headerSection: some View {
        Text("Header")
    }
}

// ✅ 使用正确的属性包装器
struct MyView: View {
    @State private var text = ""              // 视图内部状态
    @StateObject private var vm = VM()        // 视图拥有的对象
    @ObservedObject var shared: Shared        // 外部传入的对象
    @EnvironmentObject var appState: AppState // 环境对象
}

// ✅ 异步任务
.task {
    await viewModel.loadData()
}

// ✅ 避免在 body 中复杂计算
// ❌ 不好
var body: some View {
    let sortedItems = items.sorted()  // 每次刷新都计算
    List(sortedItems) { ... }
}

// ✅ 好
private var sortedItems: [Item] {
    items.sorted()
}

var body: some View {
    List(sortedItems) { ... }
}
```

---

## 🔧 实用代码模板

### Service 模板

```swift
protocol MyServiceProtocol {
    func doSomething() async throws -> Result
}

actor MyService: MyServiceProtocol {
    func doSomething() async throws -> Result {
        // 实现逻辑
        throw MyError.notImplemented
    }
}

enum MyError: LocalizedError {
    case notImplemented
    
    var errorDescription: String? {
        "功能未实现"
    }
}
```

### ViewModel 模板

```swift
@MainActor
final class MyViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var error: Error?
    
    private let service: MyServiceProtocol
    
    init(service: MyServiceProtocol = MyService()) {
        self.service = service
    }
    
    func performAction() async {
        state = .loading
        do {
            let result = try await service.doSomething()
            state = .success
        } catch {
            self.error = error
            state = .error
        }
    }
}

enum ViewState {
    case idle, loading, success, error
}
```

### View 模板

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            contentView
            
            Button("执行") {
                Task {
                    await viewModel.performAction()
                }
            }
            .disabled(viewModel.state == .loading)
        }
        .alert("错误", isPresented: .constant(viewModel.error != nil)) {
            Button("确定") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            Text("准备就绪")
        case .loading:
            ProgressView("处理中...")
        case .success:
            Text("完成")
        case .error:
            Text("失败")
        }
    }
}
```

---

## 🧪 测试

### 使用 Swift Testing

```swift
import Testing

@Suite("功能测试")
struct MyTests {
    
    @Test("基本功能")
    func testBasic() async throws {
        let service = MyService()
        let result = try await service.doSomething()
        #expect(result != nil)
    }
    
    @Test("错误处理")
    func testError() async {
        await #expect(throws: MyError.self) {
            try await service.doInvalidOperation()
        }
    }
}
```

### Mock 对象

```swift
actor MockService: MyServiceProtocol {
    var shouldFail = false
    
    func doSomething() async throws -> Result {
        if shouldFail {
            throw MyError.failed
        }
        return Result.mock
    }
}

// 在测试中使用
@Test
@MainActor
func testViewModel() async {
    let mockService = MockService()
    let viewModel = MyViewModel(service: mockService)
    
    await viewModel.performAction()
    
    #expect(viewModel.state == .success)
}
```

---

## 📋 代码审查清单

### 功能性
- [ ] 代码实现了需求
- [ ] 边界情况已处理
- [ ] 错误处理完整

### 代码质量
- [ ] 命名清晰、有意义
- [ ] 遵循 MVVM 模式
- [ ] 使用依赖注入
- [ ] 函数长度适中（< 50 行）

### 并发
- [ ] 正确使用 async/await
- [ ] UI 更新在主线程（@MainActor）
- [ ] 使用 Actor 保护共享状态

### SwiftUI
- [ ] 使用正确的属性包装器
- [ ] 复杂视图已拆分
- [ ] 避免在 body 中复杂计算

---

## 🚀 快速开始

### 创建新功能的步骤

1. **定义 Service**
   ```swift
   protocol NewServiceProtocol {
       func doWork() async throws
   }
   
   actor NewService: NewServiceProtocol {
       func doWork() async throws { }
   }
   ```

2. **创建 ViewModel**
   ```swift
   @MainActor
   final class NewViewModel: ObservableObject {
       @Published var state: ViewState = .idle
       private let service: NewServiceProtocol
       
       init(service: NewServiceProtocol = NewService()) {
           self.service = service
       }
   }
   ```

3. **创建 View**
   ```swift
   struct NewView: View {
       @StateObject private var viewModel = NewViewModel()
       var body: some View { }
   }
   ```

4. **编写测试**
   ```swift
   @Suite("New Feature Tests")
   struct NewTests {
       @Test func testFeature() async { }
   }
   ```

---

## 🔍 常见问题

### Q: 何时使用 @State vs @StateObject?
- `@State`: 简单值类型（String, Int, Bool）
- `@StateObject`: 引用类型（ObservableObject）

### Q: 何时使用 Actor vs @MainActor?
- `Actor`: Service 层，需要线程安全
- `@MainActor`: ViewModel 层，需要更新 UI

### Q: 如何在测试中使用 Mock?
```swift
// 定义协议
protocol ServiceProtocol { }

// 生产环境
class RealService: ServiceProtocol { }

// 测试环境
class MockService: ServiceProtocol { }

// 依赖注入
init(service: ServiceProtocol = RealService()) {
    self.service = service
}
```

---

**保持简单，专注核心！** 🎯
