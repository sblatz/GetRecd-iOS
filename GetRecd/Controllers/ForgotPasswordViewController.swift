//
//  ForgotPasswordViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Pastel

class ForgotPasswordViewController: AuthenticationViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(sender:)))
        view.addGestureRecognizer(tap)
        
        errorLabel.isHidden = true
        emailTextField.delegate = self
        setupVisuals()
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
        let border = CALayer()
        let borderWidth: CGFloat = 1
        border.borderColor = UIColor(red:1, green:1, blue:1, alpha:1.0).cgColor
        border.frame = CGRect(x: 0, y: emailView.frame.size.height - borderWidth, width: emailView.frame.size.width, height: 1)
        border.borderWidth = borderWidth
        emailView.layer.addSublayer(border)
    }
    
    @objc func dismissKeyboard(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.endEditing(true)
        }
        
        return true
    }
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
        guard let emailText = emailTextField.text else {
            errorLabel.text = "Please enter a valid email address."
            errorLabel.isHidden = false
            return
        }
        
        if emailText.count == 0 || !emailText.contains("@") {
            errorLabel.text = "Please enter a valid email address."
            errorLabel.isHidden = false
            return
        }
        
        AuthService.instance.resetPassword(email: emailText) { (success) -> (Void) in
            if success {
                self.errorLabel.text = "Email for password reset sent!"
                self.errorLabel.isHidden = false
            } else {
                self.errorLabel.text = "Error trying to reset password, please try again!"
                self.errorLabel.isHidden = false
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

