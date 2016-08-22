//
//  Api.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/22/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire
import JSONParser

final class Api {
    // MARK: - Private Properties
    private let manager: Alamofire.Manager
    
    // MARK: - Designated Initializer
    init(manager: Alamofire.Manager = Alamofire.Manager.sharedInstance) {
        self.manager = manager
    }
}

private func += <K, V> (inout left: [K : V], right: [K : V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

private extension Alamofire.Manager {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil) -> Alamofire.Request {
        // Insert your common headers here, for example, authorization token or accept.
        var commonHeaders = ["Accept" : "application/json"]
        if let headers = headers {
            commonHeaders += headers
        }
        
        return request(endpoint.method, endpoint.url, parameters: parameters, headers: commonHeaders)
    }
}

private extension Alamofire.Request {
    static func apiResponseSerializer() -> Alamofire.ResponseSerializer<JSON, NSError> {
        return Alamofire.ResponseSerializer { _, _, data, error in
            if let error = error {
                return .Failure(error)
            }
            
            guard let validData = data else {
                let reason = "Data could not be serialized. Input data was nil."
                return .Failure(NSError(domain: "com.shenghuawu.simpleapiclient", code: 1001, userInfo: [NSLocalizedDescriptionKey : reason]))
            }
            
            do {
                let json = try JSON(data: validData)
                // TODO: Should consider HTTP response as well.
                return sanitizeError(json)
            } catch let error as NSError {
                return .Failure(error)
            }
        }
    }
    
    static func sanitizeError(json: JSON) -> Alamofire.Result<JSON, NSError> {
        if json["error"].object == nil {
            return .Success(json)
        }
        
        let code = json["error"]["code"].intValue
        let message = json["error"]["message"].stringValue
        let error = NSError(domain: "com.shenghuawu.simpleapiclient", code: code, userInfo: [NSLocalizedDescriptionKey : message])
        return .Failure(error)
    }
    
    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        return response(responseSerializer: Request.apiResponseSerializer(), completionHandler: completionHandler)
    }
}
