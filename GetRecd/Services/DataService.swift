//
//  DataService.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseStorage

class DataService {
    // Static instance variable used to call DataService functions
    static let instance = DataService()
    private var _REF_USERS = Database.database().reference().child("Users")

    // Firebase Storage reference (TODO: Need to create storage)
    private var _REF_PROFILE_PICS = Storage.storage().reference().child("profile-pics")
    
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    var REF_PROFILE_PICS: StorageReference {
        return _REF_PROFILE_PICS
    }
    
    // Adds/updates user's entry in the Firebase database
    func createOrUpdateUser(uid: String, userData: [String:Any]) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
    
    // Retrives user based on userID/user's key in Firebase
    func getUser(userID: String,  handler: @escaping (_ user: User) -> ()) {
        DataService.instance.REF_USERS.child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            guard let userDict = snapshot.value as? [String:Any] else {
                print("ERROR GETTING USER DICT")
                return
            }
            
            let user = User(userDict: userDict, userID: snapshot.key)
            handler(user)
            return
        }) { (error) in
            print("ERROR \(error.localizedDescription)")
            return
        }
    }
    
    // Gets a user's profile picture from Firebase Storage
    func getProfilePicture(user: User, handler: @escaping (_ image: UIImage) -> ()) {
        guard let url = URL(string: user.profilePictureURL) else {
            return
        }
        
        let session = URLSession(configuration: .default)
        
        //creating a dataTask to get profile picture
        let getImageFromUrl = session.dataTask(with: url) { (data, response, error) in
            
            if error != nil {
                //displaying the message
                print("Error downloading image: \(String(describing: error))")
            } else {
                guard let _ = response as? HTTPURLResponse else {
                    print("No response from server")
                    return
                }
                
                if let imageData = data {
                    guard let image = UIImage(data: imageData) else {
                        return
                    }
                    
                    handler(image)
                    return
                } else {
                    print("Image file is corrupted")
                }
            }
        }
        
        getImageFromUrl.resume()
    }
}
