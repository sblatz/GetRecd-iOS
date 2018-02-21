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

class AuthService: NSObject, GIDSignInDelegate {
    // Static variable used to call AuthService functions
    static let instance = AuthService()
    private var authInstance: Auth?

    private override init() {
        super.init()
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                accessToken: authentication.accessToken)

        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            var userData = [String:Any]()
            if (user!.displayName != nil) {
                userData["name"] = user?.displayName!
            }
            if (user!.email != nil) {
                userData["email"] = user?.email!
            }
            if (user!.photoURL != nil) {
                userData["photoURL"] = user?.photoURL!.absoluteString
            }
            DataService.instance.createOrUpdateUser(uid: user!.uid, userData: userData)
            // Show the home screen.
        }
    }

    func googleAuthenticate(forViewController controller: GIDSignInUIDelegate) {
        GIDSignIn.sharedInstance().uiDelegate = controller
        GIDSignIn.sharedInstance().signIn()
    }

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

    func signOut(success: @escaping (Bool) -> (Void)) {
        if authInstance != nil {
            do {
                try authInstance!.signOut()
            } catch let signOutError as NSError {
                success(false)
                print("Error signing out: %@", signOutError)
            }
            
            success(true)
        }
    }
    
    
    func deleteAccount(success: @escaping (Bool) -> (Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        DataService.instance.deleteUser(uid: uid)
        Auth.auth().currentUser?.delete(completion: { (error) in
            if error != nil {
                success(false)
                print("DELETE USER ERROR: \(String(describing: error))")
            } else {
                success(true)
            }
        })
    }
}
