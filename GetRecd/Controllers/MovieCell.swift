//
//  MovieCell.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit


class MovieCell: UITableViewCell {

    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!


    var movie: Movie! {
        didSet {
            self.nameLabel.text = movie.name
            self.releaseLabel.text = movie.releaseDate
            self.artworkView.image = nil

            downloadArtwork(url: movie.posterPath) { (image) in
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


    // Show trailer of the movie
    @IBAction func onArtTap(_ sender: Any) {
        //MusicService.sharedInstance.playPreview(url: song.preview)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
