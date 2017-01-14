//
//  CourseDetailTitleCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class CourseDetailTitleCell: UITableViewCell {

    @IBOutlet weak var courseNameLabel: UILabel!
    
    @IBOutlet weak var courseDescriptionLabel: UILabel!
    
    @IBOutlet weak var creditHoursLabel: UILabel!
    
    @IBOutlet weak var joinOrQuitBtn: UIButton!
    
    var course:Course?
    var delegate:CourseDetailVCProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        joinOrQuitBtn.setTitleColor(Design.color.deepGreenPersianGreenColor(), for: .normal)
        joinOrQuitBtn.layer.masksToBounds = true
        
        joinOrQuitBtn.layer.borderColor = Design.color.deepGreenPersianGreenColor().cgColor
        joinOrQuitBtn.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(course: Course?) {
        self.course = course
        courseNameLabel.text = course?.coursename ?? ""
        courseDescriptionLabel.text = course?.title ?? ""
        if let creditHours = course?.creditHours.value {
            creditHoursLabel.text = "\(creditHours) crs"
        } else {
            creditHoursLabel.text = ""
        }
        if course != nil {
            joinOrQuitBtn.isHidden = false
            if User.currentUser!.hasJoinedCourse(course!.id!) {
                joinOrQuitBtn.backgroundColor = Design.color.lighterGreenMountainMead()

                joinOrQuitBtn.setTitleColor(UIColor.white, for: .normal)
                joinOrQuitBtn.setTitle("  Joined  ", for: .normal)
                joinOrQuitBtn.layer.borderWidth = 0
                joinOrQuitBtn.alpha = 1
            } else {
                joinOrQuitBtn.backgroundColor = UIColor.white
                joinOrQuitBtn.setTitleColor(Design.color.deepGreenPersianGreenColor(), for: .normal)
                joinOrQuitBtn.setTitle(" Join ", for: .normal)
                joinOrQuitBtn.layer.borderWidth = 1

                joinOrQuitBtn.alpha = 1
            }
        } else {
            joinOrQuitBtn.isHidden = true
        }
        
        
    }
    
    @IBAction func joinCourseBtnPressed(_ sender: UIButton) {
        if User.currentUser!.hasJoinedCourse(course!.id!) {
            delegate?.joinOrDropCourse(join: false)
        } else {
            delegate?.joinOrDropCourse(join: true)
        }
    }
    

}
