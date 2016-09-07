//
//  SeededManager.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 9/7/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire

final class SeededManager: ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol {
        return SeededRequest(url: endpoint.url)
    }
}
