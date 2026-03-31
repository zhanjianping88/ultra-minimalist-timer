//
//  AlarmPlayer.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import AVFoundation
import AudioToolbox

@MainActor
final class AlarmPlayer {
    static let shared = AlarmPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var systemSoundID: SystemSoundID = 0
    private var fallbackTimer: Timer?

    private init() { }

    func playCompletionSound(named fileName: String) {
        let components = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard let resource = components.first else { return }
        let fileExtension = components.count > 1 ? components[1] : nil
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
            try session.overrideOutputAudioPort(.speaker)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            if audioPlayer?.play() != true {
                playFallbackAlert(using: url)
            }
        } catch {
            audioPlayer?.stop()
            audioPlayer = nil
            playFallbackAlert(using: url)
        }
    }

    func stop() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil

        audioPlayer?.stop()
        audioPlayer = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Nothing user-actionable here.
        }
    }

    private func playFallbackAlert(using url: URL) {
        if systemSoundID == 0 {
            AudioServicesCreateSystemSoundID(url as CFURL, &systemSoundID)
        }

        guard systemSoundID != 0 else { return }
        AudioServicesPlayAlertSound(systemSoundID)

        fallbackTimer?.invalidate()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            AudioServicesPlayAlertSound(self.systemSoundID)
        }
    }
}
