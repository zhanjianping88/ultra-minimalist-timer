//
//  TimerView.swift
//  Ultra Minimalist Timer
//
//  Created by 建平 on 2026/3/30.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var timerViewModel: TimerViewModel

    @Binding var showingSettings: Bool
    @State private var breathing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.03, green: 0.03, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(timerViewModel.timeText)
                .font(.system(size: 112, weight: .ultraLight, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(timerViewModel.isAlarming ? 1 : (timerViewModel.isRunning ? 0.96 : 0.72)))
                .scaleEffect(timerViewModel.isAlarming ? 1.02 : (breathing ? 1.012 : 0.988))
                .animation(
                    .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                    value: breathing
                )
                .animation(.easeInOut(duration: 0.2), value: timerViewModel.isAlarming)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.45)
                .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .onAppear {
            breathing = true
        }
        .gesture(timerGesture)
    }

    private var timerGesture: some Gesture {
        ExclusiveGesture(
            LongPressGesture(minimumDuration: 0.6),
            TapGesture()
        )
        .onEnded { value in
            switch value {
            case .first(true):
                showingSettings = true
            case .first(false):
                break
            case .second:
                timerViewModel.handlePrimaryTap()
            }
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = AppSettings()

        TimerView(showingSettings: .constant(false))
            .environmentObject(TimerViewModel(settings: settings))
            .preferredColorScheme(.dark)
    }
}
