//
//  PublicProfile.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 14/09/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class PublicProfile {
    var id: String?
    var userID: String?
    var displayName: String?
    var profileType: String?
    var profileImageData: Data?
    var isActive: Bool?
    var lastSeen: Date?
    var createdAt: Date?
    var recordID: String? // CloudKit record ID
    
    init(userID: String, displayName: String, profileType: String, profileImageData: Data? = nil) {
        self.id = "public_\(userID)" // Unique identifier combining prefix and userID
        self.userID = userID
        self.displayName = displayName
        self.profileType = profileType
        self.profileImageData = profileImageData
        self.isActive = true
        self.lastSeen = Date()
        self.createdAt = Date()
    }
    
    // CloudKit record
    func getRecord() -> CKRecord {
        let recordIDString = self.recordID ?? UUID().uuidString
        let ckRecordID = CKRecord.ID(recordName: recordIDString)
        let record = CKRecord(recordType: "PublicProfile", recordID: ckRecordID)
        record.setValue(self.userID, forKey: "userID")
        record.setValue(self.displayName, forKey: "displayName")
        record.setValue(self.profileType, forKey: "profileType")
        record.setValue(self.profileImageData, forKey: "profileImageData")
        record.setValue(self.isActive, forKey: "isActive")
        record.setValue(self.lastSeen, forKey: "lastSeen")
        record.setValue(self.createdAt, forKey: "createdAt")
        
        // Update local recordID if it wasn't set
        if self.recordID == nil {
            self.recordID = recordIDString
        }
        
        return record
    }
    
    // Update record ID after CloudKit save
    func updateRecordID(_ newRecordID: String) {
        self.recordID = newRecordID
    }
    
    // Init from CloudKit record
    init(from record: CKRecord) {
        self.id = "public_\(record["userID"] as? String ?? "")"
        self.userID = record["userID"] as? String
        self.displayName = record["displayName"] as? String
        self.profileType = record["profileType"] as? String
        self.profileImageData = record["profileImageData"] as? Data
        self.isActive = record["isActive"] as? Bool
        self.lastSeen = record["lastSeen"] as? Date
        self.createdAt = record["createdAt"] as? Date
        self.recordID = record.recordID.recordName
    }
    
    func updatePublicProfile(name: String? = nil, type: String? = nil, imageData: Data? = nil) {
        print("PublicProfile: Updating public profile - name: \(name ?? "unchanged"), type: \(type ?? "unchanged"), image: \(imageData != nil ? "updated" : "unchanged")")
        if let name = name {
            self.displayName = name
        }
        if let type = type {
            self.profileType = type
        }
        if let imageData = imageData {
            self.profileImageData = imageData
        }
        self.lastSeen = Date()
    }
    
    func updateLastSeen() {
        print("PublicProfile: Updating last seen")
        self.lastSeen = Date()
    }
}