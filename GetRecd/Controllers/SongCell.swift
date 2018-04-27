//
//  SongCell.swift
//  GetRecd
//
//  Created by Siraj Zaneer on 2/23/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class SongCell: UITableViewCell {

    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ratingsView: RatingController!
    
    static var currPlaying = -1
    
    var song: Song! {
        didSet {
            self.artistLabel.text = ""
            self.artworkView.image = UIImage()
            self.nameLabel.text = ""
            if self.ratingsView != nil {
                self.ratingsView.rating = 0
            }
            
            self.playButton.setImage(nil, for: .normal)
            
            self.nameLabel.text = song.name
            self.artistLabel.text = song.artist
            
            var songType: DataService.ContentType
            if song.type == .AppleMusic {
                typeView.image = UIImage(named: "AppleMusicIcon")
                songType = DataService.ContentType.AppleSong
            } else {
                typeView.image = UIImage(named: "SpotifyIcon")
                songType = DataService.ContentType.SpotifySong
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

            if ratingsView != nil {
                guard let uid = Auth.auth().currentUser?.uid else {
                    print("Tried to retrieve a rating before authenticating!")
                    return
                }

                DataService.sharedInstance.getRating(
                        uid: uid,
                        contentType: songType,
                        contentId: song.id,
                        success: { (rating) in self.ratingsView.rating = rating },
                        failure: { (error) in print("Failed to retrieve a song rating: \(error)") })
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
