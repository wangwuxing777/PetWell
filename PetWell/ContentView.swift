//
//  ContentView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedTab: Tab = .blog // Default to Blog as per request "Blog button to the first one"
    @State private var isGuardianPresented = false
    @State private var guardianButtonPosition: CGPoint = .zero
    @State private var guardianButtonDragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TabView(selection: $selectedTab) {
                    BlogView()
                        .tabItem { Label(languageManager.isChinese ? "日誌" : "Blog", systemImage: "bubble.left.and.bubble.right.fill") }
                        .tag(Tab.blog)

                    ProductsView()
                        .tabItem { Label(languageManager.isChinese ? "商店" : "Shop", systemImage: "bag") }
                        .tag(Tab.shop)

                    ClinicView()
                        .tabItem { Label(languageManager.isChinese ? "醫療" : "Medical", systemImage: "cross.case") }
                        .tag(Tab.medical)

                    InsuranceView()
                        .tabItem { Label(languageManager.isChinese ? "保險" : "Insurance", systemImage: "shield") }
                        .tag(Tab.insurance)

                    RecordsView()
                        .tabItem { Label(languageManager.isChinese ? "檔案" : "Profile", systemImage: "person.circle") }
                        .tag(Tab.profile)
                }

                // Floating PetWell Guardian button (draggable)
                Button {
                    isGuardianPresented = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 6)
                        .accessibilityLabel("PetWell Guardian")
                }
                .position(x: guardianButtonPosition.x + guardianButtonDragOffset.width,
                          y: guardianButtonPosition.y + guardianButtonDragOffset.height)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guardianButtonDragOffset = value.translation
                        }
                        .onEnded { value in
                            let buttonRadius: CGFloat = 28 // approx half of button diameter
                            let padding: CGFloat = 12

                            var newX = guardianButtonPosition.x + value.translation.width
                            var newY = guardianButtonPosition.y + value.translation.height

                            // Clamp inside the screen
                            newX = min(max(newX, buttonRadius + padding), geo.size.width - buttonRadius - padding)
                            newY = min(max(newY, buttonRadius + padding), geo.size.height - buttonRadius - padding)

                            guardianButtonPosition = CGPoint(x: newX, y: newY)
                            guardianButtonDragOffset = .zero
                        }
                )
                .onAppear {
                    // Set default position (bottom-right) once
                    if guardianButtonPosition == .zero {
                        let buttonRadius: CGFloat = 28
                        let padding: CGFloat = 18
                        guardianButtonPosition = CGPoint(
                            x: geo.size.width - buttonRadius - padding,
                            y: geo.size.height - buttonRadius - padding
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isGuardianPresented) {
            GuardianChatView()
        }
    }
}

private enum Tab: Hashable {
    case shop, medical, insurance, profile, blog
}

// MARK: - Placeholder screens (MVP stubs)

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("PetWell")
                    .font(.largeTitle).bold()

                Text("Shop (unused stub)")
                    .font(.title3)

                Text("Next: pet overview + reminders.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Shop")
        }
    }
}




private struct ClinicView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vaccination & Medical (MVP stub)")
                    .font(.title2).bold()

                Text("Next: clinic list + booking flow.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Medical")
        }
    }
}

private struct InsuranceView: View {
    var body: some View {
		InsuranceLandingView()
    }
}

private struct ProductsView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Products (MVP stub)")
                    .font(.title2).bold()

                Text("Next: health products list + details.")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Shop")
        }
    }
}


#Preview {
    ContentView()
}

// MARK: - Blog

struct BlogPost: Identifiable {
    let id = UUID()
    let authorName: String
    let authorAvatar: String // SF Symbol or Image name
    let title: String
    let imageColor: Color // Placeholder for image
    let imageHeight: CGFloat // For masonry layout
    let likes: Int
    let isLiked: Bool
}

struct BlogView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingPostSheet = false
    @State private var selectedTabStr = "Explore"
    @State private var posts: [BlogPost] = [
        BlogPost(authorName: "Sarah & Max", authorAvatar: "person.crop.circle", title: "Living with a Reactive Dog in HK", imageColor: .mint, imageHeight: 200, likes: 124, isLiked: false),
        BlogPost(authorName: "Dr. Chan", authorAvatar: "cross.fill", title: "Summer Heat Safety Tips", imageColor: .orange, imageHeight: 150, likes: 856, isLiked: true),
        BlogPost(authorName: "MeowMom99", authorAvatar: "pawprint.fill", title: "Best CWB Cat Cafes", imageColor: .pink, imageHeight: 220, likes: 42, isLiked: false),
        BlogPost(authorName: "PetLoverHK", authorAvatar: "heart.fill", title: "Weekend Hike", imageColor: .blue, imageHeight: 180, likes: 89, isLiked: false),
        BlogPost(authorName: "GoldenBoy", authorAvatar: "star.fill", title: "My new toy!", imageColor: .yellow, imageHeight: 240, likes: 1200, isLiked: true),
        BlogPost(authorName: "VetNurse_J", authorAvatar: "cross.case.fill", title: "Tick Season is here", imageColor: .green, imageHeight: 160, likes: 330, isLiked: false)
    ]
    
    // Split posts into two columns for masonry layout
    var leftColumn: [BlogPost] {
        posts.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
    }
    
    var rightColumn: [BlogPost] {
        posts.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Custom Navigation Bar
                HStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(languageManager.isChinese ? "關注" : "Following")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 4) {
                        Text(languageManager.isChinese ? "探索" : "Explore")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue)
                            .frame(width: 30, height: 3)
                    }
                    
                    Text(languageManager.isChinese ? "附近" : "Nearby")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Invisible spacer or another icon to balance the search icon if needed, 
                    // keeping simple for now
                    Button(action: {
                        showingPostSheet = true
                    }) {
                        Image(systemName: "plus.square") // Or "plus" as requested
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color.white)
                
                // Content
                ScrollView {
                    HStack(alignment: .top, spacing: 10) {
                        // Left Column
                        LazyVStack(spacing: 10) {
                            ForEach(leftColumn) { post in
                                BlogCard(post: post)
                            }
                        }
                        
                        // Right Column
                        LazyVStack(spacing: 10) {
                            ForEach(rightColumn) { post in
                                BlogCard(post: post)
                            }
                        }
                    }
            .sheet(isPresented: $showingPostSheet) {
                PostBlogView { newPost in
                    posts.insert(newPost, at: 0)
                }
            }
                    .padding(10)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct BlogCard: View {
    let post: BlogPost
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Placeholder
            Rectangle()
                .fill(post.imageColor)
                .frame(height: post.imageHeight)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.largeTitle)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.black)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: post.authorAvatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                        
                        Text(post.authorName)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundColor(post.isLiked ? .red : .gray)
                        
                        Text("\(post.likes)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Ensure PostBlogView is kept or updated if needed, heavily simplified for this request as we focus on list display
struct PostBlogView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var content = ""
    
    var onPost: (BlogPost) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Image Selection Area
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // "Add" placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                )
                            
                            // Mock selected image
                             RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.blue)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Title Input
                    TextField(languageManager.isChinese ? "加入標題" : "Add a title", text: $title)
                        .font(.system(size: 20, weight: .bold)) // Larger font for title
                        .padding(.horizontal)
                    
                    Divider().padding(.horizontal)
                    
                    // Content Input
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text(languageManager.isChinese ? "加入內文" : "Add text")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden) // Remove default background
                    }
                    .padding(.horizontal)
                    
                    // Tags Row
                    HStack(spacing: 12) {
                        TagButton(icon: "number", text: languageManager.isChinese ? "話題" : "Topic")
                        TagButton(icon: "at", text: languageManager.isChinese ? "用戶" : "User")
                        TagButton(icon: "chart.bar", text: languageManager.isChinese ? "投票" : "Poll")
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Options List
                    VStack(spacing: 0) {
                        OptionRow(icon: "mappin.and.ellipse", text: languageManager.isChinese ? "加入地點" : "Tag Location", detail: languageManager.isChinese ? "香港公園" : "Hong Kong Park")
                        Divider().padding(.leading, 40)
                        OptionRow(icon: "lock.open", text: languageManager.isChinese ? "公開" : "Public", detail: languageManager.isChinese ? "所有人" : "Everyone")
                        Divider().padding(.leading, 40)
                        OptionRow(icon: "square.grid.2x2", text: languageManager.isChinese ? "加入小工具" : "Add widgets", detail: "")
                        Divider().padding(.leading, 40)
                        OptionRow(icon: "gearshape", text: languageManager.isChinese ? "進階設定" : "Advanced options", detail: "")
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100) // Space for bottom bar
            }
            
            // Bottom Bar
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button(action: {
                        // Draft action
                    }) {
                        Text(languageManager.isChinese ? "存草稿" : "Save draft")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(24)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let newPost = BlogPost(
                            authorName: languageManager.isChinese ? "你" : "You",
                            authorAvatar: "person.circle.fill", // Mock avatar
                            title: title.isEmpty ? (languageManager.isChinese ? "新貼文" : "New Post") : title,
                            imageColor: .blue,
                            imageHeight: 200,
                            likes: 0,
                            isLiked: false
                        )
                        onPost(newPost)
                        dismiss()
                    }) {
                        Text(languageManager.isChinese ? "發布" : "Post")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 48)
                            .background(Color.blue) // Standard app blue
                            .cornerRadius(24)
                    }
                }
                .padding()
            }
            .background(Color.white)
        }
    }
}

struct TagButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 14))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .foregroundColor(.black)
    }
}

struct OptionRow: View {
    let icon: String
    let text: String
    let detail: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.black)
            
            Text(text)
                .foregroundColor(.black)
            
            Spacer()
            
            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.vertical, 16)
    }
}

