//
//  NavigationViewController.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 2/6/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
    }

}
