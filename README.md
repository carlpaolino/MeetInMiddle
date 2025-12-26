# MeetHalfway - iOS App

An iOS app that helps groups meet in the middle by computing fair travel times and recommending high-rated venues/activities that match each person's profile.

## Features

### Core Features (MVP)
- **Meet in the Middle**: Add friends/participants, set starting points, and get ranked suggestions for meeting places
- **Activity Finder**: Browse activities based on your personal profile
- **Profile Management**: Set food preferences, activity types, budget, and vibe preferences
- **Smart Ranking**: Places ranked by time fairness, total travel time, and profile match

### Key Algorithms
- Geographic midpoint calculation
- Travel time calculation using MapKit routing
- Fairness scoring (max travel time - min travel time)
- Profile-based matching for restaurants and activities

## Setup Instructions

### Prerequisites
- Xcode 16.2 or later
- iOS 18.2+ deployment target
- Apple Developer account (for running on device)

### Initial Setup

1. **Open the Project**
   ```bash
   open MeetInMiddle.xcodeproj
   ```

2. **Configure Location Permissions**
   
   The project includes an `Info.plist` file with location permission strings. However, since the project uses `GENERATE_INFOPLIST_FILE = YES`, you need to add the location permission key to the build settings:
   
   - Open the project in Xcode
   - Select the `MeetInMiddle` target
   - Go to the "Info" tab (or "Build Settings" → search for "Info.plist")
   - Add the following key-value pair:
     - Key: `NSLocationWhenInUseUsageDescription`
     - Value: `We use your location to estimate travel time and suggest nearby meeting spots.`
   
   Alternatively, you can disable `GENERATE_INFOPLIST_FILE` and use the provided `Info.plist` file directly.

3. **Configure Signing**
   - Select your development team in the "Signing & Capabilities" tab
   - Ensure the bundle identifier matches your team

4. **Build and Run**
   - Select a simulator or connected device
   - Press ⌘R to build and run

## Project Structure

```
MeetInMiddle/
├── Models/              # Data models
│   ├── Preferences.swift
│   ├── UserProfile.swift
│   ├── Participant.swift
│   ├── StartPoint.swift
│   ├── Meet.swift
│   ├── Place.swift
│   ├── TravelMode.swift
│   └── PlaceCategory.swift
├── Services/            # Business logic services
│   ├── LocationManager.swift      # CoreLocation wrapper
│   ├── PlaceSearchService.swift  # MapKit place search
│   ├── RoutingService.swift      # MKDirections routing
│   └── RankingService.swift      # Scoring and ranking
├── ViewModels/         # MVVM view models
│   ├── AppViewModel.swift
│   ├── NewMeetViewModel.swift
│   ├── ResultsViewModel.swift
│   ├── ActivityFinderViewModel.swift
│   └── ProfileViewModel.swift
├── Views/              # SwiftUI views
│   ├── HomeView.swift
│   ├── NewMeetView.swift
│   ├── LocationPickerView.swift
│   ├── ResultsView.swift
│   ├── ActivityFinderView.swift
│   └── ProfileView.swift
└── Info.plist          # Location permissions
```

## Usage

### Creating a Meet

1. Tap "New Meet" on the home screen
2. Enter a meet title
3. Add participants (2-8 people)
4. Set starting location for each participant:
   - Use current location
   - Enter an address
5. Select transportation mode (Drive)
6. Choose place category (Restaurant/Cafe/Activity/Parking)
7. Tap "Find Places" to get ranked suggestions

### Viewing Results

Results are ranked by:
- **Fairness Score**: Difference between longest and shortest travel time (lower is better)
- **Total Travel Time**: Sum of all participants' travel times
- **Profile Match**: How well the place matches user preferences (0-100%)

Each result shows:
- Place name and address
- Travel time for each participant
- Fairness and total time metrics
- Profile match percentage

Tap a result to see details and open in Apple Maps.

### Activity Finder

1. Tap "Find Activities" on the home screen
2. Optionally enter a search query
3. Select a category
4. Adjust search radius
5. Tap "Search" to find activities near your location

Results are filtered based on your profile preferences.

### Profile Management

1. Tap "Profile" on the home screen
2. Set your display name
3. Add food preferences (e.g., "Italian", "Sushi")
4. Add activity preferences (e.g., "Bowling", "Hiking")
5. Set budget range (Low/Medium/High)
6. Add vibe preferences (e.g., "quiet", "lively")
7. Add accessibility needs
8. Tap "Save"

## Technical Details

### Architecture
- **MVVM**: ViewModels manage state and business logic
- **SwiftUI**: Modern declarative UI framework
- **Async/Await**: Modern concurrency for network and location operations

### Key Services

#### LocationManager
- Handles CoreLocation permissions
- Provides current location
- Geocodes addresses to coordinates

#### PlaceSearchService
- Uses MKLocalSearch to find places near a midpoint
- Supports category-based and query-based searches
- Limits results to 25 places (per PRD)

#### RoutingService
- Uses MKDirections to calculate travel times
- Caches results to avoid redundant API calls
- Supports concurrent requests with TaskGroup

#### RankingService
- Calculates fairness score (max - min travel time)
- Computes profile match based on preferences
- Combines scores with weighted algorithm:
  - Fairness: 45%
  - Total Time: 35%
  - Profile Match: 20%
  - Rating: 0% (not available in MVP)

### Data Models

- **UserProfile**: User information and preferences
- **Meet**: A meeting with participants, mode, and category
- **Participant**: A person in a meet with starting point
- **Place**: A venue/activity from MapKit
- **PlaceScore**: A place with calculated scores and travel times

## Phase 2 Features (Not Implemented)

The following features are planned for future phases:

### External Services Integration
- **Google Places API**: For ratings, photos, and detailed place information
- **Yelp Fusion API**: Alternative ratings provider
- **Foursquare**: Additional place data

To integrate external services:

1. **Create a PlacesProvider Protocol**
   ```swift
   protocol PlacesProvider {
       func search(midpoint: CLLocationCoordinate2D, category: PlaceCategory, radius: Double) async throws -> [Place]
       func details(placeID: String) async throws -> PlaceDetails
   }
   ```

2. **Implement Providers**
   - Create `GooglePlacesProvider`
   - Create `YelpPlacesProvider`
   - Update `PlaceSearchService` to use providers

3. **Add API Keys**
   - Store keys securely (e.g., Keychain, environment variables)
   - Never commit keys to version control

### Additional Features
- **Transit Mode**: Public transportation routing
- **Walk Mode**: Walking directions
- **Real-time Location Sharing**: Background location updates
- **Invitations**: Share meets via links
- **SwiftData Persistence**: Save profiles and meets locally
- **Saved Meets**: View and reuse previous meets

## Performance Considerations

- **Candidate Places**: Limited to 15-25 places
- **Participants**: Limited to 8 people (MVP)
- **Concurrent Routing**: Uses TaskGroup for parallel requests
- **Caching**: Directions results cached per session
- **Search Radius**: Dynamically calculated based on participant spread (2-8 miles)

## Privacy & Permissions

- **Location**: "When In Use" permission only
- **No Background Tracking**: MVP does not track location continuously
- **User Control**: Users explicitly set starting points
- **Privacy-First**: No location data stored persistently (Phase 2: SwiftData)

## Troubleshooting

### Location Permission Not Requested
- Ensure `NSLocationWhenInUseUsageDescription` is set in Info.plist or build settings
- Check that LocationManager is requesting permission correctly

### No Places Found
- Verify location permissions are granted
- Check that participants have valid starting locations
- Try increasing search radius
- Ensure you're in an area with places (not remote location)

### Routing Fails
- Check internet connection
- Verify coordinates are valid
- Some routes may not be available (e.g., pedestrian-only areas)

### Build Errors
- Ensure all files are added to the target
- Check that deployment target is iOS 18.2+
- Verify Swift version is 5.0+

## Testing

### Manual Testing Checklist
- [ ] Location permission request appears
- [ ] Can add/remove participants
- [ ] Can set starting locations (current/address)
- [ ] Search returns results
- [ ] Results are ranked correctly
- [ ] Can open places in Apple Maps
- [ ] Profile preferences save correctly
- [ ] Activity finder filters by preferences

### Test Scenarios
1. **Two Participants**: Create meet with 2 people, verify fairness calculation
2. **Multiple Participants**: Test with 4-6 people, verify performance
3. **Different Categories**: Test restaurant, cafe, activity, parking searches
4. **Profile Matching**: Set preferences, verify match scores
5. **Edge Cases**: Remote locations, invalid addresses, no results

## App Store Submission

### Required Information
- **Privacy Policy**: Required for location usage
- **App Description**: Highlight meet-in-the-middle functionality
- **Screenshots**: Show main flows (Home → New Meet → Results)
- **App Icon**: 1024x1024 icon

### Privacy Details
- Location data used only for routing and place suggestions
- No data shared with third parties (MVP)
- No background location tracking

## Contributing

When adding new features:
1. Follow MVVM architecture
2. Use async/await for async operations
3. Add error handling
4. Update this README
5. Test on device (not just simulator)

## License

[Add your license here]

## Support

For issues or questions, please [create an issue](link-to-issues) or contact [your-email].

