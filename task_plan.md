# PetWell Profile & Pet Detail 页面改进计划

## Goal
1. Insurance 按钮改为打开空白页面（临时占位）
2. Booking Record 改为二级菜单（先选宠物 → 再选状态）
3. Pet Health Reports 页面改进：
   - 优化宠物选择器（减少宽度占用）
   - 添加录入功能（右上角按钮，支持上传照片/文件）
   - 与宠物卡片上的 Health Reports 页面保持一致

## Phases

### Phase 1: Insurance 按钮改为空白页面
**Status:** ✅ complete
**Files:**
- `Views/Records/RecordsView.swift` - Profile 页面的 Insurance 按钮
- `Views/Records/PetDetailView.swift` - 宠物详情的 Insurance 按钮
- `Views/Shared/ViewModifiers.swift` - 添加了 PetInsurancePlaceholderView

**Tasks:**
- [x] 创建 PetInsurancePlaceholderView（空白页面，显示"Coming Soon"）
- [x] 修改 RecordsView 的 Insurance 按钮跳转
- [x] 修改 PetDetailView 的 Insurance 按钮跳转

---

### Phase 2: Booking Record 二级菜单
**Status:** ✅ complete
**Files:**
- `Views/Records/BookingRecordView.swift` - 已重写

**Tasks:**
- [x] 设计一级菜单：宠物选择（横向滚动圆形头像+名字）
- [x] 设计二级菜单：状态筛选（All, Upcoming, Completed, Cancelled）
- [x] 实现宠物选择后的状态筛选联动

**New Features:**
- 宠物选择器：圆形头像设计，选中显示蓝色边框
- 未选择宠物时显示提示："Please Select a Pet"
- 选择宠物后显示状态筛选标签

---

### Phase 3: Pet Health Reports 页面改进
**Status:** ✅ complete
**Files:**
- `Views/Records/HealthReportsListView.swift` - 已重写

**Tasks:**
- [x] 优化宠物选择器（改为圆形头像横向滚动，更紧凑）
- [x] 右上角添加"+"按钮用于录入
- [x] 创建 AddHealthReportView 录入表单（支持照片上传）
- [x] PetDetailView 的 Health Reports 按钮已指向 HealthReportsListView

**New Features:**
- PetAvatarButton：紧凑的圆形头像宠物选择器
- AddHealthReportView：
  - 选择报告类型（General Checkup, Blood Test, X-Ray 等）
  - 选择日期
  - 照片上传（PhotosPicker）
  - 备注输入
  - 保存到 SwiftData

---

### Phase 4: 测试与验证
**Status:** ✅ complete
**Tasks:**
- [x] 编译验证所有修改 - BUILD SUCCEEDED
- [x] 检查导航流程是否正确

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| PetInsurancePlaceholderView not found | 1 | 将代码添加到 ViewModifiers.swift 而非单独文件 |
| HealthReportModel init 参数错误 | 1 | 修正为正确的参数：date, category, markdownContent, originalFileType, originalFileData |
| scaledToFit 语法错误 | 1 | 改为 scaledToFit() |

## Notes
- Insurance 页面后续会有新设计，当前仅作占位
- Health Reports 录入功能已支持照片上传
- Booking Record 现在采用二级菜单设计，与整体风格一致
- 所有页面编译通过
