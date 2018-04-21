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

class AuthService: NSObject {
    // Static variable used to call AuthService functions
    static let instance = AuthService()
    static let sharedInstance = AuthService()
    
    func createAccountWithEmail(userInfo: [String: String], success: @escaping (User) -> (), failure: @escaping (Error) -> ()) {
        var userInfo = userInfo
        Auth.auth().createUser(withEmail: userInfo["email"]!, password: userInfo["password"]!) { (user, error) in
            if let error = error {
                failure(error)
            } else if let user = user {
                userInfo["password"] = nil
                userInfo["uid"] = user.uid
                userInfo["privateMovie"] = "false"
                userInfo["privateShow"] = "false"
                userInfo["privateMusic"] = "false"

                DataService.sharedInstance.createUser(uid: user.uid, userData: userInfo, success: { (user) in
                    success(user)
                }, failure: { (error) in
                    print(error.localizedDescription)
                    failure(error)
                })
            }
        }
    }
    
    func signInWithEmail(email: String, password: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                failure(error)
            } else {
                success()
            }
        }
    }
    
    func facebookAuthenticate(forViewController controller: AuthenticationViewController) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: controller) { (loginResult) in
            switch loginResult {
            case .success(_, _, let accessToken):
                let firebaseCredential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                Auth.auth().signIn(with: firebaseCredential) { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    } else if let user = user {
                        let graphConnection = GraphRequestConnection()
                        graphConnection.add(GraphRequest(graphPath: "/me", parameters: ["fields": "email, name, picture"], accessToken: accessToken)) { (httpResponse, result) in
                            switch result {
                            case .success(let response):
                                var userData = [String:Any]()
                                userData["name"] = response.dictionaryValue?["name"]
                                userData["email"] = response.dictionaryValue?["email"]
                                userData["profilePictureURL"] = ((response.dictionaryValue?["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String
                                DataService.sharedInstance.createUser(uid: user.uid, userData: userData, success: { (user) in
                                    controller.performSegue(withIdentifier: "RecFeed", sender: controller)
                                }, failure: { (error) in
                                    // TODO: Make controller display error
                                    print(error.localizedDescription)
                                })
                                
                            case .failed(let error):
                                print(error)
                            }
                        }
                        graphConnection.start()
                    }
                    
                }
            case .cancelled:
                print("Cancelled Facebook login.")
            case .failed(let error):
                print(error)
            }
        }
    }

    func signOut(success: @escaping (Bool) -> (Void)) {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                success(true)
            } catch let signOutError as NSError {
                success(false)
                print("Error signing out: %@", signOutError)
            }
        } else {
            success(true)
        }
    }
    
    
    func resetPassword(email: String, success: @escaping (Bool) -> (Void)) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if error != nil {
                return success(false)
            } else {
               return success(true)
            }
        }
    }
}

extension AuthService: GIDSignInDelegate {
    func setupGoogle() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()!.options.clientID
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let user = user else {return}
            var userData = [String:Any]()
            userData["name"] = user.displayName
            userData["email"] = user.email
            userData["profilePictureURL"] = user.photoURL?.absoluteString
            DataService.sharedInstance.createUser(uid: user.uid, userData: userData, success: { (user) in
                DispatchQueue.main.async {
                    let viewController = signIn.uiDelegate as! UIViewController
                    viewController.performSegue(withIdentifier: "RecFeed", sender: viewController)
                }
            }, failure: { (error) in
                print(error.localizedDescription)
            })
            
        }
    }
    
    func googleAuthenticate(forViewController controller: AuthenticationViewController) {
        GIDSignIn.sharedInstance().uiDelegate = controller
        GIDSignIn.sharedInstance().signIn()
    }
}
