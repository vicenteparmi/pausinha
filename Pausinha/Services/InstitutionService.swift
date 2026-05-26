//
//  InstitutionService.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import Foundation
import CloudKit
import Observation

@Observable
final class InstitutionService {
    var isLoading: Bool = false
    var lastError: String?
    
    // Shared cache to bridge state between different view instances (like InstitutionSelectionView and HomeView)
    static var cache: [String: Institution] = [:]
    
    private let container = CKContainer.default()
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    
    // Check if iCloud account is available
    func isAccountAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available || status == .temporarilyUnavailable
        } catch {
            print("InstitutionService: Erro ao verificar conta iCloud: \(error)")
            return false
        }
    }
    
    // Create Institution
    func createInstitution(name: String, creatorID: String) async throws -> Institution {
        let isDev = creatorID == "dev_user"
        
        isLoading = true
        lastError = nil
        
        // Generate a 6-character alphanumeric join code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let joinCode = String((0..<6).map { _ in characters.randomElement()! })
        
        let institution = Institution(name: name, joinCode: joinCode, creatorID: creatorID)
        let record = institution.getPublicRecord()
        
        do {
            if isDev {
                try await Task.sleep(nanoseconds: 300_000_000)
                InstitutionService.cache[institution.id] = institution
                isLoading = false
                return institution
            }
            
            // Check if iCloud account is available. If so, attempt to save to CloudKit.
            let isICloudAvailable = await isAccountAvailable()
            if isICloudAvailable {
                do {
                    let savedRecord = try await savePublicRecord(record)
                    institution.cloudKitRecordName = savedRecord.recordID.recordName
                } catch {
                    print("InstitutionService: Warning - CloudKit save failed, proceeding with local fallback: \(error.localizedDescription)")
                    institution.cloudKitRecordName = "local_\(institution.id)"
                }
            } else {
                print("InstitutionService: iCloud not available, creating institution locally.")
                institution.cloudKitRecordName = "local_\(institution.id)"
            }
            
            InstitutionService.cache[institution.id] = institution
            isLoading = false
            return institution
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // Join Institution
    func joinInstitution(code: String) async throws -> Institution {
        let isDev = UserDefaults.standard.string(forKey: "appleUserID") == "dev_user"
        
        isLoading = true
        lastError = nil
        
        let predicate = NSPredicate(format: "joinCode == %@", code.uppercased())
        let query = CKQuery(recordType: "Institution", predicate: predicate)
        
        do {
            if isDev {
                try await Task.sleep(nanoseconds: 300_000_000)
                let mockInstitution = Institution(name: "Academy Dev Local", joinCode: code.uppercased(), creatorID: "dev_user")
                mockInstitution.id = "mock_institution_id"
                InstitutionService.cache[mockInstitution.id] = mockInstitution
                isLoading = false
                return mockInstitution
            }
            
            let isICloudAvailable = await isAccountAvailable()
            if isICloudAvailable {
                do {
                    let result = try await publicDB.records(matching: query, resultsLimit: 1)
                    let records = result.matchResults.compactMap { try? $0.1.get() }
                    
                    if records.isEmpty {
                        print("DEBUG: joinInstitution retornou 0 records para o código \(code.uppercased())")
                        throw NSError(domain: "InstitutionService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Instituição não encontrada com esse código."])
                    }
                    
                    guard let firstRecord = records.first else {
                        throw NSError(domain: "InstitutionService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Instituição não encontrada com esse código."])
                    }
                    
                    let institution = Institution(from: firstRecord)
                    InstitutionService.cache[institution.id] = institution
                    
                    // Check if current user is blocked
                    if let userID = UserDefaults.standard.string(forKey: "appleUserID"),
                       institution.blockedUserIDs.contains(userID) {
                        throw NSError(domain: "InstitutionService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Você foi bloqueado(a) de ingressar nesta instituição."])
                    }
                    
                    isLoading = false
                    return institution
                } catch {
                    // Se for um erro específico de negócio (404 ou 403), propaga o erro.
                    if (error as NSError).domain == "InstitutionService" {
                        throw error
                    }
                    // Caso contrário, é erro de rede/iCloud. Faz o fallback.
                    print("InstitutionService: Warning - CloudKit join failed, using local offline fallback: \(error.localizedDescription)")
                }
            }
            
            // Fallback: criar instituição local fictícia com o código inserido
            let fallbackInstitution = Institution(name: "Instituição \(code.uppercased()) (Local)", joinCode: code.uppercased(), creatorID: "local_creator")
            fallbackInstitution.id = "local_\(code.uppercased())"
            InstitutionService.cache[fallbackInstitution.id] = fallbackInstitution
            isLoading = false
            return fallbackInstitution
            
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // Fetch Institution by ID
    func fetchInstitution(id: String) async throws -> Institution {
        if let cached = InstitutionService.cache[id] {
            return cached
        }
        
        let recordID = CKRecord.ID(recordName: id)
        
        do {
            let record = try await publicDB.record(for: recordID)
            let institution = Institution(from: record)
            InstitutionService.cache[id] = institution
            // Return without failing if blocked, but caller needs to know to kick user out
            return institution
        } catch let error as CKError {
            if error.code == .unknownItem {
                throw NSError(domain: "InstitutionService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Instituição não encontrada."])
            }
            throw error
        } catch {
            throw error
        }
    }
    
    // Update Institution (owner only)
    func updateInstitution(_ institution: Institution) async throws {
        isLoading = true
        lastError = nil
        let record = institution.getPublicRecord()
        do {
            _ = try await savePublicRecord(record)
            InstitutionService.cache[institution.id] = institution
            isLoading = false
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // Delete Institution (owner only)
    func deleteInstitution(_ institution: Institution) async throws {
        isLoading = true
        lastError = nil
        
        let recordName = institution.cloudKitRecordName ?? institution.id
        let recordID = CKRecord.ID(recordName: recordName)
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
                operation.qualityOfService = .userInitiated
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        InstitutionService.cache.removeValue(forKey: institution.id)
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                self.publicDB.add(operation)
            }
            isLoading = false
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // Fetch Members of an Institution
    func fetchMembers(institutionID: String) async throws -> [PublicProfile] {
        isLoading = true
        lastError = nil
        let predicate = NSPredicate(format: "institutionID == %@", institutionID)
        let query = CKQuery(recordType: "PublicProfile", predicate: predicate)
        
        do {
            let result = try await publicDB.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            let members = records.map { PublicProfile(from: $0) }
            isLoading = false
            return members
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // Fetch user's created institutions
    func fetchMyInstitutions(userID: String) async throws -> [Institution] {
        if userID == "dev_user" {
            let mock1 = Institution(name: "Academy Dev Local", joinCode: "DEV123", creatorID: userID)
            mock1.id = "mock_institution_id"
            InstitutionService.cache[mock1.id] = mock1
            return [mock1]
        }
        
        isLoading = true
        lastError = nil
        
        print("DEBUG: Iniciando fetchMyInstitutions para userID: \(userID)")
        
        let predicate = NSPredicate(format: "creatorID == %@", userID)
        let query = CKQuery(recordType: "Institution", predicate: predicate)
        
        do {
            let result = try await publicDB.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            let institutions = records.map { Institution(from: $0) }
            
            print("DEBUG: Encontradas \(institutions.count) instituições filtradas para o criador.")
            
            // Cache them
            for inst in institutions {
                InstitutionService.cache[inst.id] = inst
            }
            
            isLoading = false
            return institutions
        } catch {
            self.lastError = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    private func savePublicRecord(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
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
}
