//
//  LoginCourseListCVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class LoginCourseListCVCell: UICollectionViewCell {
    
    @IBOutlet weak var courseNameLabel: UILabel!
    
    @IBOutlet weak var courseBGView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        courseBGView.layer.cornerRadius = 5
        courseBGView.layer.masksToBounds = true
    }
    
}
