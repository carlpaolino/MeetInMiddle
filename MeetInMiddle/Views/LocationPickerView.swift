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
    @StateObject private var completer = AddressCompleter()
    
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
                            .onChange(of: addressQuery) { oldValue, newValue in
                                completer.search(query: newValue)
                            }
                        
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
                    
                    // Show autocomplete suggestions in separate section
                    if !completer.suggestions.isEmpty && !addressQuery.isEmpty {
                        Section("Suggestions") {
                            ForEach(completer.suggestions, id: \.id) { suggestion in
                                Button(action: {
                                    selectSuggestion(suggestion)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suggestion.title)
                                                .foregroundColor(.primary)
                                                .font(.body)
                                                .multilineTextAlignment(.leading)
                                            if !suggestion.subtitle.isEmpty {
                                                Text(suggestion.subtitle)
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
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
    
    private func selectSuggestion(_ suggestion: AddressSuggestion) {
        addressQuery = suggestion.fullAddress
        completer.clearSuggestions()
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

// MARK: - Address Autocomplete
class AddressCompleter: NSObject, ObservableObject {
    private let completer = MKLocalSearchCompleter()
    @Published var suggestions: [AddressSuggestion] = []
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.filterType = .locationsAndQueries
    }
    
    func search(query: String) {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        completer.queryFragment = query
    }
    
    func clearSuggestions() {
        suggestions = []
    }
}

extension AddressCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(5).enumerated().map { index, result in
            AddressSuggestion(
                id: "\(result.title)-\(result.subtitle)-\(index)",
                title: result.title,
                subtitle: result.subtitle,
                fullAddress: "\(result.title)\(result.subtitle.isEmpty ? "" : ", \(result.subtitle)")"
            )
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Address completer error: \(error.localizedDescription)")
    }
}

struct AddressSuggestion: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let fullAddress: String
}

#Preview {
    LocationPickerView(
        participant: Participant(name: "John"),
        locationManager: LocationManager(),
        onSelect: { _ in }
    )
}
