//
//  RankingService.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import Foundation
import CoreLocation

class RankingService {
    static let shared = RankingService()
    
    private init() {}
    
    // Weights from PRD: w1=0.45 (fairness), w2=0.35 (total time), w3=0.20 (profile match), w4=0 (rating)
    private let fairnessWeight: Double = 0.45
    private let totalTimeWeight: Double = 0.35
    private let profileMatchWeight: Double = 0.20
    private let ratingWeight: Double = 0.0 // Not available in MVP
    
    func calculateScore(
        travelTimes: [TimeInterval],
        profileMatch: Double,
        rating: Double = 0.0
    ) -> (fairness: Double, totalTime: TimeInterval, combinedScore: Double) {
        guard !travelTimes.isEmpty else {
            return (fairness: Double.infinity, totalTime: 0, combinedScore: Double.infinity)
        }
        
        let maxTime = travelTimes.max() ?? 0
        let minTime = travelTimes.min() ?? 0
        let fairness = maxTime - minTime // Lower is better
        let totalTime = travelTimes.reduce(0, +)
        
        // Normalize scores (lower is better for all)
        // We'll normalize against reasonable max values
        let maxFairness = 3600.0 // 1 hour difference
        let maxTotalTime = 14400.0 // 4 hours total (for 2 people)
        
        let normalizedFairness = min(fairness / maxFairness, 1.0)
        let normalizedTotalTime = min(totalTime / maxTotalTime, 1.0)
        let normalizedProfileMatch = 1.0 - (profileMatch / 100.0) // Invert: lower is better
        let normalizedRating = 1.0 - (rating / 5.0) // Assuming 5-star rating
        
        let combinedScore = (fairnessWeight * normalizedFairness) +
                           (totalTimeWeight * normalizedTotalTime) +
                           (profileMatchWeight * normalizedProfileMatch) +
                           (ratingWeight * normalizedRating)
        
        return (fairness: fairness, totalTime: totalTime, combinedScore: combinedScore)
    }
    
    func calculateProfileMatch(
        place: Place,
        category: PlaceCategory,
        preferences: Preferences
    ) -> Double {
        var score: Double = 0.0
        var maxScore: Double = 0.0
        
        let placeName = place.name.lowercased()
        let placeAddress = (place.address ?? "").lowercased()
        let placeText = "\(placeName) \(placeAddress)"
        
        // Food type matching (for restaurants/cafes)
        if category == .restaurant || category == .cafe {
            maxScore += 50.0
            for foodType in preferences.foodTypes {
                if placeText.contains(foodType.lowercased()) {
                    score += 50.0 / Double(max(preferences.foodTypes.count, 1))
                }
            }
        }
        
        // Activity type matching
        if category == .activity {
            maxScore += 50.0
            for activityType in preferences.activityTypes {
                if placeText.contains(activityType.lowercased()) {
                    score += 50.0 / Double(max(preferences.activityTypes.count, 1))
                }
            }
        }
        
        // Base relevance score (all places get some score)
        maxScore += 50.0
        score += 50.0
        
        // Normalize to 0-100
        if maxScore > 0 {
            return min((score / maxScore) * 100.0, 100.0)
        }
        
        return 50.0 // Default match score
    }
    
    func rankPlaces(
        places: [Place],
        participants: [Participant],
        resolvedCoordinates: [UUID: CLLocationCoordinate2D],
        mode: TravelMode,
        category: PlaceCategory,
        userProfile: UserProfile
    ) async -> [PlaceScore] {
        var scores: [PlaceScore] = []
        
        for place in places {
            // Get travel times for all participants
            var travelTimes: [UUID: TimeInterval] = [:]
            
            for participant in participants {
                guard let startCoord = resolvedCoordinates[participant.id] else {
                    continue
                }
                
                do {
                    let time = try await RoutingService.shared.getTravelTime(
                        from: startCoord,
                        to: place.coordinate,
                        mode: mode
                    )
                    travelTimes[participant.id] = time
                } catch {
                    // Skip if routing fails
                    continue
                }
            }
            
            guard !travelTimes.isEmpty else {
                continue
            }
            
            // Calculate profile match
            let profileMatch = calculateProfileMatch(
                place: place,
                category: category,
                preferences: userProfile.preferences
            )
            
            // Calculate scores
            let timeValues = Array(travelTimes.values)
            let (fairness, totalTime, combinedScore) = calculateScore(
                travelTimes: timeValues,
                profileMatch: profileMatch
            )
            
            let placeScore = PlaceScore(
                place: place,
                travelTimes: travelTimes,
                fairnessScore: fairness,
                totalTravelTime: totalTime,
                profileMatch: profileMatch,
                combinedScore: combinedScore
            )
            
            scores.append(placeScore)
        }
        
        // Sort by combined score (lower is better)
        return scores.sorted { $0.combinedScore < $1.combinedScore }
    }
}

