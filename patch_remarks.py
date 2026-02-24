import re

file_path = "/Users/vfzzz/Desktop/PetWell/Views/Insurance/InsuranceCompareView.swift"

with open(file_path, 'r') as f:
    content = f.read()

# 1. State vars
content = re.sub(
    r'@State private var showRemarkSheet = false\n\s*@State private var selectedRemark: String = ""\n\s*@State private var selectedRemarkData: RemarkData\?\n\s*@State private var selectedRemarkTitle: String = ""\n\s*@State private var selectedCoverageTerm: String = ""\n\s*@State private var selectedSubCoverageTerm: String\?\n',
    '@State private var remarkContext: RemarkSheetContext?\n',
    content
)

# 2. .sheet modifier
content = re.sub(
    r'\.sheet\(isPresented: \$showRemarkSheet\) \{\n\s*RemarkSheetView\(\n\s*title: selectedRemarkTitle,\n\s*remark: selectedRemark,\n\s*remarkData: selectedRemarkData,\n\s*coverageTerm: selectedCoverageTerm,\n\s*subCoverageTerm: selectedSubCoverageTerm,\n\s*isPresented: \$showRemarkSheet\n\s*\)\n\s*\}',
    '.sheet(item: $remarkContext) { context in\n      RemarkSheetView(\n        title: context.title,\n        remark: context.remark,\n        productName: context.productName\n      )\n    }',
    content
)

# 3. subCoverageStatusCell button
content = re.sub(
    r'Button\(action: \{\n\s*selectedRemark = remark\n\s*selectedRemarkData = nil\n\s*selectedRemarkTitle =\n\s*isLeft \? \(leftProduct\?\.insuranceName \?\? ""\) : \(rightProduct\?\.insuranceName \?\? ""\)\n\s*selectedCoverageTerm = subName\n\s*selectedSubCoverageTerm = nil\n\s*showRemarkSheet = true\n\s*\}\) \{',
    '''Button(action: {
            remarkContext = RemarkSheetContext(
              title: subName,
              remark: remark,
              productName: isLeft ? (leftProduct?.insuranceName ?? "") : (rightProduct?.insuranceName ?? "")
            )
          }) {''',
    content
)

# 4. coverageStatusCell button
content = re.sub(
    r'Button\(action: \{\n\s*selectedRemark = remark\n\s*selectedRemarkData = limit\?\.parsedRemark\n\s*selectedRemarkTitle =\n\s*isLeft \? \(leftProduct\?\.insuranceName \?\? ""\) : \(rightProduct\?\.insuranceName \?\? ""\)\n\s*selectedCoverageTerm = coverageType\n\s*selectedSubCoverageTerm = nil\n\s*showRemarkSheet = true\n\s*\}\) \{',
    '''Button(action: {
            remarkContext = RemarkSheetContext(
              title: coverageType,
              remark: remark,
              productName: isLeft ? (leftProduct?.insuranceName ?? "") : (rightProduct?.insuranceName ?? "")
            )
          }) {''',
    content
)

# 5. Add RemarkSheetContext definition
if 'struct RemarkSheetContext' not in content:
    content = content.replace(
        'struct InsuranceCompareView: View {',
        '''// MARK: - Remark Context
struct RemarkSheetContext: Identifiable {
  let id = UUID()
  let title: String
  let remark: String
  let productName: String
}

struct InsuranceCompareView: View {'''
    )

with open(file_path, 'w') as f:
    f.write(content)

