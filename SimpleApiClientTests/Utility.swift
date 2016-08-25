//
//  Utility.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/25/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
@testable import SimpleApiClient

extension User {
    static func userForTesting() -> User {
        return User(userId: "plokmijn", name: "shane wu", email: "shane.wu@gmail.com", description: "I'm shane wu.")
    }
}

extension NSError {
    static func errorForTesting() -> NSError {
        let reason = "This is a preset error."
        return NSError(domain: "com.shenghuawu.simpleapiclient", code: 8787, userInfo: [NSLocalizedDescriptionKey : reason])
    }
}
