//
//  DurationInputSection.swift
//  Pausinha
//
//  Seção de tempo do formulário de criação: segmented control Duração / Horário,
//  grid de presets, stepper livre e DatePicker de horário.
//

import SwiftUI

struct DurationInputSection: View {
    @Binding var timeMode: TimeMode
    @Binding var selectedPresetMinutes: Int?
    @Binding var customMinutes: Int
    @Binding var endTime: Date

    let effectiveMinutes: Int
    let expiresAt: Date

    private let presets: [(label: String, minutes: Int)] = [
        ("5 min", 5), ("10 min", 10), ("15 min", 15), ("30 min", 30), ("1 h", 60),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Até quando?", systemImage: "clock")
                .font(.headline)

            Picker("Modo", selection: $timeMode.animation()) {
                ForEach(TimeMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: timeMode) { _, _ in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }

            if timeMode == .duration {
                DurationPresetsGrid(
                    presets: presets,
                    selectedPresetMinutes: $selectedPresetMinutes,
                    customMinutes: $customMinutes
                )
                DurationStepper(
                    customMinutes: $customMinutes,
                    selectedPresetMinutes: $selectedPresetMinutes,
                    effectiveMinutes: effectiveMinutes
                )
                Text("Encerra às \(formatShortTime(expiresAt))")
                    .font(.caption).foregroundColor(.secondary)
            } else {
                EndTimePicker(endTime: $endTime, expiresAt: expiresAt)
            }
        }
    }
}
