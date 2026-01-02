//
//  PlaceDetailSheet.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlaceDetailSheet: View {
    let mapItem: MKMapItem
    let userLocation: CLLocationCoordinate2D?
    let address1: MKMapItem?
    let address2: MKMapItem?
    let onSetAsAddress1: () -> Void
    let onSetAsAddress2: () -> Void
    let onDismiss: () -> Void
    
    @State private var distance: CLLocationDistance?
    @State private var formattedAddress: String = ""
    @State private var isSettingAddress1 = false
    @State private var isSettingAddress2 = false
    
    private var isCurrentAddress1: Bool {
        guard let addr1 = address1 else { return false }
        let coord1 = addr1.placemark.coordinate
        let coord2 = mapItem.placemark.coordinate
        return abs(coord1.latitude - coord2.latitude) < 0.0001 && abs(coord1.longitude - coord2.longitude) < 0.0001
    }
    
    private var isCurrentAddress2: Bool {
        guard let addr2 = address2 else { return false }
        let coord1 = addr2.placemark.coordinate
        let coord2 = mapItem.placemark.coordinate
        return abs(coord1.latitude - coord2.latitude) < 0.0001 && abs(coord1.longitude - coord2.longitude) < 0.0001
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar with dismiss
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Place name
                    Text(mapItem.name ?? "Unknown Place")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Address
                    if !formattedAddress.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(formattedAddress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Distance
                    if let distance = distance, let userLocation = userLocation {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(formatDistance(distance))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Phone number if available
                    if let phoneNumber = mapItem.phoneNumber {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text(phoneNumber)
                                .font(.subheadline)
                            Spacer()
                            Button(action: {
                                if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Call")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Website if available
                    if let url = mapItem.url {
                        HStack(spacing: 8) {
                            Image(systemName: "safari.fill")
                                .foregroundColor(.blue)
                            Text(url.host ?? url.absoluteString)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                Text("Open")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isSettingAddress1 = true
                            }
                            onSetAsAddress1()
                        }) {
                            HStack {
                                if isSettingAddress1 {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: isCurrentAddress1 ? "checkmark.circle.fill" : "1.circle.fill")
                                        .font(.title3)
                                }
                                
                                if isCurrentAddress1 {
                                    Text("Current Address 1")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Set as Address 1")
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                if isCurrentAddress1 {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                isCurrentAddress1
                                    ? Color.green
                                    : Color.accentColor
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSettingAddress1 || isCurrentAddress1)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isSettingAddress2 = true
                            }
                            onSetAsAddress2()
                        }) {
                            HStack {
                                if isSettingAddress2 {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: isCurrentAddress2 ? "checkmark.circle.fill" : "2.circle.fill")
                                        .font(.title3)
                                }
                                
                                if isCurrentAddress2 {
                                    Text("Current Address 2")
                                        .fontWeight(.semibold)
                                } else {
                                    Text("Set as Address 2")
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                if isCurrentAddress2 {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                isCurrentAddress2
                                    ? Color.green
                                    : Color.accentColor.opacity(0.8)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isSettingAddress2 || isCurrentAddress2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        .onAppear {
            calculateDistance()
            formatAddress()
        }
    }
    
    private func calculateDistance() {
        guard let userLocation = userLocation,
              let placeLocation = mapItem.placemark.location else {
            return
        }
        
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        distance = userLoc.distance(from: placeLocation)
    }
    
    private func formatAddress() {
        let placemark = mapItem.placemark
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            addressComponents.append(street)
        }
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let zip = placemark.postalCode {
            addressComponents.append(zip)
        }
        
        formattedAddress = addressComponents.joined(separator: " ")
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        if miles < 0.1 {
            return String(format: "%.2f miles away", miles)
        } else if miles < 1 {
            return String(format: "%.1f miles away", miles)
        } else {
            return String(format: "%.1f miles away", miles)
        }
    }
}

#Preview {
    let samplePlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
    let sampleMapItem = MKMapItem(placemark: samplePlacemark)
    sampleMapItem.name = "Sample Restaurant"
    
    return PlaceDetailSheet(
        mapItem: sampleMapItem,
        userLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        address1: nil,
        address2: nil,
        onSetAsAddress1: {},
        onSetAsAddress2: {},
        onDismiss: {}
    )
}

