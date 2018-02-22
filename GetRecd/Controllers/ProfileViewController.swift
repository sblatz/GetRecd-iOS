//
//  ProfileViewController.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/19/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UITableViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var bioTextView: UITextView!
    
    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getCurrentUser()
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Settings", let settingsVC = segue.destination as? ProfileSettingsViewController {
            settingsVC.currentUser = currentUser
            settingsVC.profilePictureImage = profilePicture.image
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DataService.instance.getUser(userID: uid) { (user) in
            self.currentUser = user
            
            print("GETTING USER ON PROFILE")
            DispatchQueue.main.async {
                self.nameLabel.text = self.currentUser.name
                self.bioTextView.text = self.currentUser.bio.isEmpty ? "No Bio": self.currentUser?.bio
            }
            
            DataService.instance.getProfilePicture(user: self.currentUser, handler: { (image) in
                DispatchQueue.main.async {
                self.profilePicture.image = image
                }
            })
        }
    }
    
}

