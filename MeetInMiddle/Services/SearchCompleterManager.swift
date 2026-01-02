//
//  SearchCompleterManager.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import MapKit
import Combine

@MainActor
class SearchCompleterManager: NSObject, ObservableObject {
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupSearchCompleter()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
    }
    
    func updateRegion(_ region: MKCoordinateRegion) {
        searchCompleter.region = region
    }
    
    func search(queryFragment: String) {
        guard !queryFragment.isEmpty else {
            completions = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = queryFragment
    }
    
    func clearSearch() {
        searchCompleter.queryFragment = ""
        completions = []
        isSearching = false
    }
    
    func getLocation(for completion: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems.first?.placemark.coordinate
    }
    
    func getMapItem(for completion: MKLocalSearchCompletion) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems.first
    }
}

extension SearchCompleterManager: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            completions = completer.results
            isSearching = false
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Search completer error: \(error.localizedDescription)")
            completions = []
            isSearching = false
        }
    }
}

