//
//  PausinhaWidgetLiveActivity.swift
//  PausinhaWidget
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// NOTA: Para este arquivo compilar, ele precisa estar em um Target de Widget Extension.
// Ele também precisa ter acesso ao arquivo `PausinhaAttributes.swift`.

struct PausinhaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PausinhaAttributes.self) { context in
            // Lock screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.title, systemImage: "cup.and.saucer.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.secondary)
                        Text("\(context.state.participantCount)")
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.isClosed ? "Encerrado" : (context.state.isOverTime ? "Tempo extra" : "Termina em:"))
                            .font(.subheadline)
                            .foregroundColor(context.state.isOverTime ? .orange : .secondary)
                        
                        Spacer()
                        
                        if !context.state.isClosed {
                            Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundColor(context.state.isOverTime ? .orange : .primary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            } compactLeading: {
                // Compact Leading (Ex: Ícone laranja)
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(.accentColor)
            } compactTrailing: {
                // Compact Trailing (Timer)
                Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .frame(minWidth: 40)
            } minimal: {
                // Minimal (Apenas ícone na Dynamic Island quando há outras atividades)
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundColor(.accentColor)
            }
            .keylineTint(Color.accentColor)
        }
    }
}

// MARK: - Subviews

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PausinhaAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Ícone circular
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
            }
            
            // Informações
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(context.state.participantCount) participando")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Timer
            VStack(alignment: .trailing, spacing: 4) {
                if context.state.isClosed {
                    Text("Encerrado")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                } else if context.state.isOverTime {
                    Text("Tempo extra")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                } else {
                    Text(timerInterval: Date()...context.state.expiresAt, countsDown: true)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.6))
        .activitySystemActionForegroundColor(Color.accentColor)
    }
}
