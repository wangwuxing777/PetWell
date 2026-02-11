import SwiftUI

struct RAGChatView: View {
  @StateObject var ragService = RAGService()
  @State private var question = ""

  // Design Constants
  private let bubbleColorUser = Color.blue
  private let bubbleColorAI = Color(UIColor.secondarySystemBackground)

  // Context Management
  var contextString: String?
  @Binding var isPresented: Bool

  @State private var showContextSheet = false
  @ObservedObject var insuranceService = InsuranceService.shared
  @State private var selectedContextProduct: InsuranceProduct?

  var body: some View {
    VStack(spacing: 0) {
      // Custom Header
      HStack {
        Button(action: {
          isPresented = false
        }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.black)
            .padding(12)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }

        Spacer()

        VStack(spacing: 2) {
          Text("PetWell Assistant")
            .font(.headline)
            .foregroundColor(.black)
          if let product = selectedContextProduct {
            Text("Context: \(product.insuranceName)")
              .font(.caption2)
              .foregroundColor(.blue)
          }
        }

        Spacer()

        // Placeholder for symmetry or menu
        Color.clear.frame(width: 44, height: 44)
      }
      .padding(.horizontal)
      .padding(.top, 16)  // Safe area adjustment if needed, usually handled by background
      .padding(.bottom, 8)
      .background(Color(UIColor.systemBackground))

      // Chat Area
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 20) {  // Increased spacing
            // Error Display
            if let error = ragService.errorMessage {
              Text("Error: \(error)")
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            ForEach(ragService.messages) { message in
              HStack(alignment: .bottom, spacing: 8) {
                if message.isUser {
                  Spacer()
                  Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleColorUser)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                  //.cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                } else {
                  // AI Avatar
                  Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                      LinearGradient(
                        colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing
                      )
                    )
                    .clipShape(Circle())

                  Text(message.content)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleColorAI)
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                  //.cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                  Spacer()
                }
              }
              .padding(.horizontal, 16)  // Consistent side padding
              .id(message.id)
            }

            if ragService.isLoading {
              HStack {
                ProgressView()
                  .padding(8)
                  .background(Color.white)
                  .clipShape(Circle())
                  .shadow(radius: 2)
                Spacer()
              }
              .padding(.leading, 16)
              .id("loading")
            }

            // Spacer for bottom content
            Color.clear.frame(height: 20)
              .id("bottom")
          }
          .padding(.vertical, 20)
        }
        .onChange(of: ragService.messages.count) { _ in
          withAnimation {
            proxy.scrollTo("bottom", anchor: .bottom)
          }
        }
        .onChange(of: ragService.isLoading) { loading in
          if loading {
            withAnimation {
              proxy.scrollTo("loading", anchor: .bottom)
            }
          }
        }
      }

      // Input Area
      VStack(spacing: 0) {
        Divider()
        HStack(spacing: 12) {
          // Plus Button (Context Switch)
          Button(action: {
            showContextSheet = true
          }) {
            Image(systemName: "plus")
              .font(.system(size: 20, weight: .medium))
              .foregroundColor(.gray)
              .frame(width: 40, height: 40)
              .background(Color(UIColor.secondarySystemBackground))
              .clipShape(Circle())
          }
          .sheet(isPresented: $showContextSheet) {
            ProviderSelectionView(isPresented: $showContextSheet) { selectedId in
              // Update context
              if let product = insuranceService.products.first(where: {
                $0.insuranceId == selectedId
              }) {
                selectedContextProduct = product
                // Optionally send a system message to indicate context switch?
                // Or just update the context used for next queries.
              }
            }
          }

          // Text Field
          TextField("Ask anything...", text: $question)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(24)
            .frame(minHeight: 44)

          // Mic Button (Visual Only for now)
          Button(action: {}) {
            Image(systemName: "mic")
              .font(.system(size: 20))
              .foregroundColor(.gray)
          }

          // Send/Wave Button
          Button(action: sendMessage) {
            Image(systemName: question.isEmpty ? "waveform" : "arrow.up.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.blue)  // Main Blue
          }
          .disabled(ragService.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)  // Dynamic bottom padding handles safe area usually
        .background(Color.white)

      }
    }
    .background(Color.white.ignoresSafeArea())  // Ensure full background
    .onAppear {
      if ragService.messages.isEmpty {
        let greeting = ChatMessage(
          content: "Hello, I am your insurance assistant, how can I help you?", isUser: false)
        ragService.messages.append(greeting)
      }
    }
  }

  private func sendMessage() {
    guard !question.isEmpty else { return }
    let currentQuestion = question
    question = ""

    // Construct context
    // If user selected a specific product, override the original context?
    // Or append? The original context was specific coverage term.
    // If user switches product, maybe they want to ask about THAT product generally?

    var currentContext = contextString
    if let product = selectedContextProduct {
      currentContext = "Context: Insurance Product - \(product.insuranceName)"
    }

    ragService.askQuestion(query: currentQuestion, context: currentContext)
  }
}
