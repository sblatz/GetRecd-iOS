//
//  MovieCell.swift
//  GetRecd
//
//  Created by Sawyer Blatz on 3/22/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import FirebaseAuth

class MovieCell: UITableViewCell {

    @IBOutlet weak var artworkView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!
    @IBOutlet weak var ratingsView: RatingController!

    var basePosterPath = "https://image.tmdb.org/t/p/original/"
    var movie: Movie! {
        didSet {
            self.nameLabel.text = movie.name
            self.releaseLabel.text = movie.releaseDate
            self.artworkView.image = nil
            if self.ratingsView != nil {
                self.ratingsView.rating = 0
            }
            
            downloadArtwork(url: (basePosterPath + movie.posterPath)) { (image) in
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
                        contentType: DataService.ContentType.Movie,
                        contentId: String(movie.id),
                        success: { (rating) in self.ratingsView.rating = rating },
                        failure: { (error) in print("Failed to retrieve a song rating: \(error)") })
            }
        }
    }

    var show: Show! {
        didSet {
            self.nameLabel.text = show.name
            self.releaseLabel.text = show.releaseDate
            self.artworkView.image = nil
            if self.ratingsView != nil {
                self.ratingsView.rating = 0
            }

            downloadArtwork(url: (basePosterPath + show.posterPath)) { (image) in
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
                        contentType: DataService.ContentType.Show,
                        contentId: String(show.id),
                        success: { (rating) in self.ratingsView.rating = rating },
                        failure: { (error) in print("Failed to retrieve a song rating: \(error)") })
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
