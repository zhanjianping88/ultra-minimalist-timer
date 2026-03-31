//
//  TimerViewModel.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import Combine
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class TimerViewModel: ObservableObject {
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isAlarming = false
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined

    var timeText: String {
        let totalSeconds = Int(remainingTime.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private let settings: AppSettings
    private let notificationManager = NotificationManager()

    private var timerCancellable: AnyCancellable?
    private var endDate: Date?
    private var didConfigure = false
    private var shouldAlarmWhenActive = false

    init(settings: AppSettings) {
        self.settings = settings
    }

    func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true

        startNewSession()
        startTicker()

        Task {
            let granted = await notificationManager.requestAuthorizationIfNeeded()
            notificationStatus = granted ? .authorized : await notificationManager.authorizationStatus()
            refreshNotificationSchedule()
        }
    }

    func handlePrimaryTap() {
        if isAlarming {
            stopAlarm()
        } else if isRunning {
            pause()
        } else if remainingTime <= 0 {
            startNewSession()
        } else {
            resume()
        }
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task {
                notificationStatus = await notificationManager.authorizationStatus()
            }
            synchronizeTimerState()
            resumeAlarmIfNeeded()
        case .background:
            refreshNotificationSchedule()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func applyUpdatedDefaultDuration() {
        stopAlarm()
        let updatedDuration = TimeInterval(settings.defaultDurationMinutes * 60)
        remainingTime = updatedDuration
        endDate = Date().addingTimeInterval(updatedDuration)
        isRunning = true
        refreshNotificationSchedule()
    }

    func refreshNotificationSchedule() {
        guard isRunning, remainingTime > 0 else {
            notificationManager.cancelTimerNotification()
            return
        }

        Task {
            let status = await notificationManager.authorizationStatus()
            notificationStatus = status

            guard status == .authorized || status == .provisional || status == .ephemeral else {
                notificationManager.cancelTimerNotification()
                return
            }

            notificationManager.scheduleTimerNotification(
                after: remainingTime,
                soundEnabled: settings.soundEnabled,
                soundFileName: settings.selectedSound.fileName
            )
        }
    }

    private func startNewSession() {
        stopAlarm()
        remainingTime = TimeInterval(settings.defaultDurationMinutes * 60)
        endDate = Date().addingTimeInterval(remainingTime)
        isRunning = true
        refreshNotificationSchedule()
    }

    private func startTicker() {
        timerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning else { return }
        synchronizeTimerState()
    }

    private func synchronizeTimerState() {
        guard isRunning, let endDate else { return }

        let updatedRemaining = max(0, endDate.timeIntervalSinceNow)
        if updatedRemaining <= 0 {
            completeTimer()
        } else {
            remainingTime = updatedRemaining
        }
    }

    private func pause() {
        synchronizeTimerState()
        isRunning = false
        endDate = nil
        stopAlarm()
        notificationManager.cancelTimerNotification()
    }

    private func resume() {
        guard remainingTime > 0 else {
            startNewSession()
            return
        }

        endDate = Date().addingTimeInterval(remainingTime)
        isRunning = true
        refreshNotificationSchedule()
    }

    private func completeTimer() {
        remainingTime = 0
        isRunning = false
        endDate = nil
        notificationManager.cancelTimerNotification()

        let shouldPlayAlarm = settings.soundEnabled
        let shouldTriggerHaptics = settings.hapticsEnabled

        if UIApplication.shared.applicationState != .active {
            shouldAlarmWhenActive = shouldPlayAlarm
            return
        }

        triggerAlarmIfNeeded(playSound: shouldPlayAlarm, playHaptics: shouldTriggerHaptics)
    }

    private func stopAlarm() {
        shouldAlarmWhenActive = false
        isAlarming = false
        AlarmPlayer.shared.stop()
    }

    private func resumeAlarmIfNeeded() {
        guard shouldAlarmWhenActive, !isAlarming, remainingTime <= 0 else { return }
        triggerAlarmIfNeeded(playSound: settings.soundEnabled, playHaptics: settings.hapticsEnabled)
    }

    private func triggerAlarmIfNeeded(playSound: Bool, playHaptics: Bool) {
        shouldAlarmWhenActive = false

        if playSound {
            isAlarming = true
            AlarmPlayer.shared.playCompletionSound(named: settings.selectedSound.fileName)
        }

        if playHaptics {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
