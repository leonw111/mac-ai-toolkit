# Mac AI Toolkit 架构培训大纲

## 📋 培训概述

**目标**: 让团队成员全面理解新架构，能够独立开发新功能  
**时长**: 2-3 天（可分散进行）  
**形式**: 讲解 + 实践 + 代码审查

---

## 📅 培训计划

### Day 1: 架构理解（3-4 小时）

#### Session 1: 架构概览（1 小时）

**内容**:
1. 为什么需要重构架构？（当前问题）
2. 新架构的核心思想
3. 技术栈介绍
   - MVVM 模式
   - Swift Concurrency
   - 协议导向设计

**资料**: `ARCHITECTURE.md` 前半部分

**讨论**:
- Q: 为什么选择 MVVM 而不是其他架构？
- Q: Actor 和 @MainActor 的区别是什么？

#### Session 2: 分层架构详解（1 小时）

**内容**:
1. 四层架构
   - Presentation Layer (Views + ViewModels)
   - Application Layer (AppState + AppEnvironment)
   - Service Layer (Business Logic)
   - Domain Layer (Models + Protocols)

2. 依赖关系
   - 上层依赖下层
   - 同层不依赖
   - 通过协议解耦

**实践**:
- 在白板上画出架构图
- 讨论每层的职责

#### Session 3: 代码示例讲解（1.5 小时）

**内容**: 以 TTS 模块为例，讲解完整流程

1. **协议定义** - `TTSServiceProtocol.swift`
   ```swift
   protocol TTSServiceProtocol: Actor {
       func speak(text: String, configuration: TTSConfiguration) async throws
   }
   ```

2. **服务实现** - `TTSService.swift`
   ```swift
   actor TTSService: TTSServiceProtocol {
       func speak(text: String, configuration: TTSConfiguration) async throws {
           // 实现
       }
   }
   ```

3. **ViewModel** - `TTSViewModel.swift`
   ```swift
   @MainActor
   final class TTSViewModel: ObservableObject {
       @Published var state: ViewState = .idle
       private let ttsService: TTSServiceProtocol
       
       func playPreview() async {
           // 调用 service
       }
   }
   ```

4. **View** - `TTSView.swift`
   ```swift
   struct TTSView: View {
       @StateObject private var viewModel: TTSViewModel
       
       var body: some View {
           // UI 代码
       }
   }
   ```

**演示**:
- 运行 TTS 功能
- 展示数据流向
- 展示错误处理

#### Break（15 分钟）

#### Session 4: 依赖注入（30 分钟）

**内容**:
1. 什么是依赖注入？
2. `AppEnvironment` 的作用
3. 如何在测试中使用 Mock

**代码示例**:
```swift
// 生产环境
let viewModel = TTSViewModel(
    ttsService: AppEnvironment.shared.ttsService
)

// 测试环境
let mockService = MockTTSService()
let viewModel = TTSViewModel(
    ttsService: mockService
)
```

#### Session 5: Q&A（30 分钟）

开放讨论，回答疑问

---

### Day 2: 编码实践（4-5 小时）

#### Session 6: 编码规范（1 小时）

**内容**: 基于 `CODING_STYLE.md`

1. **命名规范**
   - 类型名: PascalCase
   - 变量/函数: camelCase
   - 协议: xxxProtocol

2. **代码组织**
   - MARK 的使用
   - 扩展的组织
   - 文件结构

3. **SwiftUI 最佳实践**
   - 属性包装器的使用
   - 视图拆分原则
   - 性能优化技巧

4. **Swift Concurrency**
   - async/await
   - @MainActor
   - Actor 使用场景

**实践**:
- 代码审查练习
- 找出不符合规范的代码

#### Session 7: 实战演练 - 创建新功能（2 小时）

**任务**: 每个人独立创建一个简单的功能模块

**示例任务**: 创建一个"文本统计"功能
- 统计文本的字符数、单词数、行数

**步骤**:

1. **定义协议** (15 分钟)
   ```swift
   protocol TextAnalysisServiceProtocol: Actor {
       func analyze(text: String) async -> TextStatistics
   }
   ```

2. **实现服务** (20 分钟)
   ```swift
   actor TextAnalysisService: TextAnalysisServiceProtocol {
       func analyze(text: String) async -> TextStatistics {
           // 实现统计逻辑
       }
   }
   ```

3. **创建 ViewModel** (30 分钟)
   ```swift
   @MainActor
   final class TextAnalysisViewModel: ObservableObject {
       @Published var text: String = ""
       @Published var statistics: TextStatistics?
       @Published var state: ViewState = .idle
       
       func analyze() async {
           // 调用服务
       }
   }
   ```

4. **创建视图** (45 分钟)
   ```swift
   struct TextAnalysisView: View {
       @StateObject private var viewModel: TextAnalysisViewModel
       
       var body: some View {
           // 实现 UI
       }
   }
   ```

5. **编写测试** (10 分钟)
   ```swift
   @Suite("文本分析测试")
   struct TextAnalysisTests {
       @Test func testAnalyze() async {
           // 测试代码
       }
   }
   ```

**代码审查** (每人 5 分钟):
- 展示实现
- 接受反馈
- 讨论改进

#### Break（15 分钟）

#### Session 8: 错误处理和日志（45 分钟）

**内容**:

1. **错误类型定义**
   ```swift
   enum MyError: LocalizedError {
       case invalidInput
       case processingFailed(underlying: Error)
       
       var errorDescription: String? { ... }
       var recoverySuggestion: String? { ... }
   }
   ```

2. **在 ViewModel 中处理错误**
   ```swift
   func performAction() async {
       do {
           let result = try await service.doSomething()
           state = .success
       } catch let myError as MyError {
           error = myError
           state = .error(myError)
       } catch {
           let myError = MyError.processingFailed(underlying: error)
           self.error = myError
           state = .error(myError)
       }
   }
   ```

3. **日志系统**
   ```swift
   import OSLog
   
   extension Logger {
       static let myFeature = Logger(subsystem: "...", category: "MyFeature")
   }
   
   Logger.myFeature.info("操作开始")
   Logger.myFeature.error("错误: \(error)")
   ```

**实践**:
- 为刚才创建的功能添加错误处理
- 添加日志记录

#### Session 9: 测试编写（1 小时）

**内容**:

1. **Swift Testing 介绍**
   ```swift
   import Testing
   
   @Suite("测试套件")
   struct MyTests {
       @Test("测试描述")
       func testSomething() async throws {
           #expect(result == expected)
       }
   }
   ```

2. **Service 测试**
   ```swift
   @Suite("服务测试")
   struct ServiceTests {
       @Test func testBasicFunctionality() async throws {
           let service = MyService()
           let result = try await service.doSomething()
           #expect(result != nil)
       }
   }
   ```

3. **ViewModel 测试**
   ```swift
   @Suite("ViewModel 测试")
   struct ViewModelTests {
       @Test
       @MainActor
       func testStateTransition() async {
           let vm = MyViewModel(service: MockService())
           await vm.performAction()
           #expect(vm.state == .success)
       }
   }
   ```

4. **Mock 对象**
   ```swift
   actor MockService: ServiceProtocol {
       func doSomething() async throws -> Result {
           return Result.mock
       }
   }
   ```

**实践**:
- 为刚才的功能编写测试
- 运行测试
- 查看覆盖率

---

### Day 3: 迁移实践（4-5 小时）

#### Session 10: 迁移策略讲解（45 分钟）

**内容**: 基于 `MIGRATION_GUIDE.md`

1. 迁移的 7 个阶段
2. 当前进度
3. 优先级排序
4. 注意事项

**讨论**:
- 哪个模块先迁移？
- 如何保证不影响现有功能？
- 如何处理破坏性变更？

#### Session 11: 模块迁移实战（2.5 小时）

**任务**: 分组迁移现有模块

**分组建议**:
- Group 1: OCR 模块
- Group 2: STT 模块
- Group 3: History 模块

**步骤** (以 OCR 为例):

1. **创建协议** (15 分钟)
   - 基于现有 `OCRService` 定义协议
   - 参考已创建的 `OCRServiceProtocol.swift`

2. **更新服务实现** (30 分钟)
   - 让 `OCRService` 实现协议
   - 移除单例模式
   - 添加到 `AppEnvironment`

3. **创建 ViewModel** (45 分钟)
   - 提取视图逻辑到 `OCRViewModel`
   - 使用依赖注入

4. **重构视图** (60 分钟)
   - 使用 `OCRViewModel`
   - 简化视图代码
   - 改进 UI

5. **测试** (10 分钟)
   - 手动测试功能
   - 确保没有退化

#### Break（15 分钟）

#### Session 12: 代码审查和反馈（1.5 小时）

**流程**:

1. **每组展示** (每组 15 分钟)
   - 展示重构后的代码
   - 讲解设计决策
   - 演示功能

2. **代码审查** (每组 10 分钟)
   - 使用 `CODING_STYLE.md` 检查清单
   - 讨论改进点
   - 记录问题

3. **总结** (15 分钟)
   - 常见问题汇总
   - 最佳实践分享
   - 后续计划

#### Session 13: Q&A 和总结（30 分钟）

1. **回顾**
   - 架构核心概念
   - 编码规范要点
   - 迁移策略

2. **开放讨论**
   - 还有什么不清楚的？
   - 有什么建议？
   - 需要什么支持？

3. **后续安排**
   - 迁移时间表
   - Code Review 流程
   - 定期技术分享

---

## 📚 培训材料清单

### 必读文档
- [x] `ARCHITECTURE.md` - 架构设计
- [x] `CODING_STYLE.md` - 编码规范
- [x] `MIGRATION_GUIDE.md` - 迁移指南
- [x] `QUICK_REFERENCE.md` - 快速参考

### 示例代码
- [x] `TTSServiceProtocol.swift` - 服务协议示例
- [x] `TTSViewModel.swift` - ViewModel 示例
- [x] `TTSView.swift` - 视图示例

### 实践项目
- [ ] 文本统计功能（培训练习）
- [ ] OCR 模块迁移（实战演练）

---

## ✅ 培训检查清单

### 培训前准备
- [ ] 所有团队成员收到培训通知
- [ ] 准备好演示环境
- [ ] 打印或分发文档
- [ ] 准备代码审查工具

### Day 1 结束
- [ ] 所有成员理解架构设计
- [ ] 能够解释 MVVM 模式
- [ ] 理解依赖注入概念
- [ ] 知道如何使用 async/await

### Day 2 结束
- [ ] 熟悉编码规范
- [ ] 能够独立创建简单功能
- [ ] 掌握错误处理方法
- [ ] 会编写基本测试

### Day 3 结束
- [ ] 理解迁移策略
- [ ] 能够迁移现有模块
- [ ] 熟悉代码审查流程
- [ ] 清楚后续工作计划

---

## 📊 培训效果评估

### 理论知识测试（可选）

**选择题**:
1. MVVM 中的 VM 代表什么？
   - A. Virtual Machine
   - B. View Model ✅
   - C. Value Management
   - D. Visual Mode

2. 在 SwiftUI 中，哪个属性包装器用于声明视图拥有的对象？
   - A. @State
   - B. @Binding
   - C. @StateObject ✅
   - D. @ObservedObject

3. Actor 的主要作用是什么？
   - A. 提高性能
   - B. 保证线程安全 ✅
   - C. 简化代码
   - D. 管理内存

**问答题**:
1. 解释依赖注入的好处
2. 说明何时使用 @MainActor
3. 描述 Service → ViewModel → View 的数据流

### 实践能力评估

**任务**: 独立完成一个小功能模块（1-2 小时）

**评分标准**:
- [ ] 正确使用协议定义（20%）
- [ ] Service 实现合理（20%）
- [ ] ViewModel 逻辑清晰（20%）
- [ ] View 代码简洁（20%）
- [ ] 错误处理完善（10%）
- [ ] 有基本测试（10%）

---

## 🎯 培训后行动计划

### 第 1 周
- [ ] 完成 OCR 模块迁移
- [ ] 每日站会分享进度
- [ ] 遇到问题及时讨论

### 第 2 周
- [ ] 完成 STT 和 History 模块迁移
- [ ] Code Review（每个 PR 至少 2 人审查）
- [ ] 更新文档

### 第 3 周
- [ ] 完成 Settings 模块迁移
- [ ] 补充测试用例
- [ ] 性能优化

### 第 4 周
- [ ] 全面测试
- [ ] 修复 Bug
- [ ] 总结经验

---

## 💡 培训技巧

### 对于讲师
1. **由浅入深**: 从概念到实践，循序渐进
2. **多用示例**: 每个概念都要有代码示例
3. **鼓励提问**: 营造开放讨论的氛围
4. **实践为主**: 理论 40%，实践 60%
5. **及时反馈**: 在实践环节提供即时指导

### 对于学员
1. **预习文档**: 培训前阅读相关文档
2. **做好笔记**: 记录关键点和疑问
3. **主动实践**: 多写代码，多尝试
4. **勇于提问**: 不懂就问，不要憋着
5. **课后复习**: 回顾培训内容，巩固知识

---

## 📞 培训支持

### 遇到问题怎么办？

1. **查文档**: 90% 的问题文档中都有答案
2. **看示例**: TTS 模块是完整参考实现
3. **问同事**: 团队成员互相帮助
4. **查资料**: Apple 官方文档
5. **讨论群**: 建立技术讨论群

### 持续学习资源

- [Swift.org](https://swift.org) - Swift 官方网站
- [Apple Developer](https://developer.apple.com) - Apple 开发者文档
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) - SwiftUI 教程
- [WWDC Videos](https://developer.apple.com/wwdc/) - WWDC 视频

---

## 🎉 培训总结

完成这个培训后，团队成员将能够：

✅ **理解** 项目的整体架构  
✅ **遵循** 统一的编码规范  
✅ **独立** 开发新功能模块  
✅ **编写** 可测试的代码  
✅ **参与** 代码审查  
✅ **迁移** 现有代码

这将显著提升：
- 📈 代码质量
- 🚀 开发效率
- 🤝 团队协作
- 🔧 维护性

---

**培训成功的关键**: 理论 + 实践 + 持续改进

**记住**: 架构不是一成不变的，根据实际情况持续优化！

---

**祝培训顺利！** 🎊
