//
//  NotificationManager.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import Foundation
import UserNotifications

struct NotificationManager {
    static let timerNotificationIdentifier = "ultra-minimalist-timer.finished"

    func requestAuthorizationIfNeeded() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func scheduleTimerNotification(after interval: TimeInterval, soundEnabled: Bool, soundFileName: String) {
        guard interval > 0 else { return }

        cancelTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your focus session has finished."
        content.sound = soundEnabled ? UNNotificationSound(named: UNNotificationSoundName(soundFileName)) : nil
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.timerNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.timerNotificationIdentifier]
        )
    }
}
