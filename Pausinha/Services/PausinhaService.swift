//
//  PausinhaService.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import Foundation
import CloudKit
import Observation

/// Responsável por todas as operações de `PausinhaGroup` no CloudKit **banco público**.
///
/// Por que banco público?
/// O banco privado do CloudKit é acessível apenas pelo usuário dono da conta iCloud.
/// Para que todos os membros da organização vejam os grupos em tempo real, os registros
/// de `PausinhaGroup` precisam estar no `publicCloudDatabase`.
///
/// Separado do `CloudKitService` (banco privado) para manter responsabilidades bem definidas.
@Observable
final class PausinhaService {

    // MARK: - Published State

    /// Lista de grupos ativos (atualizada via fetch e assinaturas em tempo real).
    var activePausinhas: [PausinhaGroup] = []

    /// Últimas pausinhas encerradas (histórico), dentro do grace period de 3 horas.
    var recentClosedPausinhas: [PausinhaGroup] = []

    /// Indica se uma operação de rede está em andamento.
    var isLoading: Bool = false

    /// Último erro ocorrido, para exibição na UI.
    var lastError: String?

    // MARK: - CloudKit

    private let container: CKContainer
    private let publicDB: CKDatabase
    private var subscriptionID: String = "active-pausinhas-subscription"

    // MARK: - Errors

    enum PausinhaServiceError: LocalizedError {
        case iCloudUnavailable
        case recordNotFound
        case saveFailed(String)
        case fetchFailed(String)
        case deleteFailed(String)

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable:
                return "Conta iCloud não disponível. Verifique as configurações."
            case .recordNotFound:
                return "Pausinha não encontrada."
            case .saveFailed(let msg):
                return "Falha ao salvar pausinha: \(msg)"
            case .fetchFailed(let msg):
                return "Falha ao buscar pausinhas: \(msg)"
            case .deleteFailed(let msg):
                return "Falha ao excluir pausinha: \(msg)"
            }
        }
    }

    // MARK: - Init

    init() {
        self.container = CKContainer.default()
        self.publicDB  = container.publicCloudDatabase
    }

    // MARK: - Account Check

    /// Verifica se uma conta iCloud está disponível para operações no banco público.
    /// Nota: o banco público pode ser lido sem autenticação, mas escrita exige iCloud logado.
    func isAccountAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available || status == .temporarilyUnavailable
        } catch {
            print("PausinhaService: Erro ao verificar conta iCloud: \(error)")
            return false
        }
    }

    // MARK: - Fetch

    /// Busca todas as pausinhas ativas e o histórico recente (últimas 3 horas).
    @MainActor
    func fetchPausinhas(institutionID: String) async {
        isLoading = true
        lastError = nil

        do {
            let (active, recent) = try await fetchPausinhasFromCloud(institutionID: institutionID)
            self.activePausinhas       = active
            self.recentClosedPausinhas = recent
            print("PausinhaService: Fetch concluído — \(active.count) ativas, \(recent.count) recentes.")
        } catch {
            // Se for um erro de schema não inicializado (comum no boot do app quando não há registros no CloudKit),
            // tratamos como lista vazia em vez de exibir erro na interface.
            if let ckError = error as? CKError, ckError.code == .invalidArguments {
                let errorStr = String(describing: ckError)
                if errorStr.contains("Unknown field") || errorStr.contains("Record type") {
                    self.activePausinhas = []
                    self.recentClosedPausinhas = []
                    print("PausinhaService: Schema não existe no CloudKit ainda (sem registros criados). Tratando como lista vazia.")
                    isLoading = false
                    return
                }
            }
            
            self.lastError = error.localizedDescription
            print("PausinhaService: Erro no fetch — \(error)")
        }

        isLoading = false
    }

    /// Implementação interna do fetch, retornando tupla (ativas, recentes).
    private func fetchPausinhasFromCloud(institutionID: String) async throws -> (active: [PausinhaGroup], recent: [PausinhaGroup]) {
        if institutionID == "mock_institution_id" {
            let mockActive = PausinhaGroup(
                title: "Café da Tarde",
                icon: "☕️",
                institutionID: institutionID,
                creatorID: "dev_user",
                participantIDs: ["dev_user", "outro_user"],
                expiresAt: Date().addingTimeInterval(30 * 60),
                status: .active
            )
            mockActive.id = "mock_active_pausinha"
            
            let mockClosed = PausinhaGroup(
                title: "Sextou",
                icon: "🍺",
                institutionID: institutionID,
                creatorID: "outro_user",
                participantIDs: ["outro_user"],
                expiresAt: Date().addingTimeInterval(-60 * 60),
                status: .closed
            )
            mockClosed.id = "mock_closed_pausinha"
            
            return ([mockActive], [mockClosed])
        }

        // Grace period: grupos fechados há até 3 horas ainda aparecem no histórico
        let gracePeriodStart = Date().addingTimeInterval(-3 * 60 * 60)

        // Query 1: busca grupos ativos da instituição
        let activePredicate = NSPredicate(
            format: "institutionID == %@ AND status == %@",
            institutionID,
            PausinhaStatus.active.rawValue
        )
        let activeQuery = CKQuery(recordType: "PausinhaGroup", predicate: activePredicate)
        activeQuery.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        // Query 2: busca grupos fechados recentemente da instituição
        let recentPredicate = NSPredicate(
            format: "institutionID == %@ AND status == %@ AND createdAt >= %@",
            institutionID,
            PausinhaStatus.closed.rawValue,
            gracePeriodStart as NSDate
        )
        let recentQuery = CKQuery(recordType: "PausinhaGroup", predicate: recentPredicate)
        recentQuery.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        // Executa as duas queries em paralelo
        async let activeResult = publicDB.records(matching: activeQuery, resultsLimit: 100)
        async let recentResult = publicDB.records(matching: recentQuery, resultsLimit: 100)

        let (activeRecordsResult, recentRecordsResult) = try await (activeResult, recentResult)

        let activeRecords = activeRecordsResult.matchResults.compactMap { try? $0.1.get() }
        let recentRecords = recentRecordsResult.matchResults.compactMap { try? $0.1.get() }

        let active = activeRecords.map { PausinhaGroup(from: $0) }
        let recent = recentRecords.map { PausinhaGroup(from: $0) }

        return (active, recent)
    }

    // MARK: - Create

    /// Cria uma nova pausinha no banco público e a adiciona à lista local.
    @MainActor
    @discardableResult
    func createPausinha(title: String, icon: String, institutionID: String, creatorID: String, expiresAt: Date) async throws -> PausinhaGroup {
        let isDev = creatorID == "dev_user"
        
        let group = PausinhaGroup(
            title: title,
            icon: icon,
            institutionID: institutionID,
            creatorID: creatorID,
            participantIDs: [creatorID],   // O criador já entra automaticamente
            expiresAt: expiresAt,
            status: .active
        )

        if isDev {
            group.id = UUID().uuidString
            activePausinhas.insert(group, at: 0)
            LiveActivityManager.shared.startActivity(for: group)
            print("PausinhaService: Pausinha '\(title)' criada (Dev Mock)")
            return group
        }

        let record = group.getPublicRecord()

        let isICloudAvailable = await isAccountAvailable()
        if isICloudAvailable {
            do {
                let savedRecord = try await savePublicRecord(record)
                group.cloudKitRecordName = savedRecord.recordID.recordName
                print("PausinhaService: Pausinha '\(title)' criada no CloudKit.")
            } catch {
                print("PausinhaService: Warning - CloudKit save failed, proceeding with local fallback: \(error.localizedDescription)")
                group.cloudKitRecordName = "local_\(group.id)"
            }
        } else {
            print("PausinhaService: iCloud not available, creating pausinha locally.")
            group.cloudKitRecordName = "local_\(group.id)"
        }

        activePausinhas.insert(group, at: 0)
        
        // Inicia a Live Activity
        LiveActivityManager.shared.startActivity(for: group)
        
        return group
    }

    // MARK: - Update Participants

    /// Adiciona um participante ao grupo e sincroniza com o CloudKit.
    @MainActor
    func joinPausinha(_ group: PausinhaGroup, userID: String) async throws {
        let isDev = userID == "dev_user"

        group.addParticipant(userID)
        
        if isDev {
            LiveActivityManager.shared.startActivity(for: group)
            return
        }
        
        let isICloudAvailable = await isAccountAvailable()
        if isICloudAvailable {
            do {
                try await updatePausinha(group)
                print("PausinhaService: Usuário \(userID) entrou na pausinha '\(group.title)' no CloudKit")
            } catch {
                print("PausinhaService: Warning - Falha ao sincronizar entrada com CloudKit, mantendo local: \(error.localizedDescription)")
            }
        } else {
            print("PausinhaService: iCloud não disponível, salvando entrada localmente.")
        }
        
        // Inicia ou atualiza a Live Activity
        LiveActivityManager.shared.startActivity(for: group)
    }

    /// Remove um participante do grupo e sincroniza com o CloudKit.
    /// Se o grupo ficar vazio ou o grace period expirar, encerra automaticamente.
    @MainActor
    func leavePausinha(_ group: PausinhaGroup, userID: String) async throws {
        let isDev = userID == "dev_user"

        group.removeParticipant(userID)

        // Regra de negócio: grupo vazio → encerrar automaticamente
        if group.currentParticipantCount == 0 {
            group.close()
            LiveActivityManager.shared.endActivity(for: group)
            print("PausinhaService: Grupo '\(group.title)' encerrado automaticamente (sem participantes)")
        } else {
            // Se eu estou saindo mas o grupo continua, apenas encerro a minha atividade
            LiveActivityManager.shared.endActivity(for: group)
        }

        if isDev {
            refreshLocalLists(group)
            return
        }

        let isICloudAvailable = await isAccountAvailable()
        if isICloudAvailable {
            do {
                try await updatePausinha(group)
                print("PausinhaService: Usuário \(userID) saiu da pausinha '\(group.title)' no CloudKit")
            } catch {
                print("PausinhaService: Warning - Falha ao sincronizar saída com CloudKit, mantendo local: \(error.localizedDescription)")
            }
        } else {
            print("PausinhaService: iCloud não disponível, salvando saída localmente.")
        }
        
        refreshLocalLists(group)
    }

    // MARK: - Close

    /// Encerra manualmente uma pausinha (apenas o criador pode fazer isso).
    @MainActor
    func closePausinha(_ group: PausinhaGroup, requestingUserID: String) async throws {
        guard group.creatorID == requestingUserID else {
            throw PausinhaServiceError.saveFailed("Apenas o criador pode encerrar a pausinha.")
        }
        let isDev = requestingUserID == "dev_user"

        group.close()
        
        // Encerra a Live Activity local
        LiveActivityManager.shared.endActivity(for: group)
        
        if isDev {
            refreshLocalLists(group)
            return
        }
        
        let isICloudAvailable = await isAccountAvailable()
        if isICloudAvailable {
            do {
                try await updatePausinha(group)
                print("PausinhaService: Pausinha '\(group.title)' encerrada no CloudKit.")
            } catch {
                print("PausinhaService: Warning - Falha ao sincronizar encerramento com CloudKit, mantendo local: \(error.localizedDescription)")
            }
        } else {
            print("PausinhaService: iCloud não disponível, salvando encerramento localmente.")
        }
        
        refreshLocalLists(group)
    }

    /// Verifica e encerra automaticamente grupos no grace period expirado.
    @MainActor
    func closeExpiredPausinhas() async {
        let expired = activePausinhas.filter { $0.isExpiredGracePeriod }
        for group in expired {
            group.close()
            
            // Encerra a Live Activity local
            LiveActivityManager.shared.endActivity(for: group)
            
            do {
                try await updatePausinha(group)
                refreshLocalLists(group)
                print("PausinhaService: Grupo '\(group.title)' encerrado por grace period expirado.")
            } catch {
                print("PausinhaService: Erro ao encerrar grupo expirado '\(group.title)': \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    /// Sincroniza um `PausinhaGroup` modificado de volta ao CloudKit.
    private func updatePausinha(_ group: PausinhaGroup) async throws {
        let record = group.getPublicRecord()
        do {
            _ = try await savePublicRecord(record)
        } catch {
            throw PausinhaServiceError.saveFailed(error.localizedDescription)
        }
    }

    /// Salva (ou atualiza) um registro no banco público usando `CKModifyRecordsOperation`.
    private func savePublicRecord(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.savePolicy         = .changedKeys
            operation.qualityOfService   = .userInitiated
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: record)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            publicDB.add(operation)
        }
    }

    /// Move um grupo entre as listas locais após mudança de status.
    @MainActor
    private func refreshLocalLists(_ group: PausinhaGroup) {
        switch group.status {
        case .active:
            if !activePausinhas.contains(where: { $0.id == group.id }) {
                activePausinhas.insert(group, at: 0)
            }
            recentClosedPausinhas.removeAll { $0.id == group.id }
            
            // Se já tenho atividade rodando, atualizo (útil para pull-to-refresh)
            LiveActivityManager.shared.updateActivity(for: group)
            
        case .closed:
            activePausinhas.removeAll { $0.id == group.id }
            if !recentClosedPausinhas.contains(where: { $0.id == group.id }) {
                recentClosedPausinhas.insert(group, at: 0)
            }
        }
    }

    // MARK: - Real-Time Subscriptions (preparando Fase 2)

    /// Registra uma assinatura CloudKit para receber notificações push
    /// quando novas pausinhas forem criadas ou alteradas.
    /// Chamado uma vez no setup do app.
    func setupRealtimeSubscription(institutionID: String) async {
        // Verifica se a assinatura já existe para evitar duplicatas
        do {
            let existingSubscriptions = try await publicDB.allSubscriptions()
            if existingSubscriptions.contains(where: { $0.subscriptionID == subscriptionID }) {
                print("PausinhaService: Assinatura em tempo real já registrada.")
                return
            }
        } catch {
            print("PausinhaService: Erro ao verificar assinaturas: \(error)")
        }

        let predicate = NSPredicate(format: "institutionID == %@ AND status == %@", institutionID, PausinhaStatus.active.rawValue)
        let subscription = CKQuerySubscription(
            recordType: "PausinhaGroup",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // silent push
        subscription.notificationInfo = notificationInfo

        do {
            try await publicDB.save(subscription)
            print("PausinhaService: ✅ Assinatura em tempo real configurada.")
        } catch {
            print("PausinhaService: ⚠️ Falha ao configurar assinatura: \(error)")
        }
    }
}
