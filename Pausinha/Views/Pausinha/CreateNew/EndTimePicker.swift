//
//  EndTimePicker.swift
//  Pausinha
//
//  DatePicker de horário fixo de encerramento (modo "Horário").
//  Exibe aviso se o horário já passou (pausinha encerra no dia seguinte).
//

import SwiftUI

struct EndTimePicker: View {
    @Binding var endTime: Date
    let expiresAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DatePicker(
                "Horário de encerramento",
                selection: $endTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            if endTime <= Date() {
                Label(
                    "Horário já passou — pausinha encerra amanhã.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundColor(.orange)
            } else {
                Text("Duração: ~\(minutesUntil(expiresAt)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func minutesUntil(_ date: Date) -> Int {
        max(0, Int(date.timeIntervalSinceNow / 60))
    }
}
