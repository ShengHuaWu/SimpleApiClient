//
//  SimpleApiClientUITests.swift
//  SimpleApiClientUITests
//
//  Created by ShengHua Wu on 9/7/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import XCTest
@testable import SimpleApiClient

class SimpleApiClientUITests: XCTestCase {
    // MARK: - Override Methods
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Enabled Tests
    func testExample() {
        
    }
}
