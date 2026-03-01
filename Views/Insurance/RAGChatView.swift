import SwiftUI

struct RAGChatView: View {
  @StateObject var ragService = RAGService()
  @State private var question = ""

  // Design Constants
  private let bubbleColorUser = Color.blue
  private let bubbleColorAI = Color(UIColor.secondarySystemBackground)

  // Context Management
  var contextString: String?
  var initialModel: ChatModel = .insurance
  @Binding var isPresented: Bool

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // ── CHAT AREA ──
        chatScrollView

        // ── INPUT AREA ──
        inputAreaView
      }
      .background(Color.white.ignoresSafeArea())
      .navigationTitle("PetWell Assistant")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: {
            isPresented = false
          }) {
            Image(systemName: "chevron.backward")
              .font(.system(size: 17, weight: .medium))
              .foregroundColor(.black)
          }
        }
      }
    }
    .onAppear {
      ragService.selectedModel = initialModel
      if initialModel != .insurance {
        ragService.selectedProvider = .all
      }

      if ragService.messages.isEmpty {
        let greetingText =
          initialModel == .medical
          ? "Hello, I am your medical assistant, how can I help you?"
          : "Hello, I am your insurance assistant, how can I help you?"
        let greeting = ChatMessage(content: greetingText, isUser: false)
        ragService.messages.append(greeting)
      }
      ragService.createSession()
    }
  }

  // MARK: - Chat Scroll View

  private var chatScrollView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 20) {
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
            if message.isSystemNotice {
              // ── SYSTEM NOTICE (provider switch) ──
              systemNoticeView(message: message)
            } else {
              // ── CHAT BUBBLE ──
              chatBubbleView(message: message)
            }
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

          // Bottom spacer
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
  }

  // MARK: - System Notice View

  private func systemNoticeView(message: ChatMessage) -> some View {
    HStack {
      Spacer()
      HStack(spacing: 6) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.system(size: 11))
        Text(message.content)
          .font(.system(size: 12, weight: .medium))
      }
      .foregroundColor(.blue)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(Color.blue.opacity(0.08))
      .cornerRadius(16)
      Spacer()
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Chat Bubble View

  private func chatBubbleView(message: ChatMessage) -> some View {
    VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
      // Active provider badge (above AI bubbles only)
      if !message.isUser, let provider = message.activeProvider, !provider.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 10))
          Text("Based on: \(provider)")
            .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.leading, 52)  // Align with bubble (after avatar)
      }

      // Bubble
      HStack(alignment: .bottom, spacing: 8) {
        if message.isUser {
          Spacer()
          Text(LocalizedStringKey(message.content))
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(bubbleColorUser)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

          Text(LocalizedStringKey(message.content))
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(bubbleColorAI)
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
          Spacer()
        }
      }
    }
    .padding(.horizontal, 16)
    .id(message.id)
  }

  // MARK: - Input Area

  private var inputAreaView: some View {
    VStack(spacing: 0) {
      Divider()

      VStack(spacing: 10) {
        // Text Field Row
        HStack(spacing: 12) {
          TextField("Ask Anything", text: $question)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(24)
            .frame(minHeight: 44)

          // Send Button
          Button(action: sendMessage) {
            Image(systemName: question.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
              .font(.system(size: 28))
              .foregroundColor(question.isEmpty ? Color(UIColor.systemGray3) : .blue)
          }
          .disabled(ragService.isLoading || question.isEmpty)
        }

        // ── DROPDOWN PILLS ROW ──
        HStack(spacing: 10) {
          // Attachment icon (visual only)
          Image(systemName: "paperclip")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color(UIColor.systemGray2))
            .frame(width: 32, height: 32)

          // Model Selector Pill
          modelSelectorPill

          // Provider Selector Pill
          providerSelectorPill

          Spacer()
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 10)
      .padding(.bottom, 12)
      .background(Color.white)
    }
  }

  // MARK: - Model Selector Pill

  private var modelSelectorPill: some View {
    Menu {
      ForEach(ChatModel.allCases) { model in
        Button(action: {
          ragService.selectedModel = model
        }) {
          Label(model.displayName, systemImage: model.icon)
        }
      }
    } label: {
      HStack(spacing: 5) {
        Image(systemName: ragService.selectedModel.icon)
          .font(.system(size: 12, weight: .medium))
        Text(ragService.selectedModel.displayName)
          .font(.system(size: 13, weight: .medium))
        Image(systemName: "chevron.down")
          .font(.system(size: 8, weight: .bold))
      }
      .foregroundColor(.primary)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .stroke(Color(UIColor.systemGray4), lineWidth: 1)
      )
    }
  }

  // MARK: - Provider Selector Pill

  private var providerSelectorPill: some View {
    Menu {
      ForEach(ChatProviderOption.allCases) { provider in
        Button(action: {
          ragService.selectProvider(provider)
        }) {
          HStack {
            Text(provider.displayName)
            if ragService.selectedProvider == provider {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      HStack(spacing: 5) {
        Image(systemName: "shield.checkered")
          .font(.system(size: 12, weight: .medium))
        Text(
          ragService.selectedProvider == .all
            ? "Provider" : ragService.selectedProvider.displayName
        )
        .font(.system(size: 13, weight: .medium))
        Image(systemName: "chevron.down")
          .font(.system(size: 8, weight: .bold))
      }
      .foregroundColor(ragService.selectedProvider == .all ? .primary : .blue)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .stroke(
            ragService.selectedProvider == .all ? Color(UIColor.systemGray4) : Color.blue,
            lineWidth: ragService.selectedProvider == .all ? 1 : 1.5
          )
      )
    }
  }

  // MARK: - Actions

  private func sendMessage() {
    guard !question.isEmpty else { return }
    let currentQuestion = question
    question = ""

    var currentContext = contextString
    if ragService.selectedModel == .insurance && ragService.selectedProvider != .all {
      currentContext =
        "Context: Insurance Provider - \(ragService.selectedProvider.displayName)"
    }

    ragService.askQuestion(query: currentQuestion, context: currentContext)
  }
}
