//
//  DurationStepper.swift
//  Pausinha
//
//  Stepper de input livre de duração (1–480 minutos).
//  Ao tocar em − ou +, desmarca o preset selecionado e entra em modo livre.
//

import SwiftUI

struct DurationStepper: View {
    @Binding var customMinutes: Int
    @Binding var selectedPresetMinutes: Int?
    let effectiveMinutes: Int

    var body: some View {
        HStack(spacing: 0) {
            stepButton(systemImage: "minus", enabled: customMinutes > 1) {
                customMinutes -= 1
                selectedPresetMinutes = nil
            }

            Text("\(effectiveMinutes) min")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            stepButton(systemImage: "plus", enabled: customMinutes < 480) {
                customMinutes += 1
                selectedPresetMinutes = nil
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func stepButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: systemImage)
                .frame(width: 48, height: 48)
                .foregroundColor(enabled ? .primary : .secondary)
        }
    }
}
