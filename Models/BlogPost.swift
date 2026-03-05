//
//  BlogPost.swift
//  PetWell
//
//  Created for Blog API integration.
//

import Foundation

// MARK: - Blog Post Model

struct BlogPost: Codable, Identifiable {
    let id: String
    let author: PostAuthor
    let content: String
    let images: [PostImage]
    let likes: Int
    let comments: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case images
        case likes
        case comments
        case createdAt = "created_at"
    }
}

// MARK: - Post Author Model

struct PostAuthor: Codable {
    let id: String
    let name: String
    let avatar: String?
}

// MARK: - Post Image Model

struct PostImage: Codable {
    let url: String
    let width: Int
    let height: Int
}

// MARK: - API Response Models

struct BlogPostsResponse: Codable {
    let posts: [BlogPost]
    let total: Int
    let page: Int
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case posts
        case total
        case page
        case perPage = "per_page"
    }
}

struct CreatePostRequest: Codable {
    let content: String
    let images: [String]
}

struct CreatePostResponse: Codable {
    let id: String
    let message: String
}

// MARK: - Mock Data for Preview

extension BlogPost {
    static var mockPosts: [BlogPost] {
        [
            BlogPost(
                id: "1",
                author: PostAuthor(
                    id: "user1",
                    name: "Alice Chen",
                    avatar: "https://example.com/avatar1.jpg"
                ),
                content: "My golden retriever loves this new park! 🐕🌳 #doglife #petwell",
                images: [
                    PostImage(
                        url: "https://example.com/image1.jpg",
                        width: 1200,
                        height: 800
                    )
                ],
                likes: 128,
                comments: 23,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            BlogPost(
                id: "2",
                author: PostAuthor(
                    id: "user2",
                    name: "Bob Wang",
                    avatar: nil
                ),
                content: "Just tried the new organic cat food. My kitty approves! 😺",
                images: [],
                likes: 45,
                comments: 8,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            BlogPost(
                id: "3",
                author: PostAuthor(
                    id: "user3",
                    name: "Carol Liu",
                    avatar: "https://example.com/avatar3.jpg"
                ),
                content: "Vaccination day! Protecting our furry friends is so important. 💉🐾",
                images: [
                    PostImage(
                        url: "https://example.com/image2.jpg",
                        width: 800,
                        height: 1200
                    ),
                    PostImage(
                        url: "https://example.com/image3.jpg",
                        width: 1200,
                        height: 800
                    )
                ],
                likes: 256,
                comments: 42,
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
    }

    static var mockPost: BlogPost {
        mockPosts[0]
    }
}

// MARK: - Date Formatter Helper

extension JSONDecoder {
    static var blogDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var blogEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
