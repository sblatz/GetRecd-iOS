//
//  IntroViewController.swift
//  Get Recd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Shift

class IntroViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGradient()

        if let view = self.view as? ShiftView {
            view.setColors([UIColor(red:0.77, green:0.45, blue:0.83, alpha:1.0), UIColor(red:0.33, green:0.34, blue:0.95, alpha:1.0)])
        }

    }

    func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [
            UIColor(red:0.33, green:0.34, blue:0.95, alpha:1.0).cgColor,
            UIColor(red:0.77, green:0.45, blue:0.83, alpha:1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint = CGPoint(x:1, y:1)
        self.view.layer.insertSublayer(gradient, at: 0 )

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

