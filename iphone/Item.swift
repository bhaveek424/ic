//
//  Item.swift
//  iphone
//
//  Created by Bhaveek Jain on 12/01/26.
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
