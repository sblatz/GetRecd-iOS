//
//  AuthService.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/3/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AuthService {
    // Static variable used to call AuthService functions
    static let instance = AuthService()
    private var authInstance: Auth?

    func createAccountWithEmail(email: String, password: String, responseHandler: @escaping (String) -> (Void)) {
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error == nil {
                self.authInstance = Auth.auth()
                responseHandler("")
            } else {
                responseHandler(error!.localizedDescription)
            }
        }
    }

    func signInWithEmail(email: String, password: String, responseHandler: @escaping (String) -> (Void)) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if error == nil {
                self.authInstance = Auth.auth()
                responseHandler("")
            } else {
                responseHandler(error!.localizedDescription)
            }
        }
    }

    func isAuthenticated() -> Bool {
        return authInstance != nil
    }

    func getUserUid() -> String {
        return isAuthenticated() ? authInstance!.currentUser!.uid : ""
    }

    func signOut() {
        if authInstance != nil {
            do {
                try authInstance!.signOut()
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }
    }
}
