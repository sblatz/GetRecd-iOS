//
//  User.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import Firebase

class User {

    private(set) var name: String!
    private(set) var email: String!
    private(set) var bio: String?
    private(set) var userID: String!
    private(set) var privateMovies: Bool!
    private(set) var privateMusic: Bool!
    private(set) var privateShows: Bool!

    init(userDict: [String: Any]) {
        
        // TODO: Complete intializer once other properties have been added to the class
        
        if let userID = userDict["uid"] as? String {
            self.userID = userID
        }
        
        if let name = userDict["name"] as? String {
            self.name = name
        }
        
        if let email = userDict["email"] as? String {
            self.email = email
        }
        
        if let bio = userDict["bio"] as? String {
            self.bio = bio
        }

        if let movie = userDict["privateMovie"] as? String {
            if movie == "true" {
                self.privateMovies = true
            } else {
                self.privateMovies = false
            }
        }

        if let music = userDict["privateMusic"] as? String {
            if music == "true" {
                self.privateMusic = true
            } else {
                self.privateMusic = false
            }
        }

        if let show = userDict["privateShow"] as? String {
            if show == "true" {
                self.privateShows = true
            } else {
                self.privateShows = false
            }
        }
    }
}
