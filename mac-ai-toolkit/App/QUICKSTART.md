# 快速开始指南 - 按照项目架构开发新功能

本指南将帮助团队成员快速上手，按照项目架构标准开发新功能。

---

## 🎯 5 分钟快速入门

### 示例：添加一个新的 "翻译" 功能

#### 步骤 1：创建 Protocol（5 行代码）

```swift
// TranslationServiceProtocol.swift
protocol TranslationServiceProtocol {
    func translate(text: String, from: String, to: String) async throws -> String
}
```

#### 步骤 2：创建 Model（10 行代码）

```swift
// TranslationModels.swift
struct TranslationRequest: Codable {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
}

struct TranslationResult: Codable {
    let translatedText: String
    let confidence: Double
}
```

#### 步骤 3：创建 Service（30 行代码）

```swift
// TranslationService.swift
actor TranslationService: TranslationServiceProtocol {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(text: String, from: String, to: String) async throws -> String {
        // 实现翻译逻辑
        // 可以调用系统 API、第三方服务等
        
        // 示例：使用 NLLanguageRecognizer
        return "翻译结果"
    }
}
```

#### 步骤 4：创建 ViewModel（80 行代码）

```swift
// TranslationViewModel.swift
@MainActor
final class TranslationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published var sourceLanguage: String = "auto"
    @Published var targetLanguage: String = "zh-CN"
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Private Properties
    private let translationService: TranslationServiceProtocol
    private let historyService: HistoryServiceProtocol
    
    // MARK: - Initialization
    init(
        translationService: TranslationServiceProtocol = TranslationService.shared,
        historyService: HistoryServiceProtocol = EnhancedHistoryService.shared
    ) {
        self.translationService = translationService
        self.historyService = historyService
    }
    
    // MARK: - Public Methods
    func translate() {
        guard !inputText.isEmpty else { return }
        
        isTranslating = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                let result = try await translationService.translate(
                    text: inputText,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                
                outputText = result
                isTranslating = false
                
                // 记录历史
                await recordHistory()
            } catch {
                isTranslating = false
                handleError(error)
            }
        }
    }
    
    private func recordHistory() async {
        // 记录到历史服务
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
```

#### 步骤 5：创建 View（100 行代码）

```swift
// TranslationView.swift
struct TranslationView: View {
    @StateObject private var viewModel = TranslationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 输入区域
                TranslationInputSection(
                    text: $viewModel.inputText,
                    language: $viewModel.sourceLanguage
                )
                
                // 翻译按钮
                Button(action: viewModel.translate) {
                    if viewModel.isTranslating {
                        ProgressView()
                    } else {
                        Label("翻译", systemImage: "arrow.right.arrow.left")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.isEmpty)
                
                // 输出区域
                TranslationOutputSection(
                    text: viewModel.outputText,
                    language: $viewModel.targetLanguage
                )
            }
            .padding()
        }
        .navigationTitle("翻译")
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
```

#### 步骤 6：编写测试（50 行代码）

```swift
// TranslationViewModelTests.swift
@Suite("TranslationViewModel Tests")
@MainActor
struct TranslationViewModelTests {
    
    @Test("Translation calls service correctly")
    func testTranslation() async throws {
        let mockService = MockTranslationService()
        let viewModel = TranslationViewModel(
            translationService: mockService,
            historyService: MockHistoryService()
        )
        
        viewModel.inputText = "Hello"
        viewModel.sourceLanguage = "en"
        viewModel.targetLanguage = "zh-CN"
        
        viewModel.translate()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(mockService.translateCalled)
        #expect(!viewModel.outputText.isEmpty)
        #expect(!viewModel.isTranslating)
    }
}

@MainActor
final class MockTranslationService: TranslationServiceProtocol {
    var translateCalled = false
    
    func translate(text: String, from: String, to: String) async throws -> String {
        translateCalled = true
        return "你好"
    }
}
```

---

## 📋 开发检查清单

### 开始前
- [ ] 阅读 `ARCHITECTURE.md`
- [ ] 了解 MVVM 模式
- [ ] 熟悉 Swift Concurrency

### Protocol & Model（数据定义）
- [ ] 定义 `ServiceProtocol`
- [ ] 创建必要的 `Model` 结构体
- [ ] 实现 `Codable`、`Identifiable` 等协议

### Service（业务实现）
- [ ] 实现 `Protocol` 定义的方法
- [ ] 使用 `actor` 或 `@MainActor` 确保线程安全
- [ ] 添加错误处理
- [ ] 使用 `async/await` 处理异步操作

### ViewModel（业务逻辑）
- [ ] 标记 `@MainActor`
- [ ] 继承 `ObservableObject`
- [ ] 使用 `@Published` 发布状态
- [ ] 通过构造函数注入依赖
- [ ] 实现计算属性（如 `canPerformAction`）
- [ ] 统一错误处理
- [ ] 添加必要的 `MARK` 注释

### View（UI 层）
- [ ] 使用 `@StateObject` 持有 ViewModel
- [ ] 拆分复杂视图为多个 Section
- [ ] 添加错误提示（Alert）
- [ ] 添加加载状态（ProgressView）
- [ ] 禁用状态绑定到 ViewModel
- [ ] 添加 SwiftUI Preview

### Tests（测试）
- [ ] 创建 Mock 服务
- [ ] 测试主要功能
- [ ] 测试错误处理
- [ ] 测试边界条件
- [ ] 使用 Swift Testing 框架

---

## 🛠️ 常用代码模板

### 1. Service 模板

```swift
//
//  XXXService.swift
//  mac-ai-toolkit
//
//  XXX 服务
//

import Foundation

// MARK: - Protocol

protocol XXXServiceProtocol {
    func performAction() async throws -> Result
}

// MARK: - Implementation

actor XXXService: XXXServiceProtocol {
    static let shared = XXXService()
    
    // MARK: - Private Properties
    
    private var someResource: Resource?
    
    // MARK: - Initialization
    
    private init() {
        // 初始化
    }
    
    // MARK: - Public Methods
    
    func performAction() async throws -> Result {
        // 实现
        return Result()
    }
    
    // MARK: - Private Methods
    
    private func helperMethod() {
        // 辅助方法
    }
}

// MARK: - Supporting Types

struct Result {
    let data: String
}
```

### 2. ViewModel 模板

```swift
//
//  XXXViewModel.swift
//  mac-ai-toolkit
//
//  XXX 视图模型
//

import Foundation
import Combine

@MainActor
final class XXXViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var inputData: String = ""
    @Published var outputData: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Computed Properties
    
    var canPerformAction: Bool {
        !inputData.isEmpty && !isProcessing
    }
    
    // MARK: - Private Properties
    
    private let service: XXXServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(service: XXXServiceProtocol = XXXService.shared) {
        self.service = service
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 设置监听器
    }
    
    // MARK: - Public Methods
    
    func performAction() {
        guard canPerformAction else { return }
        
        isProcessing = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                let result = try await service.performAction()
                outputData = result.data
                isProcessing = false
            } catch {
                isProcessing = false
                handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// MARK: - Preview Support

extension XXXViewModel {
    static var preview: XXXViewModel {
        let viewModel = XXXViewModel()
        viewModel.inputData = "预览数据"
        return viewModel
    }
}
```

### 3. View 模板

```swift
//
//  XXXView.swift
//  mac-ai-toolkit
//
//  XXX 视图
//

import SwiftUI

struct XXXView: View {
    @StateObject private var viewModel = XXXViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 输入区域
                XXXInputSection(data: $viewModel.inputData)
                
                Divider()
                
                // 操作按钮
                XXXActionSection(
                    isProcessing: viewModel.isProcessing,
                    canPerformAction: viewModel.canPerformAction,
                    onAction: viewModel.performAction
                )
                
                Divider()
                
                // 输出区域
                XXXOutputSection(data: viewModel.outputData)
            }
            .padding()
        }
        .navigationTitle("功能名称")
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Subviews

struct XXXInputSection: View {
    @Binding var data: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输入")
                .font(.headline)
            
            TextField("请输入...", text: $data)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct XXXActionSection: View {
    let isProcessing: Bool
    let canPerformAction: Bool
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            if isProcessing {
                ProgressView()
            } else {
                Label("执行", systemImage: "play.fill")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canPerformAction)
    }
}

struct XXXOutputSection: View {
    let data: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输出")
                .font(.headline)
            
            Text(data.isEmpty ? "暂无数据" : data)
                .foregroundColor(data.isEmpty ? .secondary : .primary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        XXXView()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        XXXView()
    }
    .preferredColorScheme(.dark)
}
```

### 4. Test 模板

```swift
//
//  XXXViewModelTests.swift
//  mac-ai-toolkit-tests
//
//  XXX 视图模型测试
//

import Testing
import Foundation
@testable import mac_ai_toolkit

// MARK: - Mock Service

@MainActor
final class MockXXXService: XXXServiceProtocol {
    var actionCalled = false
    var shouldThrowError = false
    var resultToReturn: Result?
    
    func performAction() async throws -> Result {
        actionCalled = true
        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }
        return resultToReturn ?? Result(data: "mock")
    }
}

// MARK: - Tests

@Suite("XXXViewModel Tests")
@MainActor
struct XXXViewModelTests {
    
    @Test("Initialization sets default values")
    func testInitialization() {
        let viewModel = XXXViewModel(service: MockXXXService())
        
        #expect(viewModel.inputData.isEmpty)
        #expect(!viewModel.isProcessing)
    }
    
    @Test("Perform action calls service")
    func testPerformAction() async throws {
        let mockService = MockXXXService()
        let viewModel = XXXViewModel(service: mockService)
        
        viewModel.inputData = "test"
        viewModel.performAction()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(mockService.actionCalled)
        #expect(!viewModel.isProcessing)
        #expect(!viewModel.outputData.isEmpty)
    }
    
    @Test("Error handling shows error message")
    func testErrorHandling() async throws {
        let mockService = MockXXXService()
        mockService.shouldThrowError = true
        
        let viewModel = XXXViewModel(service: mockService)
        viewModel.inputData = "test"
        viewModel.performAction()
        
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(!viewModel.isProcessing)
        #expect(viewModel.showError)
        #expect(viewModel.errorMessage != nil)
    }
}
```

---

## 🎨 UI 组件库

项目中可复用的 UI 组件：

### 1. 参数滑块

```swift
struct ParameterSlider: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(label)
                .frame(width: 60, alignment: .leading)
            
            Slider(value: $value, in: range)
            
            Text(String(format: "%.1f", value))
                .frame(width: 40)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}

// 使用
ParameterSlider(
    label: "语速",
    icon: "speedometer",
    value: $rate,
    range: 0...1
)
```

### 2. 文本输入区

```swift
struct TextInputArea: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let onPaste: (() -> Void)?
    let onClear: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if !text.isEmpty, let onClear = onClear {
                    Button(action: onClear) {
                        Label("清空", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Text("\(text.count) 字符")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let onPaste = onPaste {
                    Button(action: onPaste) {
                        Label("粘贴", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }
}
```

---

## 💡 常见问题

### Q1: 什么时候使用 `actor`？什么时候使用 `@MainActor`？

**A:** 
- **Service 层**：使用 `actor`（如 TTSService、TranslationService）
- **ViewModel 层**：使用 `@MainActor`（需要更新 UI）
- **Model 层**：通常都不需要

### Q2: 如何处理异步操作？

**A:** 
```swift
// ✅ 推荐：使用 Task
func loadData() {
    Task {
        do {
            let data = try await service.fetchData()
            self.data = data
        } catch {
            handleError(error)
        }
    }
}

// ❌ 避免：使用回调
func loadData(completion: @escaping (Result<Data, Error>) -> Void) {
    // 不推荐
}
```

### Q3: 如何在 View 之间传递数据？

**A:**
- **父 → 子**：直接传参或 `@Binding`
- **子 → 父**：通过闭包回调
- **跨层级**：使用 `@EnvironmentObject`

```swift
// 父传子
struct ParentView: View {
    @State private var text = "Hello"
    
    var body: some View {
        ChildView(text: $text)  // Binding
    }
}

struct ChildView: View {
    @Binding var text: String
    
    var body: some View {
        TextField("", text: $text)
    }
}

// 子传父
struct ParentView: View {
    var body: some View {
        ChildView { result in
            print("Got: \(result)")
        }
    }
}

struct ChildView: View {
    let onComplete: (String) -> Void
    
    var body: some View {
        Button("完成") {
            onComplete("结果")
        }
    }
}
```

### Q4: 如何添加新的设置项？

**A:**
1. 在 `AppState.swift` 的 `AppSettings` 中添加属性
2. 在 `SettingsView` 中添加 UI
3. 通过 `@EnvironmentObject` 访问

---

## 🚀 发布前检查

- [ ] 所有测试通过
- [ ] 代码已格式化
- [ ] 删除所有 `print` 调试语句
- [ ] 更新文档
- [ ] 添加注释
- [ ] 检查内存泄漏
- [ ] 性能测试通过

---

**祝你开发愉快！有问题随时查阅 `ARCHITECTURE.md` 或咨询团队成员。**
