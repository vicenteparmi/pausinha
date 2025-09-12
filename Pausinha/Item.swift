//
//  Item.swift
//  Pausinha
//
//  Created by Vicente Parmigiani on 12/09/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
