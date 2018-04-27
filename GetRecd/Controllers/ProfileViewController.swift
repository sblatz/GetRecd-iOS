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
    @IBOutlet weak var bioLabel: UILabel!
    
    @IBOutlet weak var infoCell: UITableViewCell!
    @IBOutlet weak var settingButtonConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingButtonConstraint.constant = UIApplication.shared.statusBarFrame.height
        let bgFrame = CGRect(x: self.view.bounds.origin.x, y: self.view.bounds.origin.y, width: self.view.bounds.width, height: self.view.bounds.height - tabBarController!.tabBar.frame.height)
        let backgroundImageView = UIImageView(frame: bgFrame)
        backgroundImageView.image = UIImage(named: "launch-bg")
        tableView.backgroundView = backgroundImageView
        
        
        infoCell.backgroundColor = .clear
//        let adjustForTabbarInsets: UIEdgeInsets = UIEdgeInsetsMake(0, 0, self.tabBarController!.tabBar.frame.height, 0)
//        self.tableView.contentInset = adjustForTabbarInsets
//        self.tableView.scrollIndicatorInsets = adjustForTabbarInsets
        self.tableView.tableFooterView = UIView()
        
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
        return 4
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row > 0 {
            return (view.frame.height - infoCell.frame.height - tabBarController!.tabBar.frame.height) / 3.0
        }
        
        return infoCell.frame.height
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.row) {
            case 1:
                // Segue to music
                self.performSegue(withIdentifier: "showMusicLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            case 2:
                self.performSegue(withIdentifier: "showMovieLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            case 3:
                self.performSegue(withIdentifier: "showShowLikes", sender: nil)
                tableView.deselectRow(at: indexPath, animated: true)
            default:
                break
        }
    }
    
    func getCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        DataService.sharedInstance.getUser(uid: uid, success: { (user) in
            DispatchQueue.main.async {
                self.nameLabel.text = user.name
                self.bioLabel.text = user.bio ?? "No Bio"
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
    }
}
