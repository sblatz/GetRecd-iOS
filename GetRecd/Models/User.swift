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
    }
}
