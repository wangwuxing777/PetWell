//
//  ContentView.swift
//  PetWell
//
//  Created by 王武行 on 2025/12/24.
//

import SwiftUI
import Combine
import PhotosUI
import UIKit

enum Tab: Hashable {
  case shop, medical, insurance, profile, blog
}

enum GuideAction: String {
  case blogPostTapped
  case shopOpenedFilter
  case insuranceScrolled
  case insuranceCompareTapped
  case insuranceComparedChanged
  case medicalOpenedMap
  case profileTappedAddPet
}

struct GuideStep: Identifiable {
  let id = UUID()
  let tab: Tab
  let title: String
  let message: String
  let requiredAction: GuideAction?
}

final class GuideManager: ObservableObject {
  @Published var isActive = false
  @Published var currentIndex = 0

  private let completedKey = "hasCompletedContextualGuideV1"

  let steps: [GuideStep] = [
    GuideStep(
      tab: .blog,
      title: "Blog",
      message: "Tap the + button at the top-right to create your first post.",
      requiredAction: .blogPostTapped
    ),
    GuideStep(
      tab: .shop,
      title: "Shop · For You",
      message: "Open Filter to try the For my pet recommendation (future core feature).",
      requiredAction: .shopOpenedFilter
    ),
    GuideStep(
      tab: .insurance,
      title: "Insurance",
      message: "Scroll down to learn key insurance basics.",
      requiredAction: .insuranceScrolled
    ),
    GuideStep(
      tab: .insurance,
      title: "Insurance Compare",
      message: "Tap Compare to open side-by-side plan comparison.",
      requiredAction: .insuranceCompareTapped
    ),
    GuideStep(
      tab: .insurance,
      title: "Use Compare",
      message: "Try changing a product or switch to scenario mode to compare by case.",
      requiredAction: .insuranceComparedChanged
    ),
    GuideStep(
      tab: .medical,
      title: "Medical",
      message: "Use the clinic button at top-right to open testclinics and book a test medical service.",
      requiredAction: .medicalOpenedMap
    ),
    GuideStep(
      tab: .profile,
      title: "Profile",
      message: "Tap + to add your pet profile and complete records.",
      requiredAction: .profileTappedAddPet
    ),
  ]

  var currentStep: GuideStep? {
    guard isActive, currentIndex < steps.count else { return nil }
    return steps[currentIndex]
  }

  var progressText: String {
    "\(min(currentIndex + 1, steps.count))/\(steps.count)"
  }

  func startIfNeeded() {
    let hasCompleted = UserDefaults.standard.bool(forKey: completedKey)
    if !hasCompleted {
      isActive = true
      currentIndex = 0
    }
  }

  func skip() {
    complete()
  }

  func next() {
    guard isActive else { return }
    if currentIndex >= steps.count - 1 {
      complete()
    } else {
      currentIndex += 1
    }
  }

  func mark(_ action: GuideAction) {
    guard let step = currentStep else { return }
    guard step.requiredAction == action else { return }
    next()
  }

  func complete() {
    isActive = false
    UserDefaults.standard.set(true, forKey: completedKey)
  }

  func replay() {
    UserDefaults.standard.set(false, forKey: completedKey)
    isActive = true
    currentIndex = 0
  }
}

private struct GuideOverlayCard: View {
  let step: GuideStep
  let progressText: String
  let onSkip: () -> Void
  let onNext: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(step.title)
          .font(.headline.weight(.bold))
        Spacer()
        Text(progressText)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Text(step.message)
        .font(.subheadline)
        .foregroundColor(.secondary)

      HStack {
        Button("Skip") { onSkip() }
          .font(.subheadline.weight(.semibold))
          .foregroundColor(.secondary)

        Spacer()

        Button("Next") {
          onNext()
        }
        .font(.subheadline.weight(.bold))
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.blue, in: Capsule())
      }
    }
    .padding(16)
    .background(
      LinearGradient(
        colors: [Color.white.opacity(0.20), Color.white.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      in: RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(
          LinearGradient(
            colors: [Color.white.opacity(0.70), Color.white.opacity(0.24)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 10)
  }
}

struct ContentView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @State private var selectedTab: Tab = .blog  // Default to Blog as per request "Blog button to the first one"
  @State private var isGuardianPresented = false
  @State private var guardianButtonPosition: CGPoint = .zero
  @State private var guardianIsDragging = false
  @State private var guardianDragStartPosition: CGPoint = .zero
  @State private var guardianSuppressNextTap = false
  @StateObject private var blogService = BlogService.shared
  @StateObject private var guideManager = GuideManager()
  @ObservedObject private var forYouOrchestrator = ForYouOrchestrator.shared
  private let guardianButtonRadius: CGFloat = 28
  private let guardianButtonPadding: CGFloat = 12

  var body: some View {
    GeometryReader { geo in
      ZStack {
        TabView(selection: $selectedTab) {
          BlogView()
            .environmentObject(blogService)  // Inject service
            .environmentObject(guideManager)
            .onChange(of: selectedTab) { _, tab in
              if tab == .blog {
                Task { await blogService.fetchPosts() }
              }
            }
            .tabItem {
              Label(
                languageManager.isChinese ? "日誌" : "Blog",
                systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(Tab.blog)

          ShopView()
            .environmentObject(guideManager)
            .tabItem { Label(languageManager.isChinese ? "商店" : "Shop", systemImage: "bag") }
            .tag(Tab.shop)

          VaccineView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "醫療" : "Medical", systemImage: "cross.case")
            }
            .tag(Tab.medical)

          InsuranceView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "保險" : "Insurance", systemImage: "shield")
            }
            .tag(Tab.insurance)

          RecordsView()
            .environmentObject(guideManager)
            .tabItem {
              Label(languageManager.isChinese ? "檔案" : "Profile", systemImage: "person.circle")
            }
            .tag(Tab.profile)
        }

        // Floating PetWell Guardian button (draggable)
        ZStack(alignment: .topTrailing) {
          Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .padding(14)
            .background(Circle().fill(Color.accentColor))
            .shadow(radius: 6)

          // Red dot: ForYou recommendation ready
          if forYouOrchestrator.hasNewResult {
            Circle()
              .fill(Color.red)
              .frame(width: 12, height: 12)
              .overlay(Circle().stroke(Color.white, lineWidth: 2))
              .offset(x: 2, y: -2)
              .transition(.scale.combined(with: .opacity))
          }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: forYouOrchestrator.hasNewResult)
        .accessibilityLabel(forYouOrchestrator.hasNewResult
          ? "PetWell Guardian — Insurance recommendation ready"
          : "PetWell Guardian")
        .contentShape(Circle())
        .onTapGesture {
          if guardianSuppressNextTap {
            guardianSuppressNextTap = false
            return
          }
          if !guardianIsDragging {
            isGuardianPresented = true
          }
        }
        .position(
          x: clampedGuardianX(guardianButtonPosition.x, in: geo.size),
          y: clampedGuardianY(guardianButtonPosition.y, in: geo.size)
        )
        .highPriorityGesture(
          DragGesture(minimumDistance: 1)
            .onChanged { value in
              if !guardianIsDragging {
                guardianDragStartPosition = guardianButtonPosition
                guardianIsDragging = true
              }

              let movedDistance = abs(value.translation.width) + abs(value.translation.height)
              if movedDistance > 4 {
                guardianSuppressNextTap = true
              }

              guardianButtonPosition = CGPoint(
                x: clampedGuardianX(
                  guardianDragStartPosition.x + value.translation.width,
                  in: geo.size
                ),
                y: clampedGuardianY(
                  guardianDragStartPosition.y + value.translation.height,
                  in: geo.size
                )
              )
            }
            .onEnded { value in
              let droppedX = clampedGuardianX(
                guardianDragStartPosition.x + value.translation.width,
                in: geo.size
              )
              let droppedY = clampedGuardianY(
                guardianDragStartPosition.y + value.translation.height,
                in: geo.size
              )
              let predictedX = clampedGuardianX(
                guardianDragStartPosition.x + value.predictedEndTranslation.width,
                in: geo.size
              )

              // Keep Y fixed immediately; animate only horizontal snap.
              guardianButtonPosition = CGPoint(x: droppedX, y: droppedY)
              withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.82)) {
                guardianButtonPosition.x = snappedGuardianX(
                  from: droppedX,
                  predictedX: predictedX,
                  in: geo.size
                )
              }
              guardianIsDragging = false
            }
        )
        .onAppear {
          // Set default position (bottom-right) once
          if guardianButtonPosition == .zero {
            let padding: CGFloat = 18
            guardianButtonPosition = CGPoint(
              x: geo.size.width - guardianButtonRadius - padding,
              y: geo.size.height - guardianButtonRadius - padding
            )
          }
        }

      }
    }
    .sheet(isPresented: $isGuardianPresented) {
      if forYouOrchestrator.hasNewResult, let result = forYouOrchestrator.latestResult {
        // ForYou result available → open Insurance chat with recommendation pre-filled
        RAGChatView(
          contextString: result.enrichedContext,
          initialModel: .insurance,
          initialAIMessage: result.initialAIMessage,
          isPresented: $isGuardianPresented
        )
        .onDisappear { forYouOrchestrator.clearResult() }
      } else {
        // Standard Guardian → Medical assistant
        RAGChatView(
          contextString: languageManager.isChinese ? "寵物醫療諮詢" : "Pet medical consultation",
          initialModel: .medical,
          isPresented: $isGuardianPresented
        )
      }
    }
  }

  private func clampedGuardianX(_ x: CGFloat, in size: CGSize) -> CGFloat {
    min(
      max(x, guardianButtonRadius + guardianButtonPadding),
      size.width - guardianButtonRadius - guardianButtonPadding
    )
  }

  private func clampedGuardianY(_ y: CGFloat, in size: CGSize) -> CGFloat {
    min(
      max(y, guardianButtonRadius + guardianButtonPadding),
      size.height - guardianButtonRadius - guardianButtonPadding
    )
  }

  private func snappedGuardianX(from currentX: CGFloat, predictedX: CGFloat, in size: CGSize) -> CGFloat {
    let leftX = guardianButtonRadius + guardianButtonPadding
    let rightX = size.width - guardianButtonRadius - guardianButtonPadding
    let inertiaX = predictedX - currentX
    if abs(inertiaX) > 24 {
      return inertiaX > 0 ? rightX : leftX
    }

    let distanceToLeft = abs(currentX - leftX)
    let distanceToRight = abs(currentX - rightX)
    return distanceToLeft <= distanceToRight ? leftX : rightX
  }
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



#Preview {
  ContentView()
}

// MARK: - Blog

struct BlogPost: Identifiable {
  let id = UUID()
  let authorName: String
  let authorAvatar: String  // SF Symbol or Image name
  let title: String
  let imageColor: Color  // Placeholder for image
  let imageHeight: CGFloat  // For masonry layout
  let likes: Int
  let isLiked: Bool
}

// Consolidated Blog logic mapping service models to UI
struct BlogView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var blogService: BlogService  // Injected service
  @EnvironmentObject var guideManager: GuideManager
  @State private var showingPostSheet = false

  // User Switcher UI Helper
  private var currentUserText: String {
    if let user = blogService.currentUser {
      return "User: \(user.name)"
    } else {
      return "Guest (Tap to Login)"
    }
  }

  // Helper to convert model to legacy BlogPost struct if needed or just use logic directly.
  // Simplifying to use Service data directly mapping to UI.

  var leftColumn: [BlogPostModel] {
    blogService.posts.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
  }

  var rightColumn: [BlogPostModel] {
    blogService.posts.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Top Custom Navigation Bar
        HStack(spacing: 20) {

          Spacer()

          Text(languageManager.isChinese ? "關注" : "Following")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.gray)

          VStack(spacing: 4) {
            Text(languageManager.isChinese ? "探索" : "Explore")
              .font(.system(size: 17, weight: .bold))
              .foregroundColor(AppTheme.textPrimary)

            RoundedRectangle(cornerRadius: 2)
              .fill(Color.blue)
              .frame(width: 30, height: 3)
          }

          Text(languageManager.isChinese ? "附近" : "Nearby")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.gray)

          Spacer()

          Button(action: {
            Task {
              if blogService.currentUser == nil {
                await blogService.registerUser(name: "Dev A")
              }
              showingPostSheet = true
              guideManager.mark(.blogPostTapped)
            }
          }) {
            Image(systemName: "plus.square")
              .font(.system(size: 22))
              .foregroundColor(AppTheme.textPrimary)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(AppTheme.bgElevated)

        // Content
        ScrollView {
          HStack(alignment: .top, spacing: 10) {
            // Left Column
            LazyVStack(spacing: 10) {
              ForEach(Array(leftColumn.enumerated()), id: \.element.id) { index, post in
                NavigationLink(destination: BlogPostDetailView(post: post)) {
                  BlogCard(post: post, index: index * 2)
                }
                .buttonStyle(.plain)
              }
            }

            // Right Column
            LazyVStack(spacing: 10) {
              ForEach(Array(rightColumn.enumerated()), id: \.element.id) { index, post in
                NavigationLink(destination: BlogPostDetailView(post: post)) {
                  BlogCard(post: post, index: index * 2 + 1)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(10)
        }
        .accessibilityIdentifier("BlogFeedView")
        .refreshable {
          await blogService.fetchPosts()
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showingPostSheet) {
        PostBlogView()
          .environmentObject(blogService)
      }
    }
    .task {
      // Initial fetch
      await blogService.fetchPosts()
    }
  }
}

struct BlogCard: View {
  let post: BlogPostModel
  let index: Int

  // Helper to produce color from string
  var imageColor: Color {
    switch post.imageColor {
    case "mint": return .mint
    case "orange": return .orange
    case "pink": return .pink
    case "yellow": return .yellow
    case "green": return .green
    default: return .blue
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Image area — show real image if available, otherwise color placeholder
      if let firstUrl = post.imageUrls?.first, let url = URL(string: firstUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image.resizable().scaledToFill()
              .frame(height: 180)
              .clipped()
          case .failure:
            Rectangle().fill(imageColor).frame(height: 180)
              .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.5)).font(.largeTitle))
          default:
            Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 180)
              .overlay(ProgressView())
          }
        }
      } else {
        Rectangle()
          .fill(imageColor)
          .frame(height: 180)
          .overlay(
            Image(systemName: "photo")
              .foregroundColor(.white.opacity(0.5))
              .font(.largeTitle)
          )
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(post.title)
          .font(.system(size: 14, weight: .medium))
          .lineLimit(2)
          .foregroundColor(AppTheme.textPrimary)
          .accessibilityIdentifier("BlogPostTitle_\(index)")

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
            Image(systemName: "heart")
              .font(.system(size: 12))
              .foregroundColor(.gray)

            Text("\(post.likes)")
              .font(.system(size: 10))
              .foregroundColor(.gray)
          }
        }
      }
      .padding(8)
      .background(AppTheme.bgCard)
    }
    .cornerRadius(8)
    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    .accessibilityIdentifier("BlogPostCell_\(index)")
  }
}

// Ensure PostBlogView is kept or updated if needed, heavily simplified for this request as we focus on list display
struct PostBlogView: View {
  @EnvironmentObject var languageManager: LanguageManager
  @EnvironmentObject var blogService: BlogService
  @Environment(\.dismiss) var dismiss
  @State private var title = ""
  @State private var content = ""

  // Image Picker State
  @State private var photoItems: [PhotosPickerItem] = []
  @State private var selectedImages: [UIImage] = []
  @State private var isShowingImagePicker = false

  // Tags State
  @State private var showTagsSheet = false
  @State private var selectedTopics: [BlogTopic] = []
  @State private var selectedUsers: [BlogUser] = []

  var body: some View {
    VStack(spacing: 0) {
      // Custom Header
      HStack {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 20))
            .foregroundColor(AppTheme.textPrimary)
        }
        Spacer()
      }
      .padding(.horizontal)
      .padding(.top, 16)
      .padding(.bottom, 8)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {

          // Image Selection Area with PhotosPicker
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              // Add Photo Button
              PhotosPicker(
                selection: $photoItems,
                maxSelectionCount: 10,
                matching: .images
              ) {
                VStack {
                  Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                  Text(languageManager.isChinese ? "添加相片" : "Add Photo")
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
              }

              // Selected Images Preview
              ForEach(selectedImages.indices, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                  Image(uiImage: selectedImages[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(12)

                  // Delete Button
                  Button(action: {
                    selectedImages.remove(at: index)
                    if index < photoItems.count {
                      photoItems.remove(at: index)
                    }
                  }) {
                    Image(systemName: "xmark.circle.fill")
                      .font(.system(size: 20))
                      .foregroundColor(.white)
                      .background(Circle().fill(Color.black.opacity(0.5)))
                  }
                  .offset(x: 8, y: -8)
                }
              }
            }
            .padding(.horizontal)
          }
          .onChange(of: photoItems) { _, newItems in
            // Load images from selected items
            selectedImages.removeAll()
            for item in newItems {
              Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                  await MainActor.run {
                    selectedImages.append(image)
                  }
                }
              }
            }
          }

          // Title Input
          TextField(languageManager.isChinese ? "加入標題" : "Add a title", text: $title)
            .font(.system(size: 20, weight: .bold))  // Larger font for title
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
              .scrollContentBackground(.hidden)  // Remove default background
          }
          .padding(.horizontal)

          // Tags Row
          HStack(spacing: 12) {
            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "number", text: languageManager.isChinese ? "話題" : "Topic")
            }

            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "at", text: languageManager.isChinese ? "用戶" : "User")
            }

            Button {
              showTagsSheet = true
            } label: {
              TagButton(icon: "chart.bar", text: languageManager.isChinese ? "投票" : "Poll")
            }
          }
          .padding(.horizontal)
          .sheet(isPresented: $showTagsSheet) {
            BlogTagsView(isPresented: $showTagsSheet)
          }

          Divider()

          // Options List
          VStack(spacing: 0) {
            OptionRow(
              icon: "mappin.and.ellipse", text: languageManager.isChinese ? "加入地點" : "Tag Location",
              detail: languageManager.isChinese ? "香港公園" : "Hong Kong Park")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "lock.open", text: languageManager.isChinese ? "公開" : "Public",
              detail: languageManager.isChinese ? "所有人" : "Everyone")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "square.grid.2x2", text: languageManager.isChinese ? "加入小工具" : "Add widgets",
              detail: "")
            Divider().padding(.leading, 40)
            OptionRow(
              icon: "gearshape", text: languageManager.isChinese ? "進階設定" : "Advanced options",
              detail: "")
          }
          .padding(.horizontal)
        }
        .padding(.bottom, 100)  // Space for bottom bar
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
              .foregroundColor(AppTheme.textPrimary)
              .padding(.vertical, 12)
              .padding(.horizontal, 24)
              .background(AppTheme.bgInput)
              .cornerRadius(24)
          }

          Spacer()

          Button(action: {
            Task {
              await blogService.createPost(title: title, content: content, images: selectedImages)
              dismiss()
            }
          }) {
            Text(languageManager.isChinese ? "發布" : "Post")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(AppTheme.textInverse)
              .padding(.vertical, 12)
              .padding(.horizontal, 48)
              .background(AppTheme.brandPrimary)
              .cornerRadius(24)
          }
        }
        .padding()
      }
      .background(AppTheme.bgElevated)
    }
  }
}

// MARK: - Blog Post Detail

struct BlogPostDetailView: View {
  let post: BlogPostModel
  @State private var isLiked = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {

        // Author row
        HStack(spacing: 10) {
          Image(systemName: post.authorAvatar.isEmpty ? "person.circle.fill" : post.authorAvatar)
            .resizable().scaledToFit()
            .frame(width: 36, height: 36)
            .foregroundColor(.gray)
          VStack(alignment: .leading, spacing: 2) {
            Text(post.authorName)
              .font(.system(size: 14, weight: .semibold))
            if let ts = post.timestamp {
              Text(ts)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
          }
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        // Image area — real images if available, color placeholder otherwise
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
          TabView {
            ForEach(imageUrls, id: \.self) { urlString in
              if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                  switch phase {
                  case .success(let image):
                    image.resizable().scaledToFill()
                      .frame(maxWidth: .infinity)
                      .frame(height: 300)
                      .clipped()
                  case .failure:
                    Rectangle().fill(cardColor).frame(height: 300)
                  default:
                    Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 300)
                      .overlay(ProgressView())
                  }
                }
              }
            }
          }
          .tabViewStyle(.page)
          .frame(height: 300)
        } else {
          Rectangle()
            .fill(cardColor)
            .frame(height: 260)
            .overlay(
              Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.5))
            )
        }

        // Title
        if !post.title.isEmpty {
          Text(post.title)
            .font(.system(size: 20, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }

        // Body
        if let body = post.content, !body.isEmpty {
          Text(body)
            .font(.system(size: 15))
            .foregroundColor(.primary.opacity(0.85))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }

        // Like button
        HStack(spacing: 6) {
          Button { isLiked.toggle() } label: {
            Image(systemName: isLiked ? "heart.fill" : "heart")
              .foregroundColor(isLiked ? .red : .gray)
          }
          Text("\(post.likes + (isLiked ? 1 : 0))")
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 40)
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var cardColor: Color {
    switch post.imageColor {
    case "mint": return .mint
    case "orange": return .orange
    case "pink": return .pink
    case "yellow": return .yellow
    case "green": return .green
    default: return .blue
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
    .foregroundColor(AppTheme.textPrimary)
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
        .foregroundColor(AppTheme.textPrimary)

      Text(text)
        .foregroundColor(AppTheme.textPrimary)

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
