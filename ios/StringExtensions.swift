//
//  StringExtensions.swift
//  CustomerioReactnative
//
//  Created by Levi Bostian on 3/22/23.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation

internal extension StringProtocol {
    // Uppercase the first character without modifying the rest of the string.
    // "notDeteremined" -> "NotDetermined"
    // "notdetermined" -> "Notdeteremined"
    // "not determined" -> "Not determined"
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
}
