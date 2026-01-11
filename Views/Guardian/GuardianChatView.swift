//
//  GuardianChatView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI
import SwiftData
import UIKit

struct GuardianChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var input = ""
    @State private var chatSession: ChatSession?
    @State private var isLoadingHistory = false
    @State private var showSessions = false
    @State private var sessions: [ChatSession] = []
    enum Sender: String {
        case user
        case guardian
        case system
    }
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let sender: Sender
        let text: String
        let timestamp: Date
        
        init(sender: Sender, text: String, timestamp: Date = Date()) {
            self.sender = sender
            self.text = text
            self.timestamp = timestamp
        }
    }
    
    @State private var messages: [ChatMessage] = []
    
    @State private var isTyping = false
    @StateObject private var engine = ConsultationEngine()

    enum ChatPhase {
        case smalltalk      // default: health-related chat only
        case askConsent     // detected symptoms, ask to enter consultation
        case consult        // structured consultation
    }

    @State private var chatPhase: ChatPhase = .smalltalk

    // AI for slot extraction (DeepSeek)
    private let aiService = AIService(
        config: .init(endpoint: .deepSeek(apiKey: "sk-ca28c65dd0274a79a08ee18248aecd70"))
    )

    // MARK: - SwiftData Records
    @Query(sort: \PetModel.name) private var pets: [PetModel]

    @State private var selectedPetId: PersistentIdentifier?
    
    private var activePet: PetModel? {
        if let id = selectedPetId {
            return pets.first(where: { $0.persistentModelID == id })
        }
        return pets.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if pets.count > 1 {
                    HStack {
                        Text("Profile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Pet", selection: $selectedPetId) {
                            ForEach(pets, id: \.persistentModelID) { pet in
                                Text(pet.name).tag(Optional(pet.persistentModelID))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                            
                            if isTyping {
                                TypingBubble()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .background(Color(.systemBackground))
                    .onChange(of: messages) { _, _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { _, newValue in
                        if newValue {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                if chatPhase == .askConsent {
                    HStack(spacing: 12) {
                        Button("进入问诊模式 🩺") {
                            chatPhase = .consult
                            append(.guardian, "好的，我们开始问诊。我会像医生一样一步步了解情况。")
                        }
                        .buttonStyle(.borderedProminent)

                        Button("先不需要") {
                            chatPhase = .smalltalk
                            append(.guardian, "好的，那我们继续聊宠物健康相关的话题～")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 10) {
                    TextField("输入宠物健康问题…", text: $input, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(chatPhase == .askConsent)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(10)
                            .background(Color(.label))
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatPhase == .askConsent)
                    .opacity((input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatPhase == .askConsent) ? 0.5 : 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .onAppear {
                if selectedPetId == nil, let first = pets.first {
                    selectedPetId = first.persistentModelID
                }
                
                loadOrCreateSessionForActivePet()
                
                if let pet = activePet {
                    engine.prefillFromRecord(
                        petName: pet.name,
                        species: pet.species,
                        ageMonths: (Calendar.current.component(.year, from: Date()) - pet.birthYear) * 12,
                        weightKg: pet.weightKg
                    )
                }
            }
            .onChange(of: selectedPetId) { _, _ in
                if let pet = activePet {
                    engine.prefillFromRecord(
                        petName: pet.name,
                        species: pet.species,
                        ageMonths: (Calendar.current.component(.year, from: Date()) - pet.birthYear) * 12,
                        weightKg: pet.weightKg
                    )
                }
                loadOrCreateSessionForActivePet()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        refreshSessionsList()
                        showSessions = true
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .accessibilityLabel("Chats")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            createNewSession()
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .accessibilityLabel("New chat")
                        
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("PetWell Guardian")
                            .font(.headline)
                        Text(activePet?.name ?? "未选择宠物")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSessions) {
                NavigationStack {
                    List {
                        if sessions.isEmpty {
                            Text("No chats yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sessions, id: \.id) { s in
                                Button {
                                    loadMessages(from: s)
                                    showSessions = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Chat" : s.title)
                                            .font(.headline)
                                        Text(s.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    deleteSession(sessions[idx])
                                }
                            }
                        }
                    }
                    .navigationTitle("Chats")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showSessions = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                createNewSession()
                                showSessions = false
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("New chat")
                        }
                    }
                    .onAppear { refreshSessionsList() }
                }
            }
        }
    }
    
    private func append(_ sender: Sender, _ text: String) {
        let msg = ChatMessage(sender: sender, text: text)
        messages.append(msg)
        
        guard let session = chatSession else { return }
        let entity = ChatMessageEntity(
            senderRaw: ChatSender(from: sender).rawValue,
            text: text,
            timestamp: msg.timestamp,
            orderIndex: session.messages.count
        )
        session.messages.append(entity)
        session.updatedAt = Date()
        if sender == .user, (session.title == "New chat" || session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            session.title = String(text.prefix(24))
        }
        do {
            try modelContext.save()
        } catch {
            // Non-fatal: keep UI responsive even if persistence fails
            print("⚠️ Failed to save chat message: \(error)")
        }
    }
    
    /// Build recent chat context for session-memory chat.
    /// - Parameters:
    ///   - limit: Max number of recent UI messages to include (excluding system).
    ///   - lastUserOverride: If provided, replaces the most recent user message content (used to inject profile context).
    private func buildChatContext(limit: Int, lastUserOverride: String? = nil) -> [AIService.ChatMessageInput] {
        // Take the most recent messages in UI (user + guardian).
        var recent = Array(messages.suffix(limit))
        
        // If we just appended a user message, it should be the last one; override its content with enrichedText.
        if let override = lastUserOverride {
            if let idx = recent.lastIndex(where: { $0.sender == .user }) {
                recent[idx] = ChatMessage(sender: .user, text: override, timestamp: recent[idx].timestamp)
            } else {
                recent.append(ChatMessage(sender: .user, text: override))
            }
        }
        
        return recent.compactMap { msg in
            switch msg.sender {
            case .user:
                return .init(role: "user", content: msg.text)
            case .guardian:
                return .init(role: "assistant", content: msg.text)
            case .system:
                // We don’t persist UI system messages into the model context; ignore to avoid role confusion.
                return nil
            }
        }
    }

    private func sendMessage() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        append(.user, text)
        input = ""
        
        let profileContext = activePet?.guardianContextText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let enrichedText: String = {
            if profileContext.isEmpty { return text }
            return "PET PROFILE CONTEXT:\n\(profileContext)\n\nUSER MESSAGE:\n\(text)"
        }()
        
        isTyping = true
        
        Task {
            defer { isTyping = false }
            do {
                switch chatPhase {
                case .smalltalk:
                    let detect = try await aiService.detectSymptoms(from: text)
                    if detect.hasSymptoms {
                        chatPhase = .askConsent
                        append(.guardian, "我注意到你在描述具体症状。我可以像医生一样一步步问你一些问题，来更准确地判断情况。是否进入问诊模式？")
                    } else {
                        let context = buildChatContext(limit: 20, lastUserOverride: enrichedText)
                        let reply = try await aiService.chat(messages: context)
                        append(.guardian, reply)
                    }
                    
                case .askConsent:
                    append(.guardian, "你可以直接点上面的按钮选择是否进入问诊模式哦。")
                    
                case .consult:
                    if engine.stage == .intake {
                        engine.handleUserInput(slotKey: "chiefComplaint", value: text)
                    }
                    
                    let extraction = try await aiService.extractSlots(from: enrichedText)
                    for item in extraction.slots {
                        switch item.value {
                        case .bool(let b): engine.handleUserInput(slotKey: item.slotKey, value: b)
                        case .int(let i): engine.handleUserInput(slotKey: item.slotKey, value: i)
                        case .string(let s): engine.handleUserInput(slotKey: item.slotKey, value: s)
                        }
                    }
                    
                    let decision = engine.handleUserInput(text)
                    append(.guardian, decision.assistantText)
                }
            } catch {
                append(.guardian, "⚠️ 我有点没理解你的意思，可以换种说法吗？")
            }
        }
    }
    
    private func loadOrCreateSessionForActivePet() {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        
        let petKey = activePet?.persistentModelID.chatSessionKey ?? "none"
        
        // Fetch existing session (latest) for this petKey
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.petKey == petKey && $0.isDeleted == false },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        let existing = (try? modelContext.fetch(descriptor))?.first
        if let s = existing {
            chatSession = s
            messages = s.messages
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map {
                    let stored = ChatSender(rawValue: $0.senderRaw) ?? .guardian
                    let sender: Sender = {
                        switch stored {
                        case .user: return .user
                        case .guardian: return .guardian
                        case .system: return .system
                        }
                    }()
                    return ChatMessage(sender: sender, text: $0.text, timestamp: $0.timestamp)
                }
            if messages.isEmpty {
                seedGreetingIfNeeded()
            }
            refreshSessionsList()
            return
        }
        
        // Create new session
        let newSession = ChatSession.make(petKey: petKey)
        modelContext.insert(newSession)
        chatSession = newSession
        messages = []
        seedGreetingIfNeeded()
        
        do { try modelContext.save() } catch { print("⚠️ Failed to create chat session: \(error)") }
        refreshSessionsList()
    }
    
    private func seedGreetingIfNeeded() {
        guard messages.isEmpty else { return }
        append(.guardian, "Hi, I’m PetWell Guardian 👋\n我们可以先随便聊聊宠物健康相关的问题～")
    }

    private func refreshSessionsList() {
        let petKey = activePet?.persistentModelID.chatSessionKey ?? "none"
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.petKey == petKey && $0.isDeleted == false },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func createNewSession() {
        let petKey = activePet?.persistentModelID.chatSessionKey ?? "none"
        let session = ChatSession.make(petKey: petKey)
        modelContext.insert(session)
        chatSession = session
        messages = []
        seedGreetingIfNeeded()
        do { try modelContext.save() } catch { print("⚠️ Failed to create new chat session: \(error)") }
        refreshSessionsList()
    }

    private func deleteSession(_ session: ChatSession) {
        session.isDeleted = true
        session.updatedAt = Date()
        do { try modelContext.save() } catch { print("⚠️ Failed to delete chat session: \(error)") }

        if chatSession?.id == session.id {
            chatSession = nil
            messages = []
            loadOrCreateSessionForActivePet()
        } else {
            refreshSessionsList()
        }
    }

    private func loadMessages(from session: ChatSession) {
        chatSession = session
        messages = session.messages
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map {
                let stored = ChatSender(rawValue: $0.senderRaw) ?? .guardian
                let sender: Sender = {
                    switch stored {
                    case .user: return .user
                    case .guardian: return .guardian
                    case .system: return .system
                    }
                }()
                return ChatMessage(sender: sender, text: $0.text, timestamp: $0.timestamp)
            }
        seedGreetingIfNeeded()
    }
}

// MARK: - ChatSender Mapping
private extension ChatSender {
    init(from sender: GuardianChatView.Sender) {
        switch sender {
        case .user: self = .user
        case .guardian: self = .guardian
        case .system: self = .system
        }
    }
}

private struct MessageBubble: View {
    let message: GuardianChatView.ChatMessage
    private var isUser: Bool { message.sender == .user }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer(minLength: 0)
            }
            
            if !isUser {
                AvatarCircle(text: "G")
            }
            
            MarkdownMessageText(text: message.text)
                .foregroundStyle(.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(isUser ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = message.text
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
            
            if isUser {
                AvatarCircle(text: "You")
            }
            
            if !isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarCircle(text: "G")
            
            HStack(spacing: 6) {
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
    }
}

private struct AvatarCircle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.accentColor)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

private struct MarkdownMessageText: View {
    let text: String
    
    var body: some View {
        Group {
            if let attr = markdownAttributedString(from: text) {
                Text(attr)
                    .textSelection(.enabled)
            } else {
                Text(text)
                    .textSelection(.enabled)
            }
        }
        .font(.body)
    }
    
    private func markdownAttributedString(from text: String) -> AttributedString? {
        // Fast path: avoid markdown parsing if no common markdown tokens
        if !text.contains("```") && !text.contains("**") && !text.contains("*") && !text.contains("`") && !text.contains("#") && !text.contains("- ") && !text.contains(">") {
            return nil
        }
        
        do {
            var attr = try AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            )
            
            // Apply monospaced font to inline code and code blocks
            for run in attr.runs {
                if run.inlinePresentationIntent == .code {
                    attr[run.range].font = .system(.body, design: .monospaced)
                }
                if let intent = run.presentationIntent, intent.components.contains(where: { component in
                    if case .codeBlock = component.kind { return true }
                    return false
                }) {
                    attr[run.range].font = .system(.body, design: .monospaced)
                }
            }
            
            return attr
        } catch {
            return nil
        }
    }
}

