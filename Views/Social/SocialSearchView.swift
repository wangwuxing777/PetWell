//
//  SocialSearchView.swift
//  PetWell
//
//  Created on 2026/01/23.
//

import SwiftUI

enum SearchCategory: String, CaseIterable {
    case all = "All"
    case friends = "Friends"
    case shops = "Shops"
    case clinics = "Clinics"
    
    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .friends: return "person.2"
        case .shops: return "storefront"
        case .clinics: return "cross.case"
        }
    }
}

struct SocialSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var isSearching = false
    
    // Mock data - replace with real data later
    let mockFriends = [
        SearchResult(id: "f1", name: "Emma Wilson", category: .friends, subtitle: "2 pets", icon: "person.circle.fill"),
        SearchResult(id: "f2", name: "James Chen", category: .friends, subtitle: "1 pet", icon: "person.circle.fill"),
        SearchResult(id: "f3", name: "Sophie Taylor", category: .friends, subtitle: "3 pets", icon: "person.circle.fill"),
    ]
    
    let mockShops = [
        SearchResult(id: "s1", name: "PetSmart", category: .shops, subtitle: "Pet Supplies • 0.5 mi", icon: "storefront.fill"),
        SearchResult(id: "s2", name: "Petco", category: .shops, subtitle: "Pet Supplies • 1.2 mi", icon: "storefront.fill"),
        SearchResult(id: "s3", name: "Happy Paws Shop", category: .shops, subtitle: "Pet Boutique • 0.8 mi", icon: "storefront.fill"),
    ]
    
    let mockClinics = [
        SearchResult(id: "c1", name: "VCA Animal Hospital", category: .clinics, subtitle: "24/7 Emergency • 0.3 mi", icon: "cross.case.fill"),
        SearchResult(id: "c2", name: "Banfield Pet Hospital", category: .clinics, subtitle: "Veterinary • 1.0 mi", icon: "cross.case.fill"),
        SearchResult(id: "c3", name: "Happy Tails Clinic", category: .clinics, subtitle: "Veterinary • 2.1 mi", icon: "cross.case.fill"),
    ]
    
    var allResults: [SearchResult] {
        mockFriends + mockShops + mockClinics
    }
    
    var filteredResults: [SearchResult] {
        let categoryFiltered: [SearchResult]
        switch selectedCategory {
        case .all:
            categoryFiltered = allResults
        case .friends:
            categoryFiltered = mockFriends
        case .shops:
            categoryFiltered = mockShops
        case .clinics:
            categoryFiltered = mockClinics
        }
        
        if searchText.isEmpty {
            return categoryFiltered
        }
        
        return categoryFiltered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search friends, shops, clinics...", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            categoryChip(category)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // MARK: - Results
                if filteredResults.isEmpty {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try adjusting your search or category filter")
                    }
                } else {
                    List {
                        if selectedCategory == .all {
                            // Group by category when showing all
                            if !filteredFriends.isEmpty {
                                Section("Friends") {
                                    ForEach(filteredFriends) { result in
                                        resultRow(result)
                                    }
                                }
                            }
                            
                            if !filteredShops.isEmpty {
                                Section("Shops") {
                                    ForEach(filteredShops) { result in
                                        resultRow(result)
                                    }
                                }
                            }
                            
                            if !filteredClinics.isEmpty {
                                Section("Clinics") {
                                    ForEach(filteredClinics) { result in
                                        resultRow(result)
                                    }
                                }
                            }
                        } else {
                            ForEach(filteredResults) { result in
                                resultRow(result)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredFriends: [SearchResult] {
        filteredResults.filter { $0.category == .friends }
    }
    
    private var filteredShops: [SearchResult] {
        filteredResults.filter { $0.category == .shops }
    }
    
    private var filteredClinics: [SearchResult] {
        filteredResults.filter { $0.category == .clinics }
    }
    
    private func categoryChip(_ category: SearchCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                selectedCategory == category
                    ? Color.blue
                    : Color(.secondarySystemBackground)
            )
            .foregroundStyle(selectedCategory == category ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func resultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(colorForCategory(result.category).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: result.icon)
                    .font(.title3)
                    .foregroundStyle(colorForCategory(result.category))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(result.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            actionButton(for: result)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func actionButton(for result: SearchResult) -> some View {
        switch result.category {
        case .friends:
            Button {
                // TODO: Add friend action
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(.blue)
            }
        case .shops, .clinics:
            Button {
                // TODO: View details action
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.secondary)
            }
        case .all:
            EmptyView()
        }
    }
    
    private func colorForCategory(_ category: SearchCategory) -> Color {
        switch category {
        case .all: return .gray
        case .friends: return .blue
        case .shops: return .orange
        case .clinics: return .green
        }
    }
}

// MARK: - Search Result Model
struct SearchResult: Identifiable {
    let id: String
    let name: String
    let category: SearchCategory
    let subtitle: String
    let icon: String
}

#Preview {
    SocialSearchView()
}
