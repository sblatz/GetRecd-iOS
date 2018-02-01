//
//  CreateAccountViewController.swift
//  Get Recd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var confirmPasswordView: UIView!
    @IBOutlet weak var confirmPasswordTextField: UITextField!



    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(sender:)))
        view.addGestureRecognizer(tap)

        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        setupVisuals()
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

        border = CALayer()
        border.borderColor = UIColor(red:1, green:1, blue:1, alpha:1.0).cgColor
        border.frame = CGRect(x: 0, y: confirmPasswordView.frame.size.height - borderWidth, width: confirmPasswordView.frame.size.width, height: 1)
        border.borderWidth = borderWidth
        confirmPasswordView.layer.addSublayer(border)
    }

    @objc func dismissKeyboard(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction func signUpButtonPressed(_ sender: Any) {
        // Shake the password fields if they are not matching
        // Shake the email field if no email entered / email already exists
        // Push to tab view if successful creation
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            textField.endEditing(true)
        }
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}

