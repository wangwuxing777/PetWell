# ForYou 保险推荐功能 — 手动测试文档

**功能模块：** For You 多 Agent 保险推荐链路
**测试人：** Human Lead
**最后更新：** 2026-03-09

---

## 📋 测试前准备

### 1. 启动 App（模拟器）
在 Xcode 中按 ▶ Run，选 iPhone 16 Pro 模拟器。

### 2. 创建测试宠物（需要提前建好以下 4 只，用于不同场景）

| 宠物编号 | 名字 | 物种 | 品种 | 出生年份 | 体重 |
|---|---|---|---|---|---|
| Pet-A | Buddy | Dog | Labrador | 2020（约4岁）| 28 kg |
| Pet-B | Tiny | Dog | Chihuahua | 2023（约1岁）| 3 kg |
| Pet-C | Mochi | Cat | Persian | 2019（约6岁）| 4 kg |
| Pet-D | Rex | Dog | German Shepherd | 2010（约14岁）| 30 kg |

> 进入 **Profile Tab → 添加宠物** 逐一创建。
> 出生年份填写即可（App 会自动计算年龄）。

---

## 🧪 测试用例

---

### TC-01｜入口按钮 — 单宠物直接进入流程

**测试目的：** 验证只有 1 只宠物时，点击「For Me」直接启动流程（不弹选择器）

**前置条件：** App 内只有 1 只宠物（可暂时只留 Pet-A）

**操作步骤：**
1. 进入 **Insurance Tab**
2. 在页面上方的 mini-header 找到「**For Me**」按钮（需往上滑一点才出现）
3. 点击「For Me」

**预期结果：**
- ✅ 直接弹出「**ForYou Progress 进度页面**」（5 个步骤的 Stepper）
- ✅ **不** 弹出宠物选择器

**通过标准：** 看到 5 步进度弹窗即通过

---

### TC-02｜入口按钮 — 多宠物先选择

**测试目的：** 验证有多只宠物时，先弹出宠物选择器

**前置条件：** App 内有 2+ 只宠物（Pet-A 和 Pet-B 都存在）

**操作步骤：**
1. 进入 **Insurance Tab**
2. 滑到 mini-header，点击「**For Me**」

**预期结果：**
- ✅ 弹出**宠物选择器 Sheet**（列出 Buddy 和 Tiny）
- ✅ 点击某只宠物 → Sheet 关闭 → 出现 5 步进度页面

**通过标准：** 看到宠物列表，选择后进入进度页面

---

### TC-03｜宠物选择器 — Cancel 按钮

**测试目的：** 验证 Cancel 可以关闭选择器且不启动流程

**前置条件：** 同 TC-02（多宠物）

**操作步骤：**
1. 进入 Insurance Tab，点击「For Me」
2. 弹出宠物选择器后，点击右上角「**Cancel**」

**预期结果：**
- ✅ 选择器关闭
- ✅ 回到 Insurance 页面，**没有**任何进度弹窗出现

**通过标准：** 选择器消失，回到原页面

---

### TC-04｜5 步进度页面 — 步骤动画

**测试目的：** 验证 5 个步骤依次执行并更新状态

**前置条件：** 任意 1 只宠物

**操作步骤：**
1. 点击「For Me」启动流程（选 Pet-A Labrador）
2. 观察进度弹窗

**预期结果 — 观察以下 5 个步骤依次出现：**

| 步骤 | 内容 | 状态变化 |
|---|---|---|
| Step 1 | Age Filter（年龄筛选）| ⏳ 进行中 → ✅ 完成 |
| Step 2 | Breed Risk（品种风险）| ⏳ 进行中 → ✅ 完成 |
| Step 3 | Medical RAG（病历分析）| ⏳ 进行中 → ✅/⚠️ 完成或跳过 |
| Step 4 | Context Assembly（画像组装）| ⏳ 进行中 → ✅ 完成 |
| Step 5 | Insurance RAG（保险推荐）| ⏳ 进行中 → ✅ 完成 |

> ⚠️ Step 3 和 Step 5 依赖后端（localhost:8000）。如果后端没跑，这两步会显示失败或跳过 — 这是正常的，不算 bug。

**通过标准：** 看到 5 个步骤图标和文字，至少 Step 1、2、4 能完成

---

### TC-05｜进度页面 — X 关闭按钮

**测试目的：** 验证在流程进行中可以随时关闭

**操作步骤：**
1. 点击「For Me」启动流程
2. 步骤进行中，点击右上角「**✕**」关闭按钮

**预期结果：**
- ✅ 进度弹窗关闭
- ✅ 回到 Insurance 页面
- ✅ 不 crash

**通过标准：** 正常关闭，无崩溃

---

### TC-06｜品种逻辑 — 大型犬 vs 小型犬对比

**测试目的：** 验证 LargeDogAgent 对不同品种产生不同推荐 context

**操作步骤 A（大型犬）：**
1. 选 **Pet-A（Labrador / 28kg）**
2. 启动 For Me 流程
3. 如果 RAG 完成，进入 Chat 页面
4. 看 RAG 的初始推荐文字是否提到「**third-party liability**」或「**大型犬**」相关

**操作步骤 B（小型犬）：**
1. 改用 **Pet-B（Chihuahua / 3kg）**
2. 重复上述步骤

**预期结果：**
- ✅ Labrador → Chat 初始消息**包含**第三方责任险提示
- ✅ Chihuahua → Chat 初始消息**不包含**第三方责任险提示

**通过标准：** 两者推荐内容有明显区别

---

### TC-07｜品种逻辑 — 品种遗传病风险

**测试目的：** 验证 BreedRiskAgent 为不同品种提供对应的风险数据

**操作步骤：**
1. 分别用以下宠物启动 For Me 流程，观察 Step 2 或 Chat 内容：

| 宠物 | 品种 | 预期出现的风险缩写 |
|---|---|---|
| Pet-A | Labrador | HD/ED, EIC, PRA |
| Pet-C | Persian（猫）| PKD, BOAS |
| Pet-D | German Shepherd | HD/ED, DM |

**预期结果：**
- ✅ Chat 推荐内容中对应品种的遗传病风险被提及
- ✅ 未知品种（如「Mixed Breed」）→ 推荐内容中说「No specific breed risks」

**通过标准：** 各品种对应的疾病缩写出现在推荐中

---

### TC-08｜年龄筛选 — 超龄宠物

**测试目的：** 验证超出保险年龄上限的宠物得到合适推荐

**操作步骤：**
1. 使用 **Pet-D（German Shepherd，约 14 岁）**
2. 启动 For Me 流程
3. 观察 Step 1 结果和 Chat 内容

**预期结果：**
- ✅ Step 1 完成后，符合年龄要求的方案数**较少**（多数保险有 8-11 岁上限）
- ✅ Chat 推荐会提到「仅 X 个方案符合年龄要求」

**通过标准：** 推荐方案数比年轻宠物明显更少

---

### TC-09｜健康报告 — 有报告时的上下文

**测试目的：** 验证 HealthReportExtractor 将健康报告纳入推荐

**前置条件：** Pet-A 已有至少 1 份健康报告（Records Tab → 上传报告）

**操作步骤：**
1. 先在 **Records Tab** 为 Pet-A 上传一份健康报告（随便扫一张图）
2. 回到 Insurance Tab，用 Pet-A 启动 For Me
3. 等 Step 3（Medical RAG）完成
4. 查看 Chat 初始消息

**预期结果：**
- ✅ 有健康报告 → Chat 消息会提到从报告中提取的信息
- ✅ 无健康报告 → Chat 消息会说「No health reports on file」

**通过标准：** 两种情况下 Chat 初始消息不同

---

### TC-10｜Guardian FAB 红点

**测试目的：** 验证流程完成后 Guardian FAB 出现红点

**前置条件：** 后端需要运行（`./launch.sh` 启动服务）

**操作步骤：**
1. 确认主页面右下角 Guardian FAB 没有红点
2. 启动 For Me 流程（全程等待，不要按 X 关闭）
3. 流程完成后自动跳转到 Chat 页面
4. 关闭 Chat，返回主页面

**预期结果：**
- ✅ Guardian FAB 上出现**红色小圆点**
- ✅ 点击 FAB，红点消失（或进入推荐查看页）

**通过标准：** 看到红点即通过（需要后端在线）

---

## 📊 测试结果记录表

| 用例 | 测试日期 | 结果 | 备注 |
|---|---|---|---|
| TC-01 单宠物直入流程 | | ⬜ Pass / ⬜ Fail | |
| TC-02 多宠物选择器 | | ⬜ Pass / ⬜ Fail | |
| TC-03 Cancel 关闭 | | ⬜ Pass / ⬜ Fail | |
| TC-04 5步进度动画 | | ⬜ Pass / ⬜ Fail | |
| TC-05 X关闭按钮 | | ⬜ Pass / ⬜ Fail | |
| TC-06 大型犬推荐差异 | | ⬜ Pass / ⬜ Fail | 需RAG在线 |
| TC-07 品种遗传病风险 | | ⬜ Pass / ⬜ Fail | 需RAG在线 |
| TC-08 超龄宠物筛选 | | ⬜ Pass / ⬜ Fail | |
| TC-09 健康报告上下文 | | ⬜ Pass / ⬜ Fail | 需RAG在线 |
| TC-10 Guardian FAB红点 | | ⬜ Pass / ⬜ Fail | 需RAG在线 |

---

## ⚠️ 已知限制（不算 Bug）

- **TC-06/07/09/10** 依赖 RAG 后端（localhost:8000）和 Insurance API（localhost:8000）。如果后端没运行，Step 3 和 Step 5 会失败，Chat 不会自动打开 — 这是正常的 graceful failure。
- **TC-08** 的「方案少」依赖 Insurance API 返回真实的保险产品年龄字段。如果 API 返回数据不含年龄，筛选结果可能不变化。
- **BreedRiskAgent 数据库** 目前是占位数据，真实医学验证需要 Human Lead 审查 `BreedRiskAgent.swift` 中的品种列表。
