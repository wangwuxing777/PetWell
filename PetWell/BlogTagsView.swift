//
//  BlogTagsView.swift
//  PetWell
//
//  Created by Frontend Engineer on 2026/03/04.
//

import SwiftUI

struct BlogTagsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool

    @State private var selectedTab: TagType = .topic
    @State private var searchText: String = ""
    @State private var topics: [BlogTopic] = []
    @State private var users: [BlogUser] = []
    @State private var selectedTopics: [BlogTopic] = []
    @State private var selectedUsers: [BlogUser] = []
    @State private var pollQuestion: String = ""
    @State private var pollOptions: [String] = ["", ""]
    @State private var isLoading = false

    enum TagType: String, CaseIterable {
        case topic = "Topic"
        case user = "User"
        case poll = "Poll"

        var displayName: String {
            rawValue
        }

        var icon: String {
            switch self {
            case .topic: return "number"
            case .user: return "at"
            case .poll: return "chart.bar"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar (for Topic and User)
                if selectedTab != .poll {
                    searchBar
                }

                // Tab Picker
                tabPicker

                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    switch selectedTab {
                    case .topic:
                        topicList
                    case .user:
                        userList
                    case .poll:
                        pollEditor
                    }
                }
            }
            .navigationTitle(selectedTab.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.isChinese ? "取消" : "Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.isChinese ? "完成" : "Done") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(languageManager.isChinese ? "搜索..." : "Search...", text: $searchText)
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(TagType.allCases, id: \.self) { type in
                Button {
                    withAnimation {
                        selectedTab = type
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.title3)
                        Text(type.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == type ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == type ? Color.blue.opacity(0.1) : Color.clear)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Topic List
    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Selected Topics
                if !selectedTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.isChinese ? "已選擇" : "Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(selectedTopics) { topic in
                                SelectedTopicChip(topic: topic) {
                                    selectedTopics.removeAll { $0.id == topic.id }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Divider()
                        .padding(.vertical, 8)
                }

                // Available Topics
                ForEach(filteredTopics) { topic in
                    TopicRow(topic: topic, isSelected: selectedTopics.contains(where: { $0.id == topic.id })) {
                        if selectedTopics.contains(where: { $0.id == topic.id }) {
                            selectedTopics.removeAll { $0.id == topic.id }
                        } else {
                            selectedTopics.append(topic)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - User List
    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Selected Users
                if !selectedUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.isChinese ? "已選擇" : "Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(selectedUsers) { user in
                                SelectedUserChip(user: user) {
                                    selectedUsers.removeAll { $0.id == user.id }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Divider()
                        .padding(.vertical, 8)
                }

                // Available Users
                ForEach(filteredUsers) { user in
                    UserRow(user: user, isSelected: selectedUsers.contains(where: { $0.id == user.id })) {
                        if selectedUsers.contains(where: { $0.id == user.id }) {
                            selectedUsers.removeAll { $0.id == user.id }
                        } else {
                            selectedUsers.append(user)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Poll Editor
    private var pollEditor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.isChinese ? "問題" : "Question")
                        .font(.headline)

                    TextField(languageManager.isChinese ? "輸入您的問題..." : "Enter your question...", text: $pollQuestion, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

                // Options
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.isChinese ? "選項" : "Options")
                        .font(.headline)

                    ForEach(pollOptions.indices, id: \.self) { index in
                        HStack {
                            TextField(languageManager.isChinese ? "選項 \(index + 1)" : "Option \(index + 1)", text: $pollOptions[index])
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)

                            if pollOptions.count > 2 {
                                Button {
                                    pollOptions.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    if pollOptions.count < 6 {
                        Button {
                            pollOptions.append("")
                        } label: {
                            Label(languageManager.isChinese ? "添加選項" : "Add Option", systemImage: "plus.circle")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Info
                Text(languageManager.isChinese ? "最多6個選項，投票發布後無法修改" : "Up to 6 options, poll cannot be edited after posting")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Computed Properties
    private var filteredTopics: [BlogTopic] {
        if searchText.isEmpty { return topics }
        return topics.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredUsers: [BlogUser] {
        if searchText.isEmpty { return users }
        return users.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Actions
    private func loadData() {
        isLoading = true

        // Mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            topics = BlogTopic.mockData
            users = BlogUser.mockData
            isLoading = false
        }
    }
}

// MARK: - Topic Row
private struct TopicRow: View {
    let topic: BlogTopic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(topic.name)")
                        .font(.headline)
                    if topic.postCount > 0 {
                        Text("\(topic.postCount) posts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Selected Topic Chip
private struct SelectedTopicChip: View {
    let topic: BlogTopic
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(topic.name)")
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(16)
    }
}

// MARK: - User Row
private struct UserRow: View {
    let user: BlogUser
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)
                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Selected User Chip
private struct SelectedUserChip: View {
    let user: BlogUser
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.caption)
            Text("@\(user.username)")
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Models
struct BlogTopic: Identifiable {
    let id: String
    let name: String
    let postCount: Int
    let trendScore: Int

    static var mockData: [BlogTopic] {
        [
            BlogTopic(id: "1", name: "寵物健康", postCount: 156, trendScore: 95),
            BlogTopic(id: "2", name: "養狗經驗", postCount: 123, trendScore: 88),
            BlogTopic(id: "3", name: "貓咪日常", postCount: 98, trendScore: 82),
            BlogTopic(id: "4", name: "寵物食品", postCount: 87, trendScore: 75),
            BlogTopic(id: "5", name: "訓練技巧", postCount: 76, trendScore: 70),
            BlogTopic(id: "6", name: "寵物美容", postCount: 65, trendScore: 65),
            BlogTopic(id: "7", name: "新手養宠", postCount: 54, trendScore: 60),
            BlogTopic(id: "8", name: "寵物保險", postCount: 43, trendScore: 55),
            BlogTopic(id: "9", name: "流浪動物", postCount: 32, trendScore: 50),
            BlogTopic(id: "10", name: "寵物活動", postCount: 21, trendScore: 45)
        ]
    }
}

struct BlogUser: Identifiable {
    let id: String
    let name: String
    let username: String
    let avatarUrl: String?
    let isFollowing: Bool

    static var mockData: [BlogUser] {
        [
            BlogUser(id: "1", name: "寵物愛好者", username: "petlover", avatarUrl: nil, isFollowing: false),
            BlogUser(id: "2", name: "狗爸媽", username: "dogparent", avatarUrl: nil, isFollowing: true),
            BlogUser(id: "3", name: "貓咪達人", username: "catlover", avatarUrl: nil, isFollowing: false),
            BlogUser(id: "4", name: "寵物訓練師", username: "pettrainer", avatarUrl: nil, isFollowing: true),
            BlogUser(id: "5", name: "獸醫小李", username: "vetli", avatarUrl: nil, isFollowing: false),
            BlogUser(id: "6", name: "寵物博主", username: "petblogger", avatarUrl: nil, isFollowing: false),
            BlogUser(id: "7", name: "毛孩媽媽", username: "fur mom", avatarUrl: nil, isFollowing: false),
            BlogUser(id: "8", name: "養宠新手", username: "newbie", avatarUrl: nil, isFollowing: false)
        ]
    }
}

// MARK: - API Service
class BlogTagService {
    // TODO: Connect to backend API
    // GET /api/topics?limit=20
    // GET /api/users/mentions?q=...

    static func fetchTopics() async -> [BlogTopic] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return BlogTopic.mockData
    }

    static func searchUsers(query: String) async -> [BlogUser] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return BlogUser.mockData.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.username.localizedCaseInsensitiveContains(query)
        }
    }
}

#Preview {
    BlogTagsView(isPresented: .constant(true))
        .environmentObject(LanguageManager())
}
