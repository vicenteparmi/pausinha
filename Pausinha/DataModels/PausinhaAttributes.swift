//
//  PausinhaAttributes.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import Foundation
import ActivityKit

/// Atributos da Live Activity para uma Pausinha.
/// Contém propriedades estáticas (nome da pausa) e propriedades
/// de estado que mudam ao longo do tempo (tempo restante, participantes).
public struct PausinhaAttributes: ActivityAttributes {
    
    // MARK: - Propriedades Estáticas
    // Dados que não mudam durante o ciclo de vida da atividade.
    public struct ContentState: Codable, Hashable {
        
        // MARK: - Propriedades Dinâmicas (Estado)
        // Dados que mudam (tempo, quantidade de participantes, etc).
        
        /// Data em que a pausinha deve encerrar (para o timer contínuo)
        public var expiresAt: Date
        
        /// Quantidade de participantes atual
        public var participantCount: Int
        
        /// Indica se a pausinha já passou do tempo estipulado
        public var isOverTime: Bool
        
        // As cores podem ser dinâmicas dependendo do status
        public var isClosed: Bool
        
        public init(expiresAt: Date, participantCount: Int, isOverTime: Bool, isClosed: Bool = false) {
            self.expiresAt = expiresAt
            self.participantCount = participantCount
            self.isOverTime = isOverTime
            self.isClosed = isClosed
        }
    }

    /// ID único do grupo para identificar a atividade
    public var groupID: String
    
    /// Título da pausinha ("Café", "Almoço", etc)
    public var title: String
    
    /// Nome de quem criou a pausinha
    public var creatorName: String
    
    public init(groupID: String, title: String, creatorName: String) {
        self.groupID = groupID
        self.title = title
        self.creatorName = creatorName
    }
}
