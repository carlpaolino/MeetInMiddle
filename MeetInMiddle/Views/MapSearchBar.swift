//
//  MapSearchBar.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit

struct MapSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var searchCompletions: [MKLocalSearchCompletion]
    @Binding var selectedCompletion: MKLocalSearchCompletion?
    @Binding var shouldFocus: Bool
    var focusTrigger: Int
    
    @FocusState private var isFocused: Bool
    
    var onCompletionSelected: (MKLocalSearchCompletion) -> Void
    var onSearchSubmitted: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for a place or address", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        if !searchText.isEmpty {
                            onSearchSubmitted(searchText)
                        }
                    }
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.isEmpty {
                            searchCompletions = []
                        }
                    }
                    .onChange(of: shouldFocus) { oldValue, newValue in
                        if newValue {
                            // Focus with a small delay to ensure the view is ready
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                                isFocused = true
                            }
                        }
                    }
                    .onChange(of: focusTrigger) { oldValue, newValue in
                        // Focus whenever the trigger changes
                        if newValue > oldValue {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                isFocused = true
                            }
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearching = false
                        searchCompletions = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Suggestions list - show when there are completions and search text is not empty
            if !searchText.isEmpty && !searchCompletions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(searchCompletions.enumerated()), id: \.offset) { index, completion in
                            SearchCompletionRow(completion: completion)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCompletion = completion
                                    onCompletionSelected(completion)
                                    searchText = completion.title
                                    // Clear completions after selection
                                    searchCompletions = []
                                }
                            
                            if index < searchCompletions.count - 1 {
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct SearchCompletionRow: View {
    let completion: MKLocalSearchCompletion
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCompletion(completion))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(completion.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func iconForCompletion(_ completion: MKLocalSearchCompletion) -> String {
        // Determine icon based on completion type
        if completion.subtitle.contains("Airport") || completion.subtitle.contains("Airline") {
            return "airplane"
        } else if completion.subtitle.contains("Restaurant") || completion.subtitle.contains("Food") {
            return "fork.knife"
        } else if completion.subtitle.contains("Hotel") || completion.subtitle.contains("Lodging") {
            return "bed.double.fill"
        } else if completion.subtitle.contains("Gas") || completion.subtitle.contains("Fuel") {
            return "fuelpump.fill"
        } else if completion.subtitle.contains("Park") {
            return "tree.fill"
        } else if completion.subtitle.contains("School") || completion.subtitle.contains("University") {
            return "graduationcap.fill"
        } else if completion.subtitle.contains("Hospital") || completion.subtitle.contains("Medical") {
            return "cross.case.fill"
        } else if completion.subtitle.contains("Shopping") || completion.subtitle.contains("Store") {
            return "bag.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}

#Preview {
    MapSearchBar(
        searchText: .constant(""),
        isSearching: .constant(false),
        searchCompletions: .constant([]),
        selectedCompletion: .constant(nil),
        shouldFocus: .constant(false),
        focusTrigger: 0,
        onCompletionSelected: { _ in },
        onSearchSubmitted: { _ in }
    )
    .padding()
}

