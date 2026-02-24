file_path = "/Users/vfzzz/Desktop/PetWell/Views/Insurance/InsuranceCompareView.swift"

with open(file_path, 'r') as f:
    content = f.read()

# Find the start of RemarkSheetView
start_idx = content.find("struct RemarkSheetView: View {")

if start_idx != -1:
    new_view = """struct RemarkSheetView: View {
  @Environment(\\.dismiss) var dismiss
  let title: String
  let remark: String
  let productName: String

  @State private var showRAGChat = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text(title)
          .font(.headline)
        Spacer()
        Button(action: { dismiss() }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 24))
            .foregroundColor(.gray.opacity(0.6))
        }
      }
      .padding()
      .background(Color(UIColor.systemBackground))

      Divider()

      // Remark content
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text(remark)
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(6)
        }
        .padding()
      }
      .frame(maxHeight: .infinity)

      Spacer()

      // AI Button
      Button(action: {
        showRAGChat = true
      }) {
        HStack(spacing: 8) {
          Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .semibold))
          Text("Ask AI for Explanation")
            .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
          Rectangle()
            .frame(height: 1.5)
            .foregroundColor(.clear)
            .background(
              LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
              )
            ),
          alignment: .top
        )
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .fullScreenCover(isPresented: $showRAGChat) {
      RAGChatView(contextString: constructContextString(), isPresented: $showRAGChat)
    }
  }

  private func constructContextString() -> String {
    return \"\"\"
      Context:
      - Coverage Term: \\(title)
      - Policy Type: \\(productName)
      \"\"\"
  }
}

// MARK: - Color Extension
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
"""
    # Find color extension
    color_ext_idx = content.find("// MARK: - Color Extension")
    
    # We will replace from start_idx to the end of file with new_view
    content = content[:start_idx] + new_view

    with open(file_path, 'w') as f:
        f.write(content)
