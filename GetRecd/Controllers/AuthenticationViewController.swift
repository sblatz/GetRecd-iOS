//
//  AuthenticationViewController.swift
//  GetRecd
//
//  Created by Martin Tuskevicius on 2/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import GoogleSignIn

class AuthenticationViewController: UIViewController, GIDSignInUIDelegate {
 
    @IBAction func googleSignInButtonPressed(_ sender: Any) {
        AuthService.instance.googleAuthenticate(forViewController: self)
    }
    
    @IBAction func facebookSignInButtonPressed(_ sender: Any) {
        AuthService.instance.facebookAuthenticate(forViewController: self)
    }
}
