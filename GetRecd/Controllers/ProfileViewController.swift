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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, self.tabBarController!.tabBar.frame.height, 0)
        self.tableView.contentInset = adjustForTabbarInsets
        self.tableView.scrollIndicatorInsets = adjustForTabbarInsets
        
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width/2
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        getCurrentUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        switch (indexPath.row) {
            case 2:
                // Segue to music
                self.performSegue(withIdentifier: "showMusicLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            case 3:
                self.performSegue(withIdentifier: "showMovieLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            case 4:
                self.performSegue(withIdentifier: "showShowLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            default:
                break
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DataService.sharedInstance.getUser(uid: uid, success: { (user) in
            DispatchQueue.main.async {
                self.nameLabel.text = user.name
                self.bioTextView.text = user.bio ?? "No Bio"
            }
            
        }) { (error) in
            // TODO: Show error in retrieivng user
            print(error.localizedDescription)
        }
        
        DataService.sharedInstance.getProfilePicture(uid: uid, success: { (exists, image) in
            DispatchQueue.main.async {
                self.profilePicture.image = image
            }
        }) { (error) in
            // TODO: Show error in retrieivng user picture
            print(error.localizedDescription)
        }
    }
}
