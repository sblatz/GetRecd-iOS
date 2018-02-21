//
//  RecFeedViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/20/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class RecFeedViewController: UIViewController {

    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        getCurrentUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getCurrentUser()
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DataService.instance.getUser(userID: uid) { (user) in
            self.currentUser = user
        }
    }
}
