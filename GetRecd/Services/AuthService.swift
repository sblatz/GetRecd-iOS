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
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.authInstance = Auth.auth()
            guard let user = user else {return}
            var userData = [String:Any]()
            userData["name"] = user.displayName
            userData["email"] = user.email
            userData["profilePictureURL"] = user.photoURL?.absoluteString
            DataService.instance.createOrUpdateUser(uid: user.uid, userData: userData)
            DispatchQueue.main.async {
                let viewController = signIn.uiDelegate as! UIViewController
                viewController.performSegue(withIdentifier: "RecFeed", sender: viewController)
            }
        }
    }

    func googleAuthenticate(forViewController controller: AuthenticationViewController) {
        GIDSignIn.sharedInstance().uiDelegate = controller
        GIDSignIn.sharedInstance().signIn()
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
                    }
                    let graphConnection = GraphRequestConnection()
                    graphConnection.add(GraphRequest(graphPath: "/me", parameters: ["fields": "email, name, picture"], accessToken: accessToken)) { (httpResponse, result) in
                        switch result {
                        case .success(let response):
                            self.authInstance = Auth.auth()
                            guard let user = user else {return}
                            var userData = [String:Any]()
                            userData["name"] = response.dictionaryValue?["name"]
                            userData["email"] = response.dictionaryValue?["email"]
                            userData["profilePictureURL"] = ((response.dictionaryValue?["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String
                            DataService.instance.createOrUpdateUser(uid: user.uid, userData: userData)
                            controller.performSegue(withIdentifier: "RecFeed", sender: controller)
                        case .failed(let error):
                            print(error)
                        }
                    }
                    graphConnection.start()
                }
            case .cancelled:
                print("Cancelled Facebook login.")
            case .failed(let error):
                print(error)
            }
        }
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
    
    
    func deleteAccount(success: @escaping (Bool) -> (Void)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        DataService.instance.deleteUser(uid: uid)
        Auth.auth().currentUser?.delete(completion: { (error) in
            if error != nil {
                success(false)
                print("Error deleting user: \(String(describing: error))")
            } else {
                success(true)
            }
        })
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
