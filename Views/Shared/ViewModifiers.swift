import SwiftUI
import UIKit
import PhotosUI

// Helper extension for rounding specific corners
extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

struct OwnerProfileEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  let isMandatory: Bool
  let onSaved: (OwnerProfile) -> Void

  @State private var profile: OwnerProfile = OwnerProfileStore.shared.load()
  @State private var pickerItem: PhotosPickerItem?
  @State private var validationMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("Owner Profile") {
          HStack(spacing: 12) {
            if let data = profile.avatarImageData, let ui = UIImage(data: data) {
              Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
              Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
              Text("Change Avatar")
            }
          }

          TextField("Owner Name", text: $profile.name)
          TextField("Email", text: $profile.email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          TextField("Phone", text: $profile.phone)
            .keyboardType(.phonePad)
        }

        if let validationMessage {
          Section {
            Text(validationMessage)
              .foregroundColor(.red)
              .font(.footnote)
          }
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if !isMandatory {
            Button("Cancel") { dismiss() }
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
        }
      }
      .task(id: pickerItem) {
        guard let pickerItem else { return }
        if let data = try? await pickerItem.loadTransferable(type: Data.self) {
          profile.avatarImageData = data
        }
      }
    }
  }

  private func save() {
    let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines)
    let phone = profile.phone.trimmingCharacters(in: .whitespacesAndNewlines)
    if name.isEmpty || email.isEmpty || phone.isEmpty {
      validationMessage = "Please complete name, email, and phone before continuing."
      return
    }
    profile.name = name
    profile.email = email
    profile.phone = phone
    OwnerProfileStore.shared.save(profile)
    onSaved(profile)
    dismiss()
  }
}

// MARK: - Markdown Content View
// A reusable component for rendering Markdown content with table support

struct MarkdownContentView: View {
  let content: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(parseBlocks(), id: \.id) { block in
        blockView(for: block)
      }
    }
  }

  private func blockView(for block: MarkdownBlock) -> some View {
    Group {
      switch block.type {
      case .text:
        FormattedTextView(text: block.content)

      case .heading1:
        Text(block.content)
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(.primary)

      case .heading2:
        Text(block.content)
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(.primary)

      case .heading3, .heading4, .heading5, .heading6:
        Text(block.content)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.primary)

      case .bulletList:
        BulletListView(items: block.content.components(separatedBy: "\n").filter { !$0.isEmpty })

      case .numberedList:
        NumberedListView(items: block.content.components(separatedBy: "\n").filter { !$0.isEmpty })

      case .codeBlock:
        Text(block.content)
          .font(.system(size: 14, design: .monospaced))
          .padding(12)
          .background(Color(.systemGray6))
          .cornerRadius(8)

      case .table:
        ScrollView(.horizontal, showsIndicators: true) {
          TableView(markdownTable: block.content)
        }
      }
    }
  }

  private func parseBlocks() -> [MarkdownBlock] {
    let lines = content.components(separatedBy: "\n")
    var blocks: [MarkdownBlock] = []
    var currentBlock: [String] = []
    var currentType: MarkdownBlock.BlockType = .text

    func flushBlock() {
      if !currentBlock.isEmpty {
        let content = currentBlock.joined(separator: "\n")
        if !content.trimmingCharacters(in: .whitespaces).isEmpty {
          blocks.append(MarkdownBlock(type: currentType, content: content))
        }
        currentBlock = []
      }
    }

    var i = 0
    while i < lines.count {
      let line = lines[i]
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Table detection
      if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
        // Check if this is a table header followed by separator
        if i + 1 < lines.count {
          let nextLine = lines[i + 1].trimmingCharacters(in: .whitespaces)
          if nextLine.hasPrefix("|") && nextLine.contains("---") {
            flushBlock()
            // Collect table lines
            var tableLines: [String] = [line, lines[i + 1]]
            i += 2
            while i < lines.count {
              let tableLine = lines[i].trimmingCharacters(in: .whitespaces)
              if tableLine.hasPrefix("|") && tableLine.hasSuffix("|") && !tableLine.contains("---") {
                tableLines.append(tableLine)
                i += 1
              } else {
                break
              }
            }
            blocks.append(MarkdownBlock(type: .table, content: tableLines.joined(separator: "\n")))
            continue
          }
        }
      }

      // Code block
      if trimmed.hasPrefix("```") {
        flushBlock()
        i += 1
        var codeLines: [String] = []
        while i < lines.count {
          let codeLine = lines[i]
          if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
            break
          }
          codeLines.append(codeLine)
          i += 1
        }
        blocks.append(MarkdownBlock(type: .codeBlock, content: codeLines.joined(separator: "\n")))
        i += 1
        continue
      }

      // Headings
      if trimmed.hasPrefix("# ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading1, content: String(trimmed.dropFirst(2))))
      } else if trimmed.hasPrefix("## ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading2, content: String(trimmed.dropFirst(3))))
      } else if trimmed.hasPrefix("### ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading3, content: String(trimmed.dropFirst(4))))
      } else if trimmed.hasPrefix("#### ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading4, content: String(trimmed.dropFirst(5))))
      } else if trimmed.hasPrefix("##### ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading5, content: String(trimmed.dropFirst(6))))
      } else if trimmed.hasPrefix("###### ") {
        flushBlock()
        blocks.append(MarkdownBlock(type: .heading6, content: String(trimmed.dropFirst(7))))
      }
      // Bullet list
      else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
        if currentType != .bulletList {
          flushBlock()
          currentType = .bulletList
        }
        currentBlock.append(String(trimmed.dropFirst(2)))
      }
      // Numbered list
      else if let match = trimmed.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
        if currentType != .numberedList {
          flushBlock()
          currentType = .numberedList
        }
        currentBlock.append(String(trimmed[match.upperBound...]))
      }
      // Empty line - paragraph break
      else if trimmed.isEmpty {
        flushBlock()
        currentType = .text
      }
      // Regular text
      else {
        if currentType != .text {
          flushBlock()
          currentType = .text
        }
        currentBlock.append(line)
      }

      i += 1
    }

    flushBlock()
    return blocks
  }
}

// MARK: - Markdown Block

struct MarkdownBlock: Identifiable {
  let id = UUID()
  let type: BlockType
  let content: String

  enum BlockType {
    case text, heading1, heading2, heading3, heading4, heading5, heading6
    case bulletList, numberedList, codeBlock, table
  }
}

// MARK: - Formatted Text View

struct FormattedTextView: View {
  let text: String

  var body: some View {
    Text(attributedString)
      .font(.body)
      .foregroundColor(.primary)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var attributedString: AttributedString {
    var result = AttributedString()
    let lines = text.components(separatedBy: "\n")

    for (index, line) in lines.enumerated() {
      var lineAttributed = parseInlineFormatting(line)

      if index < lines.count - 1 {
        lineAttributed.append(AttributedString("\n"))
      }

      result.append(lineAttributed)
    }

    return result
  }

  private func parseInlineFormatting(_ text: String) -> AttributedString {
    var result = AttributedString()
    var remaining = text

    // Process bold and italic
    while !remaining.isEmpty {
      // Find bold (*** or **)
      if let boldItalicRange = remaining.range(of: "\\*\\*\\*(.+?)\\*\\*\\*", options: .regularExpression) {
        // Add text before
        if boldItalicRange.lowerBound > remaining.startIndex {
          let before = String(remaining[remaining.startIndex..<boldItalicRange.lowerBound])
          result.append(AttributedString(before))
        }

        // Add bold italic text
        let match = String(remaining[boldItalicRange])
        let content = match.replacingOccurrences(of: "***", with: "")
        var boldItalic = AttributedString(content)
        boldItalic.font = .system(size: 16, weight: .bold).italic()
        result.append(boldItalic)

        remaining = String(remaining[boldItalicRange.upperBound...])
      }
      else if let boldRange = remaining.range(of: "\\*\\*(.+?)\\*\\*", options: .regularExpression) {
        // Add text before
        if boldRange.lowerBound > remaining.startIndex {
          let before = String(remaining[remaining.startIndex..<boldRange.lowerBound])
          result.append(AttributedString(before))
        }

        // Add bold text
        let match = String(remaining[boldRange])
        let content = match.replacingOccurrences(of: "**", with: "")
        var bold = AttributedString(content)
        bold.font = .system(size: 16, weight: .bold)
        result.append(bold)

        remaining = String(remaining[boldRange.upperBound...])
      }
      else if let italicRange = remaining.range(of: "\\*(.+?)\\*", options: .regularExpression) {
        // Add text before
        if italicRange.lowerBound > remaining.startIndex {
          let before = String(remaining[remaining.startIndex..<italicRange.lowerBound])
          result.append(AttributedString(before))
        }

        // Add italic text
        let match = String(remaining[italicRange])
        let content = match.replacingOccurrences(of: "*", with: "")
        var italic = AttributedString(content)
        italic.font = .system(size: 16).italic()
        result.append(italic)

        remaining = String(remaining[italicRange.upperBound...])
      }
      else {
        // No more formatting
        result.append(AttributedString(remaining))
        break
      }
    }

    return result
  }
}

// MARK: - Bullet List View

struct BulletListView: View {
  let items: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(items, id: \.self) { item in
        HStack(alignment: .top, spacing: 8) {
          Text("•")
            .font(.body)
            .foregroundColor(.primary)
          Text(attributedString(for: item))
            .font(.body)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private func attributedString(for text: String) -> AttributedString {
    // Simple inline formatting for list items
    var result = AttributedString()
    var remaining = text

    while !remaining.isEmpty {
      if let boldRange = remaining.range(of: "\\*\\*(.+?)\\*\\*", options: .regularExpression) {
        if boldRange.lowerBound > remaining.startIndex {
          result.append(AttributedString(String(remaining[remaining.startIndex..<boldRange.lowerBound])))
        }
        let content = String(remaining[boldRange]).replacingOccurrences(of: "**", with: "")
        var bold = AttributedString(content)
        bold.font = .system(size: 16, weight: .bold)
        result.append(bold)
        remaining = String(remaining[boldRange.upperBound...])
      } else if let italicRange = remaining.range(of: "\\*(.+?)\\*", options: .regularExpression) {
        if italicRange.lowerBound > remaining.startIndex {
          result.append(AttributedString(String(remaining[remaining.startIndex..<italicRange.lowerBound])))
        }
        let content = String(remaining[italicRange]).replacingOccurrences(of: "*", with: "")
        var italic = AttributedString(content)
        italic.font = .system(size: 16).italic()
        result.append(italic)
        remaining = String(remaining[italicRange.upperBound...])
      } else {
        result.append(AttributedString(remaining))
        break
      }
    }

    return result
  }
}

// MARK: - Numbered List View

struct NumberedListView: View {
  let items: [String]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(Array(items.enumerated()), id: \.offset) { index, item in
        HStack(alignment: .top, spacing: 8) {
          Text("\(index + 1).")
            .font(.body)
            .foregroundColor(.primary)
          Text(attributedString(for: item))
            .font(.body)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private func attributedString(for text: String) -> AttributedString {
    var result = AttributedString()
    var remaining = text

    while !remaining.isEmpty {
      if let boldRange = remaining.range(of: "\\*\\*(.+?)\\*\\*", options: .regularExpression) {
        if boldRange.lowerBound > remaining.startIndex {
          result.append(AttributedString(String(remaining[remaining.startIndex..<boldRange.lowerBound])))
        }
        let content = String(remaining[boldRange]).replacingOccurrences(of: "**", with: "")
        var bold = AttributedString(content)
        bold.font = .system(size: 16, weight: .bold)
        result.append(bold)
        remaining = String(remaining[boldRange.upperBound...])
      } else if let italicRange = remaining.range(of: "\\*(.+?)\\*", options: .regularExpression) {
        if italicRange.lowerBound > remaining.startIndex {
          result.append(AttributedString(String(remaining[remaining.startIndex..<italicRange.lowerBound])))
        }
        let content = String(remaining[italicRange]).replacingOccurrences(of: "*", with: "")
        var italic = AttributedString(content)
        italic.font = .system(size: 16).italic()
        result.append(italic)
        remaining = String(remaining[italicRange.upperBound...])
      } else {
        result.append(AttributedString(remaining))
        break
      }
    }

    return result
  }
}

// MARK: - Table View

struct TableView: View {
  let markdownTable: String

  var body: some View {
    let (headers, rows) = parseTable()

    HStack(spacing: 0) {
      ForEach(Array(headers.enumerated()), id: \.offset) { colIndex, header in
        VStack(alignment: .leading, spacing: 0) {
          // Header
          Text(LocalizedStringKey(header))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minWidth: 90, alignment: .leading)
            .background(Color(.systemGray6))
            .overlay(
              Rectangle()
                .stroke(Color(.systemGray4), lineWidth: 0.5)
            )

          // Data rows for this column
          ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
            if colIndex < row.count {
              Text(LocalizedStringKey(row[colIndex]))
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 90, alignment: .leading)
                .background(rowIndex % 2 == 1 ? Color(.systemGray6).opacity(0.3) : Color.clear)
                .overlay(
                  Rectangle()
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            }
          }
        }
      }
    }
    .background(Color(.systemBackground))
    .cornerRadius(6)
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
  }

  private func parseTable() -> (headers: [String], rows: [[String]]) {
    let lines = markdownTable.components(separatedBy: "\n")
    guard lines.count >= 2 else { return ([], []) }

    let headerLine = lines[0]
    let headers = parseRow(headerLine)

    var rows: [[String]] = []
    for i in 2..<lines.count {
      let row = parseRow(lines[i])
      if !row.isEmpty && row != [""] {
        rows.append(row)
      }
    }

    return (headers, rows)
  }

  private func parseRow(_ line: String) -> [String] {
    let trimmed = line.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
    return trimmed.components(separatedBy: "|").map {
      $0.trimmingCharacters(in: .whitespaces)
    }
  }
}

// MARK: - Pet Insurance Placeholder View
// Temporary placeholder for pet-specific insurance page

struct PetInsurancePlaceholderView: View {
  let pet: PetModel?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        Image(systemName: "shield.fill")
          .font(.system(size: 80))
          .foregroundColor(.blue.opacity(0.3))

        if let petName = pet?.name {
          Text("for \(petName)")
            .font(.title2)
            .foregroundColor(.secondary)
        }

        Text("Coming Soon")
          .font(.headline)
          .foregroundColor(.secondary)
          .padding(.top, 10)

        Text("Pet insurance features are under development.\nCheck back later for updates!")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)

        Spacer()
      }
      .padding(.top, 100)
      .navigationTitle("Insurance")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Back") {
            dismiss()
          }
        }
      }
    }
    .hideTabBarWhenPushed()
  }
}

// MARK: - Tab Bar Auto-Hide

extension View {
  /// Apply to any child view that is pushed onto a NavigationStack.
  /// Hides the UITabBar while the view is on screen, synchronized with the
  /// push/pop animation — no sudden jump. Works correctly for multi-level
  /// navigation (only shows tab bar when returning all the way to the root).
  func hideTabBarWhenPushed() -> some View {
    background(TabBarAutoHideRepresentable())
  }
}

struct TabBarAutoHideRepresentable: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> Impl { Impl() }
  func updateUIViewController(_ uiViewController: Impl, context: Context) {}

  final class Impl: UIViewController {
    // Associated-object key for the hide-request counter stored on UITabBar.
    // Counter tracks how many child views are currently requesting the tab bar
    // to be hidden, so multi-level navigation works correctly (tab bar only
    // reappears when ALL child views have been popped).
    private nonisolated(unsafe) static var hideCountKey: UInt8 = 0

    /// Remember the bar so we can decrement even if the VC hierarchy is
    /// already torn down during viewWillDisappear.
    private weak var trackedBar: UITabBar?

    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      guard let bar = findTabBar() else { return }
      trackedBar = bar
      let count = Self.hideCount(for: bar) + 1
      Self.setHideCount(count, for: bar)
      if count == 1 { setTabBar(bar, hidden: true, animated: animated) }
    }

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      guard let bar = trackedBar ?? findTabBar() else { return }
      let count = max(0, Self.hideCount(for: bar) - 1)
      Self.setHideCount(count, for: bar)
      if count == 0 { setTabBar(bar, hidden: false, animated: animated) }
    }

    // MARK: - Counter helpers

    private static func hideCount(for bar: UITabBar) -> Int {
      objc_getAssociatedObject(bar, &hideCountKey) as? Int ?? 0
    }

    private static func setHideCount(_ count: Int, for bar: UITabBar) {
      objc_setAssociatedObject(bar, &hideCountKey, count, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - Animation

    private func setTabBar(_ bar: UITabBar, hidden: Bool, animated: Bool) {
      guard bar.isHidden != hidden else { return }

      let duration = animated ? 0.25 : 0.0
      if hidden {
        UIView.animate(withDuration: duration) { bar.alpha = 0 }
        completion: { _ in
          bar.isHidden = true
          bar.alpha = 1
        }
      } else {
        bar.isHidden = false
        bar.alpha = 0
        UIView.animate(withDuration: duration) { bar.alpha = 1 }
      }
    }

    // MARK: - Tab bar discovery

    private func findTabBar() -> UITabBar? {
      var r: UIResponder? = self
      while let cur = r {
        if let tbc = cur as? UITabBarController { return tbc.tabBar }
        r = cur.next
      }
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)?
        .rootViewController
        .flatMap { self.searchTabBarController($0) }?
        .tabBar
    }

    private func searchTabBarController(_ vc: UIViewController) -> UITabBarController? {
      if let tbc = vc as? UITabBarController { return tbc }
      return vc.children.lazy.compactMap { self.searchTabBarController($0) }.first
    }
  }
}
