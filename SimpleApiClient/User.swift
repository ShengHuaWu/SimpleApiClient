//
//  User.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/22/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import JSONParser

struct User {
    let userId: String
    var name: String
    var email: String
    var description: String?
}

extension User {
    init(json: JSON) {
        userId = json["userId"].stringValue
        name = json["name"].stringValue
        email = json["email"].stringValue
        description = json["description"].string
    }
    
    func toParameters() -> [String : AnyObject] {
        var parameters = ["userId" : userId, "name" : name, "email" : email]
        if let description = description {
            parameters["description"] = description
        }
        
        return parameters
    }
}
