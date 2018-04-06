//
//  SignInViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 2/6/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Pastel

class SignInViewController: AuthenticationViewController, UITextFieldDelegate {

    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var orView: UIView!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(sender:)))
        view.addGestureRecognizer(tap)

        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupVisuals()
        drawHorizontalLine(view: orView)
    }

    override func viewWillAppear(_ animated: Bool) {
        if let gradientView = view as? PastelView {
            gradientView.startPastelPoint = .topRight
            gradientView.endPastelPoint = .bottomLeft

            gradientView.setColors([UIColor(red:0.35, green:0.28, blue:0.98, alpha:1.0),
                                    UIColor(red:0.78, green:0.43, blue:0.84, alpha:1.0),
                                    UIColor(red:0.19, green:0.14, blue:0.68, alpha:1.0)])

            gradientView.startAnimation()
        }
    }

    func setupVisuals() {
        var border = CALayer()
        let borderWidth: CGFloat = 1
        border.borderColor = UIColor(red:1, green:1, blue:1, alpha:1.0).cgColor
        border.frame = CGRect(x: 0, y: emailView.frame.size.height - borderWidth, width: emailView.frame.size.width, height: 1)
        border.borderWidth = borderWidth
        emailView.layer.addSublayer(border)

        border = CALayer()
        border.borderColor = UIColor(red:1, green:1, blue:1, alpha:1.0).cgColor
        border.frame = CGRect(x: 0, y: passwordView.frame.size.height - borderWidth, width: passwordView.frame.size.width, height: 1)
        border.borderWidth = borderWidth
        passwordView.layer.addSublayer(border)
    }

    func drawHorizontalLine (view: UIView) {
        var border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: view.frame.size.height / 2 + 1, width:  view.frame.size.width / 2 - 30, height: width)
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true

        border = CALayer()
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: view.frame.size.width / 2 + 30, y: view.frame.size.height / 2 + 1, width: view.frame.size.width, height: width)
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
    }

    @IBAction func signInButtonPressed(_ sender: Any) {
        guard let emailText = emailTextField.text else {return}
        guard let passwordText = passwordTextField.text else {return}

        if emailText.count == 0 || !emailText.contains("@") {
            errorLabel.text = "Please enter a valid email address."
            errorLabel.isHidden = false
        } else if passwordText.count < 6 {
            errorLabel.text = "Please enter a password with at least six characters."
            errorLabel.isHidden = false
        } else {
            AuthService.sharedInstance.signInWithEmail(email: emailText, password: passwordText, success: {
                self.errorLabel.isHidden = true
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "RecFeed", sender: self)
                }
            }) { (error) in
                self.errorLabel.text = error.localizedDescription
                self.errorLabel.isHidden = false
            }
        }
    }

    @IBAction override func googleSignInButtonPressed(_ sender: Any) {
        AuthService.instance.googleAuthenticate(forViewController: self)
    }
    
    @objc func dismissKeyboard(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.endEditing(true)
        }
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
