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

        if let gradientView = view as? PastelView {
            gradientView.startPastelPoint = .topRight
            gradientView.endPastelPoint = .bottomLeft
            /*
            gradientView.setColors([UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
              UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
              UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
              UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
              UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0),
              UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
              UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0)])
             */

            gradientView.setColors([UIColor(red:0.33, green:0.34, blue:0.95, alpha:1.0), UIColor(red:0.78, green:0.46, blue:0.83, alpha:1.0)])
            gradientView.startAnimation()
        }

        let mediaLabelTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(mediaLabelAnimation), userInfo: nil, repeats: true)
        mediaLabelTimer.fire()

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    func morphingDidStart(_ label: LTMorphingLabel) {

    }

    func morphingDidComplete(_ label: LTMorphingLabel) {

    }

    func morphingOnProgress(_ label: LTMorphingLabel, progress: Float) {

    }
}

