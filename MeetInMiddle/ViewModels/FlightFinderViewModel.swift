//
//  FlightFinderViewModel.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct FlightLocation: Identifiable, Equatable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
    
    static func == (lhs: FlightLocation, rhs: FlightLocation) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class FlightFinderViewModel: NSObject, ObservableObject {
    @Published var locations: [FlightLocation] = []
    @Published var searchQuery: String = ""
    @Published var searchCompletions: [MKLocalSearchCompletion] = []
    @Published var airports: [Place] = []
    @Published var midpoint: CLLocationCoordinate2D?
    @Published var isLoading: Bool = false
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    @Published var selectedAirport: Place?
    @Published var searchRadius: Double = 500000 // 500km default
    @Published var address1: MKMapItem?
    @Published var address2: MKMapItem?
    
    let locationManager: LocationManager
    private let searchCompleter = MKLocalSearchCompleter()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init()
        setupSearchCompleter()
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest, .query]
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            searchCompletions = []
        } else {
            searchCompleter.queryFragment = query
        }
    }
    
    func addLocation(from completion: MKLocalSearchCompletion) async {
        do {
            let request = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            guard let mapItem = response.mapItems.first else {
                errorMessage = "Could not find location"
                return
            }
            
            let coordinate = mapItem.placemark.coordinate
            let name = mapItem.name ?? completion.title
            
            let location = FlightLocation(name: name, coordinate: coordinate)
            locations.append(location)
            searchQuery = ""
            searchCompletions = []
            
            // Recalculate midpoint and search airports
            await calculateMidpointAndSearchAirports()
        } catch {
            errorMessage = "Failed to add location: \(error.localizedDescription)"
        }
    }
    
    func addCurrentLocation() async {
        do {
            let coordinate = try await locationManager.getCurrentLocation()
            let location = FlightLocation(name: "Current Location", coordinate: coordinate)
            locations.append(location)
            await calculateMidpointAndSearchAirports()
        } catch {
            errorMessage = "Failed to get current location: \(error.localizedDescription)"
        }
    }
    
    func removeLocation(_ location: FlightLocation) {
        locations.removeAll { $0.id == location.id }
        Task {
            await calculateMidpointAndSearchAirports()
        }
    }
    
    func calculateMidpointAndSearchAirports() async {
        guard !locations.isEmpty else {
            midpoint = nil
            airports = []
            return
        }
        
        // Calculate midpoint
        let coordinates = locations.map { $0.coordinate }
        let sumLat = coordinates.reduce(0) { $0 + $1.latitude }
        let sumLon = coordinates.reduce(0) { $0 + $1.longitude }
        let calculatedMidpoint = CLLocationCoordinate2D(
            latitude: sumLat / Double(coordinates.count),
            longitude: sumLon / Double(coordinates.count)
        )
        midpoint = calculatedMidpoint
        
        // Search for airports
        await searchAirports()
    }
    
    func searchAirports() async {
        guard let midpoint = midpoint else {
            airports = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let foundAirports = try await PlaceSearchService.shared.searchAirports(
                near: midpoint,
                radius: searchRadius
            )
            airports = foundAirports
        } catch {
            errorMessage = "Failed to search airports: \(error.localizedDescription)"
        }
    }
    
    func openInMaps(_ place: Place) {
        place.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    func distanceFromMidpoint(to airport: Place) -> Double? {
        guard let midpoint = midpoint else { return nil }
        let airportLocation = CLLocation(latitude: airport.coordinate.latitude, longitude: airport.coordinate.longitude)
        let midpointLocation = CLLocation(latitude: midpoint.latitude, longitude: midpoint.longitude)
        return airportLocation.distance(from: midpointLocation) / 1000 // Convert to km
    }
}

extension FlightFinderViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            searchCompletions = completer.results.prefix(10).map { $0 }
            isSearching = false
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Search completer error: \(error.localizedDescription)")
            searchCompletions = []
            isSearching = false
        }
    }
}

