//
//  ApiProtocol.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/23/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire
import JSONParser

protocol ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol
}

extension ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint) -> ApiRequestProtocol {
        return apiRequest(endpoint, parameters: nil, headers: nil)
    }
    
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?) -> ApiRequestProtocol {
        return apiRequest(endpoint, parameters: parameters, headers: nil)
    }
}

protocol ApiRequestProtocol {
    func apiResponse(completionHandler: Alamofire.Response<JSON, NSError> -> Void) -> Self
}

func += <K, V> (inout left: [K : V], right: [K : V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

extension Alamofire.Manager: ApiManagerProtocol {
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]? = nil, headers: [String : String]? = nil) -> ApiRequestProtocol {
        // Insert your common headers here, for example, authorization token or accept.
        var commonHeaders = ["Accept" : "application/json"]
        if let headers = headers {
            commonHeaders += headers
        }
        
        return request(endpoint.method, endpoint.url, parameters: parameters, headers: commonHeaders)
    }
}

extension Alamofire.Request: ApiRequestProtocol {
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
    
    func apiResponse(completionHandler: Alamofire.Response<JSON, NSError> -> Void) -> Self {
        return response(responseSerializer: Alamofire.Request.apiResponseSerializer(), completionHandler: completionHandler)
    }
}
