//
//  IntroViewController.swift
//  Get Recd
//
//  Created by Sawyer Blatz on 2/1/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit
import Pastel
import LTMorphingLabel

class IntroViewController: UIViewController, LTMorphingLabelDelegate {

    @IBOutlet weak var mediaLabel: LTMorphingLabel!

    let mediaTypes = ["song", "artist", "movie", "tv show", "album"]
    var mediaCount = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        mediaLabel.text = ""
        mediaLabel.delegate = self
        mediaLabel.morphingEffect = .evaporate

        let mediaLabelTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(mediaLabelAnimation), userInfo: nil, repeats: true)
        mediaLabelTimer.fire()
    }

    override func viewWillAppear(_ animated: Bool) {
        if let gradientView = view as? PastelView {
            gradientView.startPastelPoint = .topRight
            gradientView.endPastelPoint = .bottomLeft
            gradientView.animationDuration = 4.0

            gradientView.setColors([UIColor(red:0.35, green:0.28, blue:0.98, alpha:1.0),
                                    UIColor(red:0.78, green:0.43, blue:0.84, alpha:1.0),
                                    UIColor(red:0.19, green:0.14, blue:0.68, alpha:1.0)])

            gradientView.startAnimation()

            print(gradientView.animationDuration)
        }
    }

    @objc func mediaLabelAnimation() {
        if mediaCount == mediaTypes.count - 1 {
            mediaCount = -1
        }

        mediaCount += 1

        //UIView.animate(withDuration: 0.5) {
        mediaLabel.text = mediaTypes[self.mediaCount]
            //self.mediaLabel.text = self.mediaTypes[self.mediaCount]
        //}

    }

    func morphingDidStart(_ label: LTMorphingLabel) {

    }

    func morphingDidComplete(_ label: LTMorphingLabel) {

    }

    func morphingOnProgress(_ label: LTMorphingLabel, progress: Float) {

    }
}

