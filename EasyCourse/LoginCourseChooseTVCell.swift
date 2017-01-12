//
//  LoginCourseChooseTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class LoginCourseChooseTVCell: UITableViewCell {
    
    @IBOutlet weak var courseNameLabel: UILabel!
    
    @IBOutlet weak var courseTitleLabel: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(course:Course, choosed:Bool) {
        courseNameLabel.text = course.coursename
        courseTitleLabel.text = course.title
        if choosed {
            self.accessoryType = .checkmark
        } else {
            self.accessoryType = .none
        }
    }
    
}
