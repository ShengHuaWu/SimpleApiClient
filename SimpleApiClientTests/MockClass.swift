//
//  MockClass.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/23/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire
import JSONParser
@testable import SimpleApiClient

class MockManager: ApiManagerProtocol {
    var expectedRequest: MockRequest?
    
    func apiRequest(endpoint: Endpoint, parameters: [String : AnyObject]?, headers: [String : String]?) -> ApiRequestProtocol {
        guard let request = expectedRequest else {
            fatalError("Request is empty.")
        }
        return request
    }
}

class MockRequest: ApiRequestProtocol {
    var expectedData: [String : AnyObject]?
    var expectedError: NSError?
    
    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        if let data = expectedData {
            let result: Result<JSON, NSError> = .Success(JSON(object: data))
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } else if let error = expectedError {
            let result: Result<JSON, NSError> = .Failure(error)
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } else {
            fatalError("Both data and error are empty.")
        }
        
        return self
    }
}
