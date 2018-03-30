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
    @IBOutlet weak var playButton: UIButton!
    
    static var currPlaying = -1
    
    var song: Song! {
        didSet {
            self.artistLabel.text = ""
            self.artworkView.image = UIImage()
            self.nameLabel.text = ""
            
            self.playButton.setImage(nil, for: .normal)
            
            self.nameLabel.text = song.name
            self.artistLabel.text = song.artist
            
            if song.type == .AppleMusic {
                typeView.image = UIImage(named: "AppleMusicIcon")
            } else {
                typeView.image = UIImage(named: "SpotifyIcon")
            }
            
            if SongCell.currPlaying == self.tag {
                playButton.setImage(UIImage(named: "playIcon"), for: .normal)
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
        if song.type == .Spotify {
            MusicService.sharedInstance.playSpotify(id: song.id)
        } else {
            
            MusicService.sharedInstance.playAppleMusic(id: song.id)
        }
        
        playButton.setImage(UIImage(named: "playIcon"), for: .normal)
        SongCell.currPlaying = self.tag
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "MusicChange"), object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "MusicChange"), object: nil, queue: OperationQueue.main) { (notification) in
            self.playButton.setImage(nil, for: .normal)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "MusicChange"), object: nil)
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
