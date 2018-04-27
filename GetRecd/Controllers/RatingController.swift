//
//  RatingController.swift
//  GetRecd
//
//  Created by Martin Tuskevicius on 4/25/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import Foundation
import FirebaseAuth

class RatingController: UIStackView {
    
    @IBInspectable var starSize: CGSize = CGSize(width: 22.0, height: 22.0) {
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    private var ratingButtons = [UIButton]()
    var rating = 0 {
        didSet {
            updateButtonSelectionStates()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    @objc func ratingButtonTapped(button: UIButton) {
        guard let index = ratingButtons.index(of: button) else {
            fatalError("The button, \(button), is not in the ratingButtons array: \(ratingButtons)")
        }
        let selectedRating = index + 1
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Tried to rate a song before being authenticated!")
            return
        }
        /* Check if the cell containing this stack view is a movie or a song cell. */
        if let movieCell = self.superview?.superview as? MovieCell {
            let movie = movieCell.movie
            if movie == nil {
                DataService.sharedInstance.rateContent(
                    uid: uid,
                    contentType: DataService.ContentType.Show,
                    contentId: String(movieCell.show.id),
                    rating: selectedRating,
                    success: { },
                    failure: { (error) in print("Failed to rate a show: \(error)") })
            } else {
                DataService.sharedInstance.rateContent(
                    uid: uid,
                    contentType: DataService.ContentType.Movie,
                    contentId: String(movie!.id),
                    rating: selectedRating,
                    success: { },
                    failure: { (error) in print("Failed to rate a movie: \(error)") })
            }
        } else if let songCell = self.superview?.superview as? SongCell {
            let songType = (songCell.song.type == Song.SongType.AppleMusic)
                ? DataService.ContentType.AppleSong
                : DataService.ContentType.SpotifySong
            DataService.sharedInstance.rateContent(
                uid: uid,
                contentType: songType,
                contentId: String(songCell.song.id),
                rating: selectedRating,
                success: { },
                failure: { (error) in print("Failed to rate a song: \(error)") })
        }
    }
    
    private func setupButtons() {
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        let bundle = Bundle(for: type(of: self))
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named:"emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named:"highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 0..<starCount {
            let button = UIButton()
            
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected)
            button.setImage(highlightedStar, for: .highlighted)
            button.setImage(highlightedStar, for: [.highlighted, .selected])
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            button.addTarget(self, action: #selector(RatingController.ratingButtonTapped(button:)), for: .touchUpInside)
            
            addArrangedSubview(button)
        
            ratingButtons.append(button)
        }
        
        updateButtonSelectionStates()
    }
    
    private func updateButtonSelectionStates() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
}
