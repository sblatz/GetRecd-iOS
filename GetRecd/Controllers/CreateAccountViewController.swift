//
//  CreateAccountViewController.swift
//  Get Recd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Pastel

class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var confirmPasswordView: UIView!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    @IBOutlet weak var orView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let gradientView = view as? PastelView {
            gradientView.startPastelPoint = .topRight
            gradientView.endPastelPoint = .bottomLeft

            gradientView.setColors([UIColor(red:0.35, green:0.28, blue:0.98, alpha:1.0),
                                    UIColor(red:0.78, green:0.43, blue:0.84, alpha:1.0),
                                    UIColor(red:0.19, green:0.14, blue:0.68, alpha:1.0)])

            gradientView.startAnimation()
        }

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(sender:)))
        view.addGestureRecognizer(tap)

        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        setupVisuals()

        drawHorizontalLine(view: orView)
    }

    func drawHorizontalLine (view: UIView) {
        var border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: view.frame.size.height/2 + 1, width:  view.frame.size.width / 2 - 30, height: width)
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true

        border = CALayer()
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: view.frame.size.width / 2 + 30, y: view.frame.size.height/2 + 1, width: view.frame.size.width, height: width)
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
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
}

