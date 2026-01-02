//
//  ProfileView.swift
//  MeetInMiddle
//
//  Created by Carl Paolino on 12/25/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var appViewModel: AppViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingDataManagement = false
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            profile: appViewModel.userProfile,
            onSave: { profile in
                appViewModel.saveProfile(profile)
            }
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    NavigationLink(destination: ProfileSettingsView(viewModel: viewModel)) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.displayName.isEmpty ? "Me" : viewModel.displayName)
                                    .font(.headline)
                                Text("Manage your profile preferences")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Profile")
                }
                
                // Privacy & Policies Section
                Section {
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingTermsOfService = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingDataManagement = true
                    }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Data Management")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Privacy & Policies")
                }
                
                // Integrations Section
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Calendar")
                        Spacer()
                        Toggle("", isOn: .constant(false))
                            .disabled(true)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Contacts")
                        Spacer()
                        Toggle("", isOn: .constant(false))
                            .disabled(true)
                    }
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Location Services")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .disabled(true)
                    }
                    
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .disabled(true)
                    }
                } header: {
                    Text("Integrations")
                } footer: {
                    Text("Connect external services to enhance your experience")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingDataManagement) {
                DataManagementView(appViewModel: appViewModel)
            }
        }
    }
}

// Profile Settings Detail View
struct ProfileSettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Display Name", text: $viewModel.displayName)
            }
            
            Section("Food Preferences") {
                ForEach(viewModel.foodTypes, id: \.self) { type in
                    HStack {
                        Text(type)
                        Spacer()
                        Button(action: {
                            viewModel.removeFoodType(type)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add food type", text: $viewModel.newFoodType)
                        .onSubmit {
                            viewModel.addFoodType()
                        }
                    Button("Add") {
                        viewModel.addFoodType()
                    }
                    .disabled(viewModel.newFoodType.isEmpty)
                }
            }
            
            Section("Activity Preferences") {
                ForEach(viewModel.activityTypes, id: \.self) { type in
                    HStack {
                        Text(type)
                        Spacer()
                        Button(action: {
                            viewModel.removeActivityType(type)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add activity type", text: $viewModel.newActivityType)
                        .onSubmit {
                            viewModel.addActivityType()
                        }
                    Button("Add") {
                        viewModel.addActivityType()
                    }
                    .disabled(viewModel.newActivityType.isEmpty)
                }
            }
            
            Section("Budget") {
                Picker("Budget Range", selection: $viewModel.budget) {
                    ForEach(BudgetRange.allCases, id: \.self) { budget in
                        Text(budget.rawValue).tag(budget)
                    }
                }
            }
            
            Section("Vibe Preferences") {
                ForEach(viewModel.vibe, id: \.self) { item in
                    HStack {
                        Text(item)
                        Spacer()
                        Button(action: {
                            viewModel.removeVibe(item)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add vibe", text: $viewModel.newVibe)
                        .onSubmit {
                            viewModel.addVibe()
                        }
                    Button("Add") {
                        viewModel.addVibe()
                    }
                    .disabled(viewModel.newVibe.isEmpty)
                }
            }
            
            Section("Accessibility Needs") {
                ForEach(viewModel.accessibilityNeeds, id: \.self) { need in
                    HStack {
                        Text(need)
                        Spacer()
                        Button(action: {
                            viewModel.removeAccessibilityNeed(need)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add accessibility need", text: $viewModel.newAccessibilityNeed)
                        .onSubmit {
                            viewModel.addAccessibilityNeed()
                        }
                    Button("Add") {
                        viewModel.addAccessibilityNeed()
                    }
                    .disabled(viewModel.newAccessibilityNeed.isEmpty)
                }
            }
        }
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.displayName) { _ in
            viewModel.save()
        }
        .onChange(of: viewModel.foodTypes) { _ in
            viewModel.save()
        }
        .onChange(of: viewModel.activityTypes) { _ in
            viewModel.save()
        }
        .onChange(of: viewModel.budget) { _ in
            viewModel.save()
        }
        .onChange(of: viewModel.vibe) { _ in
            viewModel.save()
        }
        .onChange(of: viewModel.accessibilityNeeds) { _ in
            viewModel.save()
        }
    }
}

// Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)
                    
                    Text("Last Updated: December 25, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(title: "Information We Collect", content: """
                        We collect information that you provide directly to us, including:
                        - Display name and profile information
                        - Location data when you use location-based features
                        - Preferences for activities, food, and other meeting preferences
                        - Accessibility needs and requirements
                        """)
                        
                        SectionView(title: "How We Use Your Information", content: """
                        We use the information we collect to:
                        - Provide and improve our services
                        - Find meeting locations that work for all participants
                        - Personalize your experience
                        - Communicate with you about your meets
                        """)
                        
                        SectionView(title: "Data Storage", content: """
                        Your data is stored locally on your device. We do not transmit your personal information to external servers without your explicit consent.
                        """)
                        
                        SectionView(title: "Your Rights", content: """
                        You have the right to:
                        - Access your personal data
                        - Delete your personal data
                        - Modify your preferences at any time
                        """)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom)
                    
                    Text("Last Updated: December 25, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionView(title: "Acceptance of Terms", content: """
                        By using MeetInMiddle, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.
                        """)
                        
                        SectionView(title: "Use of Service", content: """
                        You agree to use MeetInMiddle only for lawful purposes and in accordance with these Terms. You agree not to use the service in any way that could damage, disable, or impair the app.
                        """)
                        
                        SectionView(title: "Location Services", content: """
                        MeetInMiddle uses location services to find meeting points. You are responsible for ensuring you have permission to share location data with other participants.
                        """)
                        
                        SectionView(title: "Limitation of Liability", content: """
                        MeetInMiddle is provided "as is" without warranties of any kind. We are not responsible for the accuracy of location data or meeting suggestions.
                        """)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Data Management View
struct DataManagementView: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: {
                        // Export data functionality
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export My Data")
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Data Export")
                } footer: {
                    Text("Download a copy of all your data stored in the app")
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Data")
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all your profile data, preferences, and meet history. This action cannot be undone.")
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Implement data deletion
                    appViewModel.userProfile = UserProfile()
                    appViewModel.saveProfile(appViewModel.userProfile)
                }
            } message: {
                Text("This will permanently delete all your data. This action cannot be undone.")
            }
        }
    }
}

// Helper view for section content
struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView(appViewModel: AppViewModel())
}

