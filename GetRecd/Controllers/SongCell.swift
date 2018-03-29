//
//  SongCell.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {

    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    var song: Song! {
        didSet {
            self.nameLabel.text = song.name
            self.artistLabel.text = song.artist
            
            if song.type == .AppleMusic {
                typeView.image = UIImage(named: "AppleMusicIcon")
            } else {
                typeView.image = UIImage(named: "SpotifyIcon")
            }
            
            self.artworkView.image = nil
            
            downloadArtwork(url: song.artwork) { (image) in
                DispatchQueue.main.async {
                    self.artworkView.image = image
                }
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func onArtTap(_ sender: Any) {
        print("sdasd")
        if song.type == .Spotify {
            MusicService.sharedInstance.testSpotify(id: song.id)
        } else {
            
            MusicService.sharedInstance.testAppleMusic(id: song.id)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
