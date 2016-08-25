//
//  Endpoint.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/19/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire

enum Endpoint {
    case GetUserInfo(userId: String)
    case UpdateUserInfo(userId: String)
    
    // MARK: - Public Properties
    var method: Alamofire.Method {
        switch self {
        case .GetUserInfo:
            return .GET
        case .UpdateUserInfo:
            return .PUT
        }
    }
    
    var url: NSURL {
        let baseUrl = NSURL.getBaseUrl()
        switch self {
        case .GetUserInfo(let userId):
            return baseUrl.URLByAppendingPathComponent("user/\(userId)")
        case .UpdateUserInfo(let userId):
            return baseUrl.URLByAppendingPathComponent("user/\(userId)")
        }
    }
}

private extension NSURL {
    static func getBaseUrl() -> NSURL {
        guard let info = NSBundle.mainBundle().infoDictionary,
            let urlString = info["Base url"] as? String,
            let url = NSURL(string: urlString) else {
            fatalError("Cannot get base url from info.plist")
        }
        
        return url
    }
}
