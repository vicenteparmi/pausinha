//
//  DurationPresetsGrid.swift
//  Pausinha
//
//  Grid de durações pré-definidas (5, 10, 15, 30, 60 min).
//

import SwiftUI

struct DurationPresetsGrid: View {
    let presets: [(label: String, minutes: Int)]
    @Binding var selectedPresetMinutes: Int?
    @Binding var customMinutes: Int

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(presets, id: \.minutes) { opt in
                let selected = selectedPresetMinutes == opt.minutes
                Button {
                    selectedPresetMinutes = opt.minutes
                    customMinutes = opt.minutes
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(opt.label)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(selected ? .white : .primary)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                        )
                }
                .animation(.easeInOut(duration: 0.15), value: selectedPresetMinutes)
            }
        }
    }
}
