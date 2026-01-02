//
//  MapViewWrapper.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit

struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let showsUserLocation: Bool
    let userTrackingMode: MKUserTrackingMode
    let selectedLocation: CLLocationCoordinate2D?
    let onRegionChange: (MKCoordinateRegion) -> Void
    let onPOISelected: ((MKMapItem) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = userTrackingMode
        mapView.region = region
        mapView.mapType = .standard
        
        // Configure for smooth zoom like Apple Maps
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        // Enable POI display
        mapView.pointOfInterestFilter = .includingAll
        
        // Disable double-tap zoom for smoother experience (like Apple Maps)
        // We'll handle zoom only through pinch gestures for smooth zoom
        DispatchQueue.main.async {
            for gesture in mapView.gestureRecognizers ?? [] {
                if let tapGesture = gesture as? UITapGestureRecognizer,
                   tapGesture.numberOfTapsRequired == 2 {
                    // Disable double-tap zoom
                    tapGesture.isEnabled = false
                }
            }
        }
        
        // Add tap gesture to detect POI taps
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Add selected location pin if needed
        if let selectedLocation = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedLocation
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region smoothly
        if !mapView.region.center.isEqual(to: region.center) ||
           abs(mapView.region.span.latitudeDelta - region.span.latitudeDelta) > 0.0001 {
            mapView.setRegion(region, animated: true)
        }
        
        // Update user location settings
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = userTrackingMode
        
        // Update selected location annotation
        mapView.removeAnnotations(mapView.annotations.filter { $0 is MKPointAnnotation })
        if let selectedLocation = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedLocation
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        
        init(_ parent: MapViewWrapper) {
            self.parent = parent
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Check if tap hit an annotation first
            for annotation in mapView.annotations {
                if let annotationView = mapView.view(for: annotation) {
                    let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
                    let distance = sqrt(pow(point.x - annotationPoint.x, 2) + pow(point.y - annotationPoint.y, 2))
                    if distance < 44 { // ~44 points is about the size of a standard annotation
                        return // Don't process POI tap if it's an annotation
                    }
                }
            }
            
            // Calculate tap radius based on current zoom level
            // At higher zoom levels, POI icons are larger, so we need a smaller search radius
            let span = mapView.region.span
            let metersPerPoint = (span.latitudeDelta * 111000) / Double(mapView.bounds.height) // Approximate meters per point
            // Use a smaller radius (20 points) for more precise POI detection
            let tapRadiusMeters = max(15, min(50, metersPerPoint * 20)) // 20 points radius, clamped between 15-50m
            
            // Use MKLocalPointsOfInterestRequest for better POI detection (iOS 13+)
            if #available(iOS 13.0, *) {
                let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: tapRadiusMeters)
                
                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    guard let response = response,
                          !response.mapItems.isEmpty else {
                        // Fallback to regular search if POI search fails
                        self.performRegularSearch(at: coordinate, radius: tapRadiusMeters)
                        return
                    }
                    
                    // Find the closest POI to the tap location
                    let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    var closestItem: MKMapItem?
                    var closestDistance: CLLocationDistance = Double.infinity
                    
                    // Filter for actual POIs (restaurants, cafes, etc.) and find closest
                    for item in response.mapItems {
                        // Only consider items that are actual POIs
                        guard item.pointOfInterestCategory != nil,
                              let itemLocation = item.placemark.location else {
                            continue
                        }
                        
                        let distance = tapLocation.distance(from: itemLocation)
                        if distance < closestDistance {
                            closestDistance = distance
                            closestItem = item
                        }
                    }
                    
                    // If within tap radius and is a POI, consider it a POI tap
                    if let closestItem = closestItem, closestDistance < tapRadiusMeters {
                        DispatchQueue.main.async {
                            self.parent.onPOISelected?(closestItem)
                        }
                    }
                }
            } else {
                // Fallback for iOS 12 and earlier
                performRegularSearch(at: coordinate, radius: tapRadiusMeters)
            }
        }
        
        private func performRegularSearch(at coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
            // Use MKLocalSearch with a more targeted approach
            let request = MKLocalSearch.Request()
            
            // Search for common POI categories
            request.naturalLanguageQuery = "restaurant cafe bar store"
            request.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: radius / 111000 * 2,
                    longitudeDelta: radius / 111000 * 2
                )
            )
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response,
                      !response.mapItems.isEmpty else {
                    return
                }
                
                // Find the closest POI to the tap location
                let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                var closestItem: MKMapItem?
                var closestDistance: CLLocationDistance = Double.infinity
                
                for item in response.mapItems {
                    // Filter for actual POIs (restaurants, cafes, etc.)
                    if item.pointOfInterestCategory != nil,
                       let itemLocation = item.placemark.location {
                        let distance = tapLocation.distance(from: itemLocation)
                        if distance < closestDistance {
                            closestDistance = distance
                            closestItem = item
                        }
                    }
                }
                
                // If within radius and is a POI, consider it a POI tap
                if let closestItem = closestItem, closestDistance < radius {
                    DispatchQueue.main.async {
                        self.parent.onPOISelected?(closestItem)
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            parent.onRegionChange(mapView.region)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Use default user location view
            }
            
            let identifier = "SelectedLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            if let pinView = annotationView as? MKPinAnnotationView {
                pinView.pinTintColor = .red
            }
            
            return annotationView
        }
    }
}

extension CLLocationCoordinate2D {
    func isEqual(to coordinate: CLLocationCoordinate2D) -> Bool {
        abs(self.latitude - coordinate.latitude) < 0.0001 &&
        abs(self.longitude - coordinate.longitude) < 0.0001
    }
}

