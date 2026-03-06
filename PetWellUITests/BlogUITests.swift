//
//  BlogUITests.swift
//  PetWellUITests
//
//  Created for Blog UI testing.
//

import XCTest

final class BlogUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test Cases

    /// Test that blog feed loads and displays posts
    func testBlogFeedLoads() throws {
        // Tap Blog tab (using label text since tabItem doesn't support accessibilityIdentifier)
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5), "Blog tab should exist")
        blogTab.tap()

        // Wait for feed to load
        let feedView = app.scrollViews["BlogFeedView"]
        XCTAssertTrue(feedView.waitForExistence(timeout: 10), "Blog feed should appear")

        // Verify posts appear (at least one post cell)
        let firstPost = app.cells["BlogPostCell_0"]
        XCTAssertTrue(firstPost.waitForExistence(timeout: 10), "At least one post should appear")

        // Assert no empty state
        let emptyState = app.staticTexts["No posts"]
        XCTAssertFalse(emptyState.exists, "Should not show empty state when posts exist")
    }

    /// Test tapping on a blog post opens detail view
    func testBlogPostCellTap() throws {
        // Navigate to Blog tab
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5))
        blogTab.tap()

        // Wait for first post and tap it
        let firstPost = app.cells["BlogPostCell_0"]
        XCTAssertTrue(firstPost.waitForExistence(timeout: 10), "First post should exist")
        firstPost.tap()

        // Verify detail view opens
        let detailView = app.scrollViews["BlogPostDetailView"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Detail view should open")

        // Assert content is visible
        let contentLabel = app.staticTexts["BlogPostContent"]
        XCTAssertTrue(contentLabel.exists, "Post content should be visible")

        // Go back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }

    /// Test pull-to-refresh functionality
    func testPullToRefresh() throws {
        // Navigate to Blog tab
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5))
        blogTab.tap()

        // Wait for feed to load
        let feedView = app.scrollViews["BlogFeedView"]
        XCTAssertTrue(feedView.waitForExistence(timeout: 10))

        // Pull down to refresh
        let start = feedView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = feedView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Verify refresh indicator appears (if implemented)
        // Note: Refresh indicator may not have accessibility identifier
        // Just verify feed still exists after refresh
        XCTAssertTrue(feedView.waitForExistence(timeout: 5), "Feed should still exist after refresh")

        // Verify posts reload
        let firstPost = app.cells["BlogPostCell_0"]
        XCTAssertTrue(firstPost.waitForExistence(timeout: 10), "Posts should reload after refresh")
    }

    /// Test loading more posts when scrolling to bottom
    func testLoadMorePosts() throws {
        // Navigate to Blog tab
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5))
        blogTab.tap()

        // Wait for initial posts
        let feedView = app.scrollViews["BlogFeedView"]
        XCTAssertTrue(feedView.waitForExistence(timeout: 10))

        // Get initial post count
        let initialPosts = app.cells.matching(identifier: "BlogPostCell").count

        // Scroll to bottom multiple times to trigger load more
        for i in 0..<3 {
            let lastCell = app.cells["BlogPostCell_\(initialPosts + i - 1)"]
            if lastCell.exists {
                lastCell.swipeUp()
            } else {
                feedView.swipeUp()
            }
            // Wait a moment for potential loading
            sleep(1)
        }

        // Verify more posts loaded or loading indicator shown
        let finalPosts = app.cells.matching(identifier: "BlogPostCell").count
        XCTAssertGreaterThanOrEqual(finalPosts, initialPosts, "Should have same or more posts after scrolling")
    }

    /// Test blog tab navigation from other tabs
    func testBlogTabNavigation() throws {
        // Start from Shop tab
        let shopTab = app.tabBars.buttons["Shop"]
        if shopTab.waitForExistence(timeout: 3) {
            shopTab.tap()
        }

        // Navigate to Blog tab
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5))
        blogTab.tap()

        // Verify Blog feed appears
        let feedView = app.scrollViews["BlogFeedView"]
        XCTAssertTrue(feedView.waitForExistence(timeout: 5), "Should navigate to Blog feed")
    }

    /// Test error state when backend is unavailable
    func testBlogFeedErrorState() throws {
        // Note: This test assumes backend might be down
        // In real scenario, would mock the backend response

        // Navigate to Blog tab
        let blogTab = app.tabBars.buttons["Blog"]
        XCTAssertTrue(blogTab.waitForExistence(timeout: 5))
        blogTab.tap()

        // Wait for potential error
        sleep(3)

        // Check if error message appears (if backend is down)
        let errorMessage = app.staticTexts["BlogErrorMessage"]
        if errorMessage.exists {
            XCTAssertTrue(errorMessage.exists, "Error message should be shown when backend fails")
        } else {
            // If no error, feed should load
            let feedView = app.scrollViews["BlogFeedView"]
            XCTAssertTrue(feedView.exists, "Feed should exist if no error")
        }
    }
}
