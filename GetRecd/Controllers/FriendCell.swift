//
//  FriendCell.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/29/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    var user: String! {
        didSet {
            
            DataService.sharedInstance.getUser(uid: user, success: { (user) in
                DispatchQueue.main.async {
                    self.nameLabel.text = user.name
                }
            }) { (error) in
                print(error.localizedDescription)
            }
            
            DataService.sharedInstance.getProfilePicture(uid: user, success: { (exists, image) in
                if exists {
                    DispatchQueue.main.async {
                        self.profilePic.image = image
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
