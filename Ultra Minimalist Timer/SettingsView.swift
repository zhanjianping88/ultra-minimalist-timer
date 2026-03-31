//
//  SettingsView.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var timerViewModel: TimerViewModel

    private let durations = Array(AppSettings.minimumDurationMinutes...AppSettings.maximumDurationMinutes)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Default Duration")
                        Spacer()
                        Menu {
                            ForEach(durations, id: \.self) { duration in
                                Button {
                                    settings.defaultDurationMinutes = duration
                                } label: {
                                    if duration == settings.defaultDurationMinutes {
                                        Label(durationLabel(for: duration), systemImage: "checkmark")
                                    } else {
                                        Text(durationLabel(for: duration))
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(settings.defaultDurationMinutes) min")
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    Toggle("Sound", isOn: $settings.soundEnabled)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                }
                .listRowBackground(Color(red: 0.08, green: 0.08, blue: 0.09))

                Section {
                    HStack {
                        Text("Alarm Sound")
                        Spacer()
                        Menu {
                            ForEach(AppSettings.availableSounds) { sound in
                                Button {
                                    settings.selectedSoundID = sound.id
                                } label: {
                                    if sound.id == settings.selectedSoundID {
                                        Label(sound.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(sound.displayName)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(settings.selectedSound.displayName)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color(red: 0.08, green: 0.08, blue: 0.09))

                Section {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundStyle(.secondary)
                    }

                    Button("Open Notification Settings") {
                        openAppSettings()
                    }
                    .foregroundStyle(.white)
                }
                .listRowBackground(Color(red: 0.08, green: 0.08, blue: 0.09))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .tint(.white)
                }
            }
        }
    }

    private func durationLabel(for duration: Int) -> String {
        duration == 1 ? "1 min" : "\(duration) min"
    }

    private var notificationStatusText: String {
        switch timerViewModel.notificationStatus {
        case .authorized:
            return "On"
        case .provisional, .ephemeral:
            return "Limited"
        case .denied:
            return "Off"
        case .notDetermined:
            return "Ask"
        @unknown default:
            return "Unknown"
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppSettings())
            .preferredColorScheme(.dark)
    }
}
