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
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
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
}

#Preview {
    ProfileView(appViewModel: AppViewModel())
}

