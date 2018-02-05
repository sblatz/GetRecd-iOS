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

    private var _firstName: String!
    private var _lastName: String!
    private var _fullName: String!
    private var _email: String!
    private var _userID: String!
    private var _profilePictureURL: String?
    
    // TODO: Add other user class properties (include private variables with getters)
    
    var firstName: String {
        return _firstName
    }
    
    var lastName: String {
        return _lastName
    }
    
    var fullName: String {
        return _fullName
    }
    
    var email: String {
        return _email
    }
    
    var userID: String {
        return _userID
    }
    
    var profilePictureURL: String {
        return _profilePictureURL ?? ""
    }
    
    init(userDict: [String:Any], userID: String) {
        
        // TODO: Complete intializer once other properties have been added to the class
        
        self._userID = userID
        
        if let firstName = userDict["firstName"] as? String {
            self._firstName = firstName
        }
        
        if let lastName = userDict["lastName"] as? String {
            self._lastName = lastName
        }
        
        if let fullName = userDict["fullName"] as? String {
            self._fullName = fullName
        }
        
        if let email = userDict["email"] as? String {
            self._email = email
        }
        
        if let profilePictureURL = userDict["profilePictureURL"] as? String {
            self._profilePictureURL = profilePictureURL
        }
    }
}
