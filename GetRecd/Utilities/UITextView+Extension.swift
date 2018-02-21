//
//  UITextView+Extension.swift
//  GetRecd
//
//  Created by Dhruv Upadhyay on 2/21/18.
//  Copyright © 2018 CS 407. All rights reserved.
//

import UIKit

extension UITextView {
    func textHeight() -> CGFloat {
        guard let text = self.text else {
            return 0
        }
        
        return text.boundingRect(with: CGSize(width: self.frame.width, height: 0), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: self.font], context: nil).height
    }
}
