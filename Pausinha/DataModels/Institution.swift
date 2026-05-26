//
//  Institution.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 18/05/26.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class Institution {
    var id: String = UUID().uuidString
    var name: String = ""
    var joinCode: String = ""
    var creatorID: String = ""
    var blockedUserIDs: [String] = []
    var createdAt: Date = Date()
    var cloudKitRecordName: String?
    
    init(name: String, joinCode: String, creatorID: String) {
        self.id = UUID().uuidString
        self.name = name
        self.joinCode = joinCode
        self.creatorID = creatorID
        self.createdAt = Date()
    }
    
    // MARK: - CloudKit Interop
    
    func getPublicRecord() -> CKRecord {
        let recordName = self.cloudKitRecordName ?? self.id
        let ckRecordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: "Institution", recordID: ckRecordID)
        
        record["id"] = self.id as CKRecordValue
        record["name"] = self.name as CKRecordValue
        record["joinCode"] = self.joinCode as CKRecordValue
        record["creatorID"] = self.creatorID as CKRecordValue
        
        // Save string array as JSON data since CKRecord doesn't support string arrays easily in all setups, or use NSArray
        record["blockedUserIDs"] = self.blockedUserIDs as CKRecordValue
        
        record["createdAt"] = self.createdAt as CKRecordValue
        
        if self.cloudKitRecordName == nil {
            self.cloudKitRecordName = recordName
        }
        
        return record
    }
    
    convenience init(from record: CKRecord) {
        self.init(
            name: record["name"] as? String ?? "Institution",
            joinCode: record["joinCode"] as? String ?? "",
            creatorID: record["creatorID"] as? String ?? ""
        )
        
        if let serverID = record["id"] as? String {
            self.id = serverID
        }
        if let blocked = record["blockedUserIDs"] as? [String] {
            self.blockedUserIDs = blocked
        }
        if let createdAt = record["createdAt"] as? Date {
            self.createdAt = createdAt
        }
        self.cloudKitRecordName = record.recordID.recordName
    }
}
