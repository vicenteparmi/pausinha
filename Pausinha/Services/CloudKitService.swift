//
//  CloudKitService.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import Foundation
import CloudKit

@Observable
class CloudKitService {
    let container: CKContainer
    let database: CKDatabase
    
    enum CloudKitError: LocalizedError {
        case accountNotAvailable
        case networkNotAvailable
        case permissionDenied
        case recordNotFound
        case saveFailure(String)
        case fetchFailure(String)
        case deleteFailure(String)
        
        var errorDescription: String? {
            switch self {
            case .accountNotAvailable:
                return "Conta do iCloud não está disponível"
            case .networkNotAvailable:
                return "Conexão de rede não disponível"
            case .permissionDenied:
                return "Permissão negada para acessar o CloudKit"
            case .recordNotFound:
                return "Registro não encontrado"
            case .saveFailure(let message):
                return "Falha ao salvar: \(message)"
            case .fetchFailure(let message):
                return "Falha ao buscar: \(message)"
            case .deleteFailure(let message):
                return "Falha ao deletar: \(message)"
            }
        }
    }
    
    init() {
        self.container = CKContainer.default()
        // Use private database for user-specific data
        self.database = container.privateCloudDatabase
    }
    
    // Initialize CloudKit and check permissions
    func initializeCloudKit() async {
        do {
            let accountStatus = try await container.accountStatus()
            print("CloudKitService: Account status: \(accountStatus.rawValue)")

            switch accountStatus {
            case .available:
                print("CloudKitService: iCloud account is available")
                // Note: userDiscoverability permission is deprecated in iOS 17+
                // We'll handle permissions through the actual operations
            case .noAccount:
                print("CloudKitService: No iCloud account configured")
            case .restricted:
                print("CloudKitService: iCloud account is restricted")
            case .couldNotDetermine:
                print("CloudKitService: Could not determine iCloud account status")
            case .temporarilyUnavailable:
                print("CloudKitService: iCloud account is temporarily unavailable")
            @unknown default:
                print("CloudKitService: Unknown account status: \(accountStatus.rawValue)")
            }
        } catch {
            print("CloudKitService: Error checking account status: \(error)")
        }
    }

    // Request CloudKit permissions (deprecated method removed)
    // Permissions are now handled through actual CloudKit operations
    
    // Check account status
    func checkAccountStatus() async throws -> Bool {
        let status = try await container.accountStatus()
        return status == .available || status == .temporarilyUnavailable
    }
    
    // Check if CloudKit is properly configured
    func isCloudKitAvailable() async -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            if accountStatus != .available && accountStatus != .temporarilyUnavailable {
                print("CloudKitService: iCloud account not available: \(accountStatus)")
                return false
            }
            print("CloudKitService: iCloud account available or temporarily unavailable")
            return true
        } catch {
            print("CloudKitService: Error checking iCloud account status: \(error)")
            return false
        }
    }
    
    // Save or update a record using CKModifyRecordsOperation to avoid insert collisions
    func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        print("CloudKitService: Saving record of type \(record.recordType) with ID \(record.recordID.recordName) via modify operation")
        // Ensure iCloud account available
        guard await isCloudKitAvailable() else {
            throw CloudKitError.accountNotAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    print("CloudKitService: Successfully modified record with ID \(record.recordID.recordName)")
                    continuation.resume(returning: record)
                case .failure(let error):
                    let ckError = error as? CKError ?? CKError(.unknownItem)
                    print("CloudKitService: Error modifying record: \(ckError.localizedDescription)")
                    continuation
                        .resume(throwing: self.mapCloudKitError(ckError))
                }
            }
            database.add(operation)
        }
    }
    
    // Save multiple records in batch
    func saveRecords(_ records: [CKRecord]) async throws -> [CKRecord] {
        print("CloudKitService: Batch saving \(records.count) records")
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success():
                    let savedRecords = records // Records are modified in place
                    print("CloudKitService: Successfully batch saved \(savedRecords.count) records")
                    continuation.resume(returning: savedRecords)
                case .failure(let error):
                    print("CloudKitService: Batch save failed: \(error.localizedDescription)")
                    continuation
                        .resume(
                            throwing: self
                                .mapCloudKitError(
                                    error as? CKError ?? error as! CKError
                                )
                        )
                }
            }
            
            database.add(operation)
        }
    }
    
    // Fetch a record by ID
    func fetchRecord(withID recordID: CKRecord.ID) async throws -> CKRecord {
        print("CloudKitService: Fetching record with ID \(recordID.recordName)")
        
        do {
            let record = try await database.record(for: recordID)
            print("CloudKitService: Successfully fetched record")
            return record
        } catch let error as CKError {
            print("CloudKitService: CloudKit error fetching record: \(error.localizedDescription)")
            throw mapCloudKitError(error)
        } catch {
            print("CloudKitService: Unexpected error fetching record: \(error.localizedDescription)")
            throw CloudKitError.fetchFailure(error.localizedDescription)
        }
    }
    
    // Delete a record
    func deleteRecord(withID recordID: CKRecord.ID) async throws {
        print("CloudKitService: Deleting record with ID \(recordID.recordName)")
        
        do {
            _ = try await database.deleteRecord(withID: recordID)
            print("CloudKitService: Successfully deleted record")
        } catch let error as CKError {
            print("CloudKitService: CloudKit error deleting record: \(error.localizedDescription)")
            throw mapCloudKitError(error)
        } catch {
            print("CloudKitService: Unexpected error deleting record: \(error.localizedDescription)")
            throw CloudKitError.deleteFailure(error.localizedDescription)
        }
    }
    
    // Fetch records by type and predicate
    func fetchRecords(ofType recordType: String, predicate: NSPredicate, limit: Int = 100) async throws -> [CKRecord] {
        print("CloudKitService: Fetching records of type \(recordType) with predicate")
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        do {
            let result = try await database.records(matching: query, resultsLimit: limit)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            print("CloudKitService: Successfully fetched \(records.count) records")
            return records
        } catch let error as CKError {
            print("CloudKitService: CloudKit error fetching records: \(error.localizedDescription)")
            throw mapCloudKitError(error)
        } catch {
            print("CloudKitService: Unexpected error fetching records: \(error.localizedDescription)")
            throw CloudKitError.fetchFailure(error.localizedDescription)
        }
    }

    // Fetch all records of a type
    func fetchRecords(ofType recordType: String, limit: Int = 100) async throws -> [CKRecord] {
        print("CloudKitService: Fetching records of type \(recordType)")
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let result = try await database.records(matching: query, resultsLimit: limit)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            print("CloudKitService: Successfully fetched \(records.count) records")
            return records
        } catch let error as CKError {
            print("CloudKitService: CloudKit error fetching records: \(error.localizedDescription)")
            throw mapCloudKitError(error)
        } catch {
            print("CloudKitService: Unexpected error fetching records: \(error.localizedDescription)")
            throw CloudKitError.fetchFailure(error.localizedDescription)
        }
    }
    
    // Map CloudKit errors to our custom errors
    private func mapCloudKitError(_ error: CKError?) -> Error {
        guard let ckError = error else {
            return CloudKitError.saveFailure("Erro desconhecido")
        }
        
        switch ckError.code {
        case .notAuthenticated:
            return CloudKitError.accountNotAvailable
        case .networkUnavailable, .networkFailure:
            return CloudKitError.networkNotAvailable
        case .permissionFailure:
            return CloudKitError.permissionDenied
        case .unknownItem:
            return CloudKitError.recordNotFound
        default:
            return CloudKitError.saveFailure(ckError.localizedDescription)
        }
    }
}
