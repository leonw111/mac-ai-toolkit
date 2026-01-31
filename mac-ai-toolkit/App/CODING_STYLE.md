# 编码规范与最佳实践

## 📝 Swift 编码风格

### 命名规范

#### 类型命名
```swift
// ✅ 正确：使用 PascalCase
class OCRService { }
struct TTSConfiguration { }
enum HistoryItemType { }
protocol OCRServiceProtocol { }

// ❌ 错误
class ocrService { }
struct tts_configuration { }
```

#### 变量和函数命名
```swift
// ✅ 正确：使用 camelCase
var inputText: String
func recognizeText(from image: NSImage)
let availableVoices: [VoiceInfo]

// ❌ 错误
var InputText: String
func RecognizeText(from image: NSImage)
let available_voices: [VoiceInfo]
```

#### 协议命名
```swift
// ✅ 正确：以 Protocol 结尾
protocol OCRServiceProtocol { }
protocol TTSServiceProtocol { }

// 或者使用形容词形式
protocol Cancellable { }
protocol Configurable { }
```

#### 常量命名
```swift
// ✅ 静态常量：使用 camelCase
static let defaultTimeout: TimeInterval = 30
static let maxRetryCount = 3

// ✅ 全局常量：可以使用 camelCase 或 SCREAMING_SNAKE_CASE
let apiEndpoint = "https://api.example.com"
let MAX_FILE_SIZE = 10_000_000
```

### 代码组织

#### 使用 MARK 分隔代码段
```swift
class OCRService {
    
    // MARK: - Properties
    
    private let configuration: OCRConfiguration
    
    // MARK: - Initialization
    
    init(configuration: OCRConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        // ...
    }
    
    // MARK: - Private Methods
    
    private func processImage(_ image: NSImage) -> CGImage? {
        // ...
    }
}

// MARK: - Protocol Conformance

extension OCRService: OCRServiceProtocol {
    // ...
}

// MARK: - Helper Types

private struct ImageProcessingResult {
    // ...
}
```

#### 扩展组织
```swift
// ✅ 将协议实现放在单独的扩展中
extension OCRService: OCRServiceProtocol {
    func recognizeText(from image: NSImage) async throws -> OCRResult {
        // ...
    }
}

// ✅ 将相关功能分组到扩展中
extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
}
```

### 类型推断

```swift
// ✅ 使用类型推断
let name = "John"
let count = 42
let items = ["a", "b", "c"]

// ⚠️ 只在必要时显式声明类型
let timeout: TimeInterval = 30.0  // 需要明确类型
let result: Result<String, Error> = .success("OK")  // 需要明确类型

// ❌ 不必要的类型声明
let name: String = "John"
let count: Int = 42
```

### 可选值处理

```swift
// ✅ 使用 guard let 提前返回
func process(text: String?) {
    guard let text = text, !text.isEmpty else {
        return
    }
    // 使用 text
}

// ✅ 使用 if let 处理可选值
if let value = optionalValue {
    print(value)
}

// ✅ 使用 nil-coalescing
let displayName = userName ?? "Guest"

// ❌ 避免强制解包
let text = optionalText!  // 危险！
```

### 错误处理

```swift
// ✅ 定义清晰的错误类型
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
    
    var recoverySuggestion: String? {
        switch self {
        case .imageProcessingFailed:
            return "请尝试使用其他图像"
        case .noTextFound:
            return "请确保图像中包含清晰的文字"
        case .serviceUnavailable:
            return "请检查系统权限设置"
        }
    }
}

// ✅ 使用 do-catch 处理错误
do {
    let result = try await service.recognizeText(from: image)
    handleSuccess(result)
} catch let ocrError as OCRError {
    handleOCRError(ocrError)
} catch {
    handleUnknownError(error)
}

// ✅ 使用 throws 传播错误
func processImage(_ image: NSImage) throws -> OCRResult {
    guard let cgImage = image.cgImage else {
        throw OCRError.imageProcessingFailed
    }
    // ...
}
```

### Swift Concurrency

```swift
// ✅ 使用 async/await
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// ✅ 使用 @MainActor 确保主线程执行
@MainActor
class ViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    
    func updateUI() {
        // 自动在主线程执行
        state = .loading
    }
}

// ✅ 使用 Task 启动异步任务
Button("Load") {
    Task {
        await viewModel.loadData()
    }
}

// ✅ 使用 actor 保证线程安全
actor DataCache {
    private var cache: [String: Data] = [:]
    
    func get(key: String) -> Data? {
        cache[key]
    }
    
    func set(key: String, value: Data) {
        cache[key] = value
    }
}

// ❌ 避免使用旧的并发方式
DispatchQueue.main.async {  // 使用 @MainActor 代替
    // ...
}
```

### SwiftUI 最佳实践

#### 视图拆分
```swift
// ✅ 将大视图拆分为小组件
struct ProfileView: View {
    var body: some View {
        VStack {
            headerSection
            contentSection
            footerSection
        }
    }
    
    private var headerSection: some View {
        HStack {
            // ...
        }
    }
    
    private var contentSection: some View {
        VStack {
            // ...
        }
    }
}

// ✅ 提取可复用组件
struct CustomButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}
```

#### 状态管理
```swift
// ✅ 使用正确的属性包装器
struct ContentView: View {
    @State private var text = ""              // 视图内部状态
    @Binding var isPresented: Bool            // 来自父视图的绑定
    @StateObject private var viewModel: ViewModel  // 视图拥有的对象
    @ObservedObject var sharedData: SharedData     // 共享的对象
    @EnvironmentObject var appState: AppState      // 环境对象
    @Environment(\.colorScheme) var colorScheme    // 系统环境值
}

// ✅ ViewModel 使用 @MainActor 和 @Published
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
}
```

#### 性能优化
```swift
// ✅ 避免在 body 中执行复杂计算
struct ItemListView: View {
    let items: [Item]
    
    // ✅ 使用计算属性
    private var sortedItems: [Item] {
        items.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List(sortedItems) { item in
            ItemRow(item: item)
        }
    }
}

// ✅ 使用 LazyVStack 处理大列表
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// ✅ 使用 .task 启动异步任务
.task {
    await viewModel.loadData()
}

// ✅ 使用 .id() 强制重新创建视图
Text("Content")
    .id(refreshID)
```

### 文档注释

```swift
/// OCR 识别服务
///
/// 提供图像文字识别功能，支持多语言识别
///
/// # 使用示例
/// ```swift
/// let service = OCRService()
/// let result = try await service.recognizeText(from: image)
/// print(result.text)
/// ```
///
/// - Note: 需要在 Info.plist 中配置相机权限
/// - Warning: 大图像可能需要较长处理时间
actor OCRService: OCRServiceProtocol {
    
    /// 识别图像中的文字
    ///
    /// - Parameters:
    ///   - image: 要识别的图像
    ///   - languages: 识别语言列表，nil 表示使用默认语言
    ///   - recognitionLevel: 识别级别（快速/准确）
    /// - Returns: OCR 识别结果，包含文字和置信度
    /// - Throws: `OCRError.imageProcessingFailed` 如果图像处理失败
    /// - Throws: `OCRError.noTextFound` 如果未识别到文字
    func recognizeText(
        from image: NSImage,
        languages: [String]? = nil,
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    ) async throws -> OCRResult {
        // ...
    }
}
```

### 单元测试

```swift
import Testing

@Suite("OCR 服务测试")
struct OCRServiceTests {
    
    @Test("识别简单文本")
    func testRecognizeSimpleText() async throws {
        let service = OCRService()
        let image = try #require(loadTestImage("simple_text.png"))
        
        let result = try await service.recognizeText(from: image)
        
        #expect(result.text.contains("Hello"))
        #expect(result.confidence > 0.8)
    }
    
    @Test("处理空图像应抛出错误")
    func testEmptyImageThrowsError() async {
        let service = OCRService()
        let emptyImage = NSImage(size: .zero)
        
        await #expect(throws: OCRError.imageProcessingFailed) {
            try await service.recognizeText(from: emptyImage)
        }
    }
    
    @Test("多语言识别", arguments: [
        ("chinese_text.png", "zh-Hans"),
        ("english_text.png", "en-US"),
        ("japanese_text.png", "ja-JP")
    ])
    func testMultiLanguageRecognition(imageName: String, language: String) async throws {
        let service = OCRService()
        let image = try #require(loadTestImage(imageName))
        
        let result = try await service.recognizeText(
            from: image,
            languages: [language]
        )
        
        #expect(result.recognizedLanguages.contains(language))
    }
}
```

## 🎨 代码审查检查清单

### 功能性
- [ ] 代码实现了需求的所有功能
- [ ] 边界情况都已处理
- [ ] 错误处理完整
- [ ] 异步操作正确处理

### 代码质量
- [ ] 命名清晰、有意义
- [ ] 函数长度适中（< 50 行）
- [ ] 类/结构体职责单一
- [ ] 没有重复代码
- [ ] 有适当的注释

### 性能
- [ ] 没有不必要的计算
- [ ] 使用了适当的数据结构
- [ ] 大列表使用了 Lazy 加载
- [ ] 图片等资源有优化

### 并发
- [ ] 正确使用 async/await
- [ ] UI 更新在主线程
- [ ] 没有数据竞争
- [ ] 使用了 actor 保护共享状态

### 测试
- [ ] 核心逻辑有单元测试
- [ ] 边界情况有测试覆盖
- [ ] Mock 依赖用于隔离测试

### 安全
- [ ] 用户输入有验证
- [ ] 敏感数据有加密
- [ ] API Key 不在代码中
- [ ] 文件操作有权限检查

## 🔧 工具推荐

- **SwiftLint**: 代码风格检查
- **SwiftFormat**: 代码格式化
- **Instruments**: 性能分析
- **Swift Testing**: 现代测试框架

---

**版本**: 1.0  
**最后更新**: 2026-01-31
