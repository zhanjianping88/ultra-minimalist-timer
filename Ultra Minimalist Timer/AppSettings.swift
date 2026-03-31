//
//  AppSettings.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let defaultDurationMinutes = "defaultDurationMinutes"
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let selectedSound = "selectedSound"
    }

    static let minimumDurationMinutes = 1
    static let maximumDurationMinutes = 180
    static let fallbackDurationMinutes = 25
    static let availableSounds: [AlertSound] = [
        AlertSound(id: "basso", displayName: "Basso", fileName: "Basso.aiff"),
        AlertSound(id: "glass", displayName: "Glass", fileName: "Glass.aiff"),
        AlertSound(id: "hero", displayName: "Hero", fileName: "Hero.aiff"),
        AlertSound(id: "submarine", displayName: "Submarine", fileName: "Submarine.aiff")
    ]

    @Published var defaultDurationMinutes: Int {
        didSet {
            let clamped = Self.clampedDuration(defaultDurationMinutes)
            if defaultDurationMinutes != clamped {
                defaultDurationMinutes = clamped
                return
            }

            UserDefaults.standard.set(defaultDurationMinutes, forKey: Keys.defaultDurationMinutes)
        }
    }

    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }

    @Published var selectedSoundID: String {
        didSet {
            let resolvedID = Self.sound(for: selectedSoundID)?.id ?? Self.availableSounds[0].id
            if selectedSoundID != resolvedID {
                selectedSoundID = resolvedID
                return
            }

            UserDefaults.standard.set(selectedSoundID, forKey: Keys.selectedSound)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        let storedDuration = userDefaults.object(forKey: Keys.defaultDurationMinutes) as? Int
        defaultDurationMinutes = Self.clampedDuration(storedDuration ?? Self.fallbackDurationMinutes)

        if userDefaults.object(forKey: Keys.soundEnabled) == nil {
            soundEnabled = true
        } else {
            soundEnabled = userDefaults.bool(forKey: Keys.soundEnabled)
        }

        if userDefaults.object(forKey: Keys.hapticsEnabled) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = userDefaults.bool(forKey: Keys.hapticsEnabled)
        }

        let storedSoundID = userDefaults.string(forKey: Keys.selectedSound) ?? Self.availableSounds[0].id
        selectedSoundID = Self.sound(for: storedSoundID)?.id ?? Self.availableSounds[0].id
    }

    static func clampedDuration(_ minutes: Int) -> Int {
        min(max(minutes, minimumDurationMinutes), maximumDurationMinutes)
    }

    static func sound(for id: String) -> AlertSound? {
        availableSounds.first(where: { $0.id == id })
    }

    var selectedSound: AlertSound {
        Self.sound(for: selectedSoundID) ?? Self.availableSounds[0]
    }
}

struct AlertSound: Identifiable, Equatable {
    let id: String
    let displayName: String
    let fileName: String
}
