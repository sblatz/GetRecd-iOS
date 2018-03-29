//
//  RoundedView.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 3/27/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

class RoundedView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = frame.size.width/2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1.75)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.50
    }
}
