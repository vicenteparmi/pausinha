//
//  UserProfile.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 13/09/25.
//

import Foundation
import SwiftData
import CloudKit

@Model
final class UserProfile {
    var userID: String?
    var userName: String?
    var profileType: String?
    var profileImageData: Data?
    var isPublic: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    var recordID: String? // CloudKit record ID
    var institutionID: String?
    
    init(userID: String, userName: String, profileType: String = "Bondiano", profileImageData: Data? = nil, isPublic: Bool = true, institutionID: String? = nil) {
        self.userID = userID
        self.userName = userName
        self.profileType = profileType
        self.profileImageData = profileImageData
        self.isPublic = isPublic
        self.institutionID = institutionID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // CloudKit record
    func getRecord() -> CKRecord {
        let recordIDString = self.recordID ?? UUID().uuidString
        let ckRecordID = CKRecord.ID(recordName: recordIDString)
        let record = CKRecord(recordType: "UserProfile", recordID: ckRecordID)
        record.setValue(self.userID, forKey: "userID")
        record.setValue(self.userName, forKey: "userName")
        record.setValue(self.profileType, forKey: "profileType")
        record.setValue(self.profileImageData, forKey: "profileImageData")
        record.setValue(self.isPublic, forKey: "isPublic")
        record.setValue(self.institutionID, forKey: "institutionID")
        record.setValue(self.createdAt, forKey: "createdAt")
        record.setValue(self.updatedAt, forKey: "updatedAt")
        
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
        self.userID = record["userID"] as? String
        self.userName = record["userName"] as? String
        self.profileType = record["profileType"] as? String
        self.profileImageData = record["profileImageData"] as? Data
        self.isPublic = record["isPublic"] as? Bool
        self.institutionID = record["institutionID"] as? String
        self.createdAt = record["createdAt"] as? Date
        self.updatedAt = record["updatedAt"] as? Date
        self.recordID = record.recordID.recordName
    }
    
    func updateProfile(name: String? = nil, type: String? = nil, imageData: Data? = nil, isPublic: Bool? = nil, institutionID: String? = nil) {
        print("UserProfile: Updating profile - name: \(name ?? "unchanged"), type: \(type ?? "unchanged"), image: \(imageData != nil ? "updated" : "unchanged"), public: \(isPublic.map { String($0) } ?? "unchanged"), institutionID: \(institutionID ?? "unchanged")")
        if let name = name {
            self.userName = name
        }
        if let type = type {
            self.profileType = type
        }
        if let imageData = imageData {
            self.profileImageData = imageData
        }
        if let isPublic = isPublic {
            self.isPublic = isPublic
        }
        if let institutionID = institutionID {
            self.institutionID = institutionID
        }
        self.updatedAt = Date()
    }
    
    func clearInstitutionID() {
        print("UserProfile: Clearing institutionID")
        self.institutionID = nil
        self.updatedAt = Date()
    }
}