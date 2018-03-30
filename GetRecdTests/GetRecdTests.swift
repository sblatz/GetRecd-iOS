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
    
    func testSpotifyRecommendations() {
        let expectation = XCTestExpectation(description: "Spotify Recommendations")
        expectation.expectedFulfillmentCount = 1
        AuthService.instance.signInWithEmail(email: "tester@tester.com", password: "123456") { (info) -> (Void) in
           
            MusicService.sharedInstance.getSpotifyRecommendations { (songs, error) in
                if let error = error {
                    XCTFail(error.localizedDescription)
                } else {
                    expectation.fulfill()
                }
            }
        }
        
        XCTWaiter().wait(for: [expectation], timeout: 10)
    }
    
    func testMovieRecommendations() {
        let expectation = XCTestExpectation(description: "Movie Recommendations")
        expectation.expectedFulfillmentCount = 1
        AuthService.instance.signInWithEmail(email: "tester@tester.com", password: "123456") { (info) -> (Void) in
            
            MovieService.sharedInstance.getRecommendedMovies(id: "12", success: { (movies) in
                expectation.fulfill()
            })
        }
        
        XCTWaiter().wait(for: [expectation], timeout: 10)
    }
    
    func testShowRecommendations() {
        let expectation = XCTestExpectation(description: "Show Recommendations")
        expectation.expectedFulfillmentCount = 1
        AuthService.instance.signInWithEmail(email: "tester@tester.com", password: "123456") { (info) -> (Void) in
            
            TVService.sharedInstance.getRecommendedTV(id: "2316", success: { (shows) in
                expectation.fulfill()
            })
        }
        
        XCTWaiter().wait(for: [expectation], timeout: 10)
    }
    
}
