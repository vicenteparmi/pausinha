//
//  PausinhaGroup.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import Foundation
import SwiftData
import CloudKit

// MARK: - Status Enum

enum PausinhaStatus: String, Codable {
    case active = "active"
    case closed = "closed"
}

// MARK: - PausinhaGroup Model

/// Representa um grupo de pausa criado por um usuário.
/// Os dados são armazenados localmente via SwiftData e sincronizados
/// com o CloudKit **banco público** para que todos os membros da
/// organização possam ver os grupos em tempo real.
@Model
final class PausinhaGroup {

    // MARK: Campos persistidos

    /// Identificador único do grupo (UUID string).
    var id: String = UUID().uuidString

    /// Título da pausa (ex: "Café na copa", "Bora jogar Uno").
    var title: String = ""

    /// Ícone da pausa (emoji)
    var icon: String = "☕️"

    /// ID da instituição a qual esta pausinha pertence.
    var institutionID: String = ""

    /// userID do usuário que criou o grupo.
    var creatorID: String = ""

    /// Array de userIDs dos participantes atuais.
    /// Armazenado como JSON string para compatibilidade com SwiftData/CloudKit.
    private var participantIDsJSON: String = "[]"

    /// Data/hora em que a pausa deve encerrar conforme estipulado pelo criador.
    var expiresAt: Date = Date()

    /// Status do grupo: "active" ou "closed".
    var statusRaw: String = PausinhaStatus.active.rawValue

    /// Data de criação do grupo.
    var createdAt: Date = Date()

    /// CloudKit record name no banco público (usado para updates/deletes).
    var cloudKitRecordName: String?

    // MARK: Computed Properties

    /// Lista de IDs dos participantes (decode do JSON interno).
    var participantIDs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: Data(participantIDsJSON.utf8))) ?? []
        }
        set {
            participantIDsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    /// Status tipado do grupo.
    var status: PausinhaStatus {
        get { PausinhaStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// Quantidade atual de participantes.
    var currentParticipantCount: Int {
        participantIDs.count
    }

    /// Verdadeiro quando o grupo ultrapassou 15 minutos além do tempo estipulado.
    /// Usado para encerramento automático pela regra de negócio.
    var isExpiredGracePeriod: Bool {
        Date() > expiresAt.addingTimeInterval(15 * 60)
    }

    /// Verdadeiro quando o tempo estipulado acabou, mas ainda dentro do grace period.
    var isOverTime: Bool {
        Date() > expiresAt && !isExpiredGracePeriod
    }

    // MARK: Inicializadores

    init(
        title: String,
        icon: String = "☕️",
        institutionID: String,
        creatorID: String,
        participantIDs: [String] = [],
        expiresAt: Date,
        status: PausinhaStatus = .active
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.icon = icon
        self.institutionID = institutionID
        self.creatorID = creatorID
        self.participantIDsJSON = (try? String(data: JSONEncoder().encode(participantIDs), encoding: .utf8)) ?? "[]"
        self.expiresAt = expiresAt
        self.statusRaw = status.rawValue
        self.createdAt = Date()
    }

    // MARK: - CloudKit Interop

    /// Cria um `CKRecord` para salvar no banco **público** do CloudKit.
    func getPublicRecord() -> CKRecord {
        let recordName = self.cloudKitRecordName ?? self.id
        let ckRecordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: "PausinhaGroup", recordID: ckRecordID)

        record["id"]              = self.id as CKRecordValue
        record["title"]           = self.title as CKRecordValue
        record["icon"]            = self.icon as CKRecordValue
        record["institutionID"]   = self.institutionID as CKRecordValue
        record["creatorID"]       = self.creatorID as CKRecordValue
        record["participantIDs"]  = self.participantIDs as CKRecordValue
        record["expiresAt"]       = self.expiresAt as CKRecordValue
        record["status"]          = self.statusRaw as CKRecordValue
        record["createdAt"]       = self.createdAt as CKRecordValue

        // Garante que o recordName local fica salvo para operações futuras
        if self.cloudKitRecordName == nil {
            self.cloudKitRecordName = recordName
        }

        return record
    }

    /// Inicializa um `PausinhaGroup` a partir de um `CKRecord` do banco público.
    convenience init(from record: CKRecord) {
        let participantIDs = record["participantIDs"] as? [String] ?? []
        let expiresAt      = record["expiresAt"] as? Date ?? Date()
        let statusRaw      = record["status"] as? String ?? PausinhaStatus.active.rawValue

        self.init(
            title:          record["title"] as? String ?? "Pausinha",
            icon:           record["icon"] as? String ?? "☕️",
            institutionID:  record["institutionID"] as? String ?? "",
            creatorID:      record["creatorID"] as? String ?? "",
            participantIDs: participantIDs,
            expiresAt:      expiresAt,
            status:         PausinhaStatus(rawValue: statusRaw) ?? .active
        )

        // Sobrescreve o id gerado com o valor original do servidor
        if let serverID = record["id"] as? String {
            self.id = serverID
        }
        if let createdAt = record["createdAt"] as? Date {
            self.createdAt = createdAt
        }
        self.cloudKitRecordName = record.recordID.recordName
    }

    // MARK: - Participant Management

    /// Adiciona um participante ao grupo (se ainda não estiver presente).
    func addParticipant(_ userID: String) {
        var ids = participantIDs
        guard !ids.contains(userID) else { return }
        ids.append(userID)
        participantIDs = ids
    }

    /// Remove um participante do grupo.
    func removeParticipant(_ userID: String) {
        participantIDs = participantIDs.filter { $0 != userID }
    }

    /// Encerra o grupo manualmente.
    func close() {
        self.status = .closed
    }
}
