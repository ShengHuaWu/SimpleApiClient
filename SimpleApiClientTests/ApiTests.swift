//
//  ApiTests.swift
//  SimpleApiClient
//
//  Created by ShengHua Wu on 8/23/16.
//  Copyright © 2016 ShengHua Wu. All rights reserved.
//

import XCTest
import Alamofire
import JSONParser
@testable import SimpleApiClient

class ApiTests: XCTestCase {
    // MARK: - Private Properties
    private var api: Api!
    private var mockManager: MockManager!
    
    // MARK: - Override Methods
    override func setUp() {
        super.setUp()
        
        mockManager = MockManager()
        mockManager.expectedRequest = MockRequest()
        api = Api(manager: mockManager)
    }
    
    override func tearDown() {
        super.tearDown()
        
        api = nil
        mockManager = nil
    }
    
    // MARK: - Enabled Tests
    func testGetUserInfoWithData() {
        let expectedUser = User.userForTesting()
        let expectedData = ["data" : expectedUser.toParameters()]
        mockManager.expectedRequest?.expectedData = expectedData
        
        api.getUserInfo(expectedUser.userId) { result in
            do {
                let user = try result.unwrap()
                
                XCTAssertEqual(user.userId, expectedUser.userId)
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.email, expectedUser.email)
                XCTAssertEqual(user.description, expectedUser.description)
            } catch {
                XCTAssert(false)
            }
        }
    }
    
    func testGetUserInfoWithError() {
        let expectedError = NSError.errorForTesting()
        mockManager.expectedRequest?.expectedError = expectedError
        
        api.getUserInfo("") { result in
            do {
                _  = try result.unwrap()
                
                XCTAssert(false)
            } catch let error as NSError {
                XCTAssertEqual(error, expectedError)
            }
        }
    }
    
    func testUpdateUserInfoWithData() {
        let expectedUser = User.userForTesting()
        let expectedData = ["data" : expectedUser.toParameters()]
        mockManager.expectedRequest?.expectedData = expectedData
        
        api.updateUserInfo(expectedUser) { result in
            do {
                let user = try result.unwrap()
                
                XCTAssertEqual(user.userId, expectedUser.userId)
                XCTAssertEqual(user.name, expectedUser.name)
                XCTAssertEqual(user.email, expectedUser.email)
                XCTAssertEqual(user.description, expectedUser.description)
            } catch {
                XCTAssert(false)
            }
        }
    }
    
    func testUpdateUserInfoWithError() {
        let expectedError = NSError.errorForTesting()
        mockManager.expectedRequest?.expectedError = expectedError
        
        let user = User.userForTesting()
        api.updateUserInfo(user) { result in
            do {
                _  = try result.unwrap()
                
                XCTAssert(false)
            } catch let error as NSError {
                XCTAssertEqual(error, expectedError)
            }
        }
    }
}
