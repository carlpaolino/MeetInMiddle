//
//  TravelTimesSheet.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI
import MapKit

struct TravelTimesSheet: View {
    let selectedLocation: CLLocationCoordinate2D
    let userLocation: CLLocationCoordinate2D?
    let travelTimes: [TravelMode: (time: TimeInterval, distance: CLLocationDistance?)]
    let isLoading: Bool
    let locationName: String?
    let onDismiss: () -> Void
    
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
            .padding(.bottom, 12)
            
            // Location name
            if let locationName = locationName {
                Text(locationName)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            
            // Travel times
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if travelTimes.isEmpty {
                Text("No routes available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(TravelMode.allCases, id: \.self) { mode in
                            if let result = travelTimes[mode] {
                                TravelTimeRow(mode: mode, time: result.time, distance: result.distance)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .frame(maxHeight: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

struct TravelTimeRow: View {
    let mode: TravelMode
    let time: TimeInterval
    let distance: CLLocationDistance?
    
    init(mode: TravelMode, time: TimeInterval, distance: CLLocationDistance? = nil) {
        self.mode = mode
        self.time = time
        self.distance = distance
    }
    
    var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "" }
        let miles = distance / 1609.34 // Convert meters to miles
        if miles < 0.1 {
            return String(format: "%.2f mi", miles)
        } else if miles < 1 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: mode.iconName)
                .font(.title3)
                .foregroundColor(mode.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.rawValue)
                    .font(.body)
                if let distance = distance {
                    Text(formattedDistance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(formattedTime)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(12)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    TravelTimesSheet(
        selectedLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        userLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        travelTimes: [
            .drive: (time: 1200, distance: 2000),
            .walk: (time: 3600, distance: 2000),
            .bike: (time: 1800, distance: 2000),
            .bus: (time: 1500, distance: 2000)
        ],
        isLoading: false,
        locationName: "Union Square",
        onDismiss: {}
    )
}

