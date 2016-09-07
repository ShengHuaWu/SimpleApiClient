//
//  SimpleApiClientUITests.swift
//  SimpleApiClientUITests
//
//  Created by ShengHua Wu on 9/7/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import XCTest

class SimpleApiClientUITests: XCTestCase {
    // MARK: - Override Methods
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let application = XCUIApplication()
        application.launchArguments.append("UI Testing")
        
        let parameters = ["userId" : "plokmijn",
                          "name" : "shane wu",
                          "email" : "shane.wu@gmail.com",
                          "description" : "I'm shane wu"]
        let data = try! NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions(rawValue: 0))
        let jsonString = String(data: data, encoding: NSUTF8StringEncoding)
        application.launchEnvironment["http://localhost:3000/user/plokmijn"] = jsonString
        application.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testExample() {
        
    }
}
