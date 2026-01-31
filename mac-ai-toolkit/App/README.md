# Mac AI Toolkit

macOS AI 工具集，集成 OCR、TTS、STT 功能。

## 🏗️ 项目架构

采用 **MVVM** 模式，遵循 Swift 最佳实践。

### 目录结构

```
mac-ai-toolkit/
├── App/                  # 应用核心
├── Features/             # 功能模块（OCR, TTS, STT）
├── Shared/               # 共享代码（Models, Services, Extensions）
└── Resources/            # 资源文件
```

### 核心原则

- **MVVM**: View → ViewModel → Service → Model
- **协议导向**: 面向接口编程
- **依赖注入**: 构造函数注入
- **Swift Concurrency**: async/await + Actor

## 📝 编码规范

详见 [ARCHITECTURE.md](ARCHITECTURE.md)

### 快速参考

```swift
// Service（业务逻辑）
protocol ServiceProtocol {
    func doWork() async throws
}

actor MyService: ServiceProtocol {
    func doWork() async throws { }
}

// ViewModel（视图逻辑）
@MainActor
final class MyViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol = MyService()) {
        self.service = service
    }
}

// View（UI）
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        Button("执行") {
            Task { await viewModel.performAction() }
        }
    }
}
```

## 🚀 快速开始

### 环境要求

- macOS 14.0+
- Xcode 16.0+
- Swift 6.0+

### 运行项目

```bash
git clone <repo-url>
cd mac-ai-toolkit
open mac-ai-toolkit.xcodeproj
```

按 `Cmd+R` 运行。

## 🧪 测试

使用 Swift Testing 框架：

```swift
import Testing

@Suite("功能测试")
struct MyTests {
    @Test func testFeature() async {
        #expect(result == expected)
    }
}
```

按 `Cmd+U` 运行测试。

## 📚 文档

- [完整架构文档](ARCHITECTURE.md) - 详细的编码规范和最佳实践

## 📄 许可证

MIT License
