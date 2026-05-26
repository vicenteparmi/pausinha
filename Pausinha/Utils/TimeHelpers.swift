//
//  TimeHelpers.swift
//  Pausinha
//
//  Funções utilitárias de formatação de tempo compartilhadas entre views.
//

import Foundation

/// Formata um `TimeInterval` em string "M:SS" (ex: "9:05", "0:30").
func formatTimeInterval(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval))
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%d:%02d", minutes, seconds)
}

/// Formata um `Date` como horário curto no locale pt_BR (ex: "14:30").
func formatShortTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.timeStyle = .short
    return f.string(from: date)
}

/// Retorna quantos minutos inteiros restam até uma data.
func minutesUntil(_ date: Date) -> Int {
    max(0, Int(date.timeIntervalSinceNow / 60))
}
