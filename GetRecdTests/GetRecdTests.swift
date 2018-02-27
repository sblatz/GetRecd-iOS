//
//  GetRecdTests.swift
//  GetRecdTests
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import XCTest

@testable import GetRecd

class GetRecdTests: XCTestCase {
    var dataService: DataService!

    override func setUp() {
        super.setUp()
        dataService = DataService()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
