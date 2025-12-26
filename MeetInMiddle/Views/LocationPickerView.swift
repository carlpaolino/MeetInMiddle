//
//  LocationPickerView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    let participant: Participant
    let locationManager: LocationManager
    let onSelect: (StartPoint) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedOption: LocationOption = .currentLocation
    @State private var addressQuery = ""
    @State private var isRequestingLocation = false
    
    enum LocationOption: String, CaseIterable {
        case currentLocation = "Current Location"
        case address = "Enter Address"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Location Type") {
                    Picker("Location Type", selection: $selectedOption) {
                        ForEach(LocationOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if selectedOption == .currentLocation {
                    Section {
                        Button(action: {
                            requestCurrentLocation()
                        }) {
                            HStack {
                                if isRequestingLocation {
                                    ProgressView()
                                }
                                Text("Use Current Location")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isRequestingLocation)
                    }
                } else {
                    Section("Enter Address") {
                        TextField("Address", text: $addressQuery)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button(action: {
                            if !addressQuery.isEmpty {
                                onSelect(.address(query: addressQuery))
                                dismiss()
                            }
                        }) {
                            Text("Use Address")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(addressQuery.isEmpty)
                    }
                }
            }
            .navigationTitle("Set Location for \(participant.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func requestCurrentLocation() {
        isRequestingLocation = true
        
        Task {
            do {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestLocationPermission()
                    // Wait a bit for permission dialog
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                
                let coordinate = try await locationManager.getCurrentLocation()
                onSelect(.coordinate(lat: coordinate.latitude, lon: coordinate.longitude, label: "Current Location"))
                dismiss()
            } catch {
                // Handle error
                print("Error getting location: \(error)")
            }
            isRequestingLocation = false
        }
    }
}

#Preview {
    LocationPickerView(
        participant: Participant(name: "John"),
        locationManager: LocationManager(),
        onSelect: { _ in }
    )
}

