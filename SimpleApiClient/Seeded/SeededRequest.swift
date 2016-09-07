//
//  SeededRequest.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 9/7/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import Foundation
import Alamofire
import JSONParser

final class SeededRequest: ApiRequestProtocol {
    private let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func apiResponse(completionHandler: Response<JSON, NSError> -> Void) -> Self {
        guard let jsonString = NSProcessInfo.processInfo().environment[url.absoluteString],
            let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {
            fatalError("Testing URL is undefined.")
        }
        
        do {
            let json = try JSON(data: data)
            let result: Result<JSON, NSError> = .Success(json)
            let response = Response(request: nil, response: nil, data: nil, result: result)
            completionHandler(response)
        } catch {
            fatalError("Cannot parse seeded data.")
        }
        
        return self
    }
}