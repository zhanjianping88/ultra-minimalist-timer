//
//  ContentView.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var timerViewModel: TimerViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSettings = false

    var body: some View {
        TimerView(showingSettings: $showingSettings)
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
            .onAppear {
                timerViewModel.configureIfNeeded()
            }
            .onChange(of: scenePhase) { newPhase in
                timerViewModel.handleScenePhaseChange(newPhase)
            }
            .onChange(of: settings.defaultDurationMinutes) { _ in
                timerViewModel.applyUpdatedDefaultDuration()
            }
            .onChange(of: settings.soundEnabled) { _ in
                timerViewModel.refreshNotificationSchedule()
            }
            .onChange(of: settings.hapticsEnabled) { _ in
                timerViewModel.refreshNotificationSchedule()
            }
            .onChange(of: settings.selectedSoundID) { _ in
                timerViewModel.refreshNotificationSchedule()
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView()
                    .preferredColorScheme(.dark)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = AppSettings()

        ContentView()
            .environmentObject(settings)
            .environmentObject(TimerViewModel(settings: settings))
    }
}
