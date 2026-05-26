//
//  LiveActivityManager.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//
//  Gerenciador do ciclo de vida das Live Activities usando ActivityKit.
//

import Foundation
import ActivityKit

/// Gerencia a criação, atualização e encerramento das Live Activities locais.
@MainActor
final class LiveActivityManager {
    
    static let shared = LiveActivityManager()
    
    private init() {}
    
    /// Inicia uma Live Activity para a pausinha atual
    func startActivity(for group: PausinhaGroup) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivityManager: Atividades ao vivo desativadas pelo usuário.")
            return
        }
        
        // Verifica se já existe uma atividade para este grupo
        if let existingActivity = getActivity(for: group.id) {
            print("LiveActivityManager: Já existe atividade para o grupo \(group.id). Atualizando...")
            updateActivity(existingActivity, with: group)
            return
        }
        
        // Atributos estáticos
        let attributes = PausinhaAttributes(
            groupID: group.id,
            title: group.title,
            creatorName: "Você" // Isso será substituído pelo nome real no futuro
        )
        
        // Estado dinâmico
        let initialState = PausinhaAttributes.ContentState(
            expiresAt: group.expiresAt,
            participantCount: group.currentParticipantCount,
            isOverTime: group.isOverTime,
            isClosed: false
        )
        
        do {
            // Solicita a criação da atividade
            let content = ActivityContent(state: initialState, staleDate: nil)
            let activity = try Activity<PausinhaAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil // Será usado APNs na Fase 4, por enquanto atualização local
            )
            print("LiveActivityManager: Atividade iniciada com ID \(activity.id) para grupo \(group.id)")
        } catch {
            print("LiveActivityManager: Erro ao iniciar atividade: \(error.localizedDescription)")
        }
    }
    
    /// Atualiza uma Live Activity existente com os dados mais recentes do grupo
    func updateActivity(for group: PausinhaGroup) {
        guard let activity = getActivity(for: group.id) else {
            print("LiveActivityManager: Nenhuma atividade encontrada para o grupo \(group.id)")
            return
        }
        updateActivity(activity, with: group)
    }
    
    /// Encerra a Live Activity
    func endActivity(for group: PausinhaGroup) {
        guard let activity = getActivity(for: group.id) else {
            print("LiveActivityManager: Nenhuma atividade encontrada para encerrar (grupo \(group.id))")
            return
        }
        
        // Estado final: fechado
        let finalState = PausinhaAttributes.ContentState(
            expiresAt: group.expiresAt,
            participantCount: group.currentParticipantCount,
            isOverTime: group.isOverTime,
            isClosed: true
        )
        
        Task {
            // Encerra imediatamente e descarta a atividade
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
            print("LiveActivityManager: Atividade encerrada para o grupo \(group.id)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Atualiza a atividade passando a instância diretamente
    private func updateActivity(_ activity: Activity<PausinhaAttributes>, with group: PausinhaGroup) {
        let newState = PausinhaAttributes.ContentState(
            expiresAt: group.expiresAt,
            participantCount: group.currentParticipantCount,
            isOverTime: group.isOverTime,
            isClosed: group.status == .closed
        )
        
        Task {
            let content = ActivityContent(state: newState, staleDate: nil)
            await activity.update(content)
            print("LiveActivityManager: Atividade atualizada para o grupo \(group.id)")
        }
    }
    
    /// Busca uma atividade ativa pelo ID do grupo
    private func getActivity(for groupID: String) -> Activity<PausinhaAttributes>? {
        return Activity<PausinhaAttributes>.activities.first(where: { $0.attributes.groupID == groupID })
    }
}
