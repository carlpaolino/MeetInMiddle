//
//  LocationManager.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationError: Error?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            manager.requestLocation()
            
            // Store continuation for delegate callback
            locationContinuation = continuation
        }
    }
    
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw LocationError.geocodingFailed
        }
        
        return location.coordinate
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location.coordinate
        
        if let continuation = locationContinuation {
            continuation.resume(returning: location.coordinate)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        
        if let continuation = locationContinuation {
            continuation.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

enum LocationError: LocalizedError {
    case notAuthorized
    case geocodingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location permission not granted"
        case .geocodingFailed:
            return "Could not find location for address"
        }
    }
}

