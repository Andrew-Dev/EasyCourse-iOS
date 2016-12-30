//
//  UserCoursesTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/15/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class UserCoursesTVCell: UITableViewCell {

    @IBOutlet weak var courseNameLabel: UILabel!
    
    @IBOutlet weak var courseTitleLabel: UILabel!
    
//    @IBOutlet weak var operationBtn: UIButton!
    
    @IBOutlet weak var joinIndicateLabel: UILabel!
    
    
    var enrolledIn = false
    var cellCourse:Course?
    var userJoinedThisCourse = false
    var delegate:cellTableviewProtocol?
    
    var isOperating = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        joinIndicateLabel.layer.cornerRadius = 6
//        joinIndicateLabel.layer.borderWidth = 1
//        joinIndicateLabel.layer.masksToBounds = true
//        self.operationBtn.alpha = 1
//        joinIndicateLabel.layer.borderColor = Design.color.lighterGreenMountainMead().cgColor
        joinIndicateLabel.textColor = Design.color.deepGreenPersianGreenColor()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configureCell(_ course:Course, userJoinedCourses:List<(Course)>) {
        cellCourse = course
        courseNameLabel.text = course.coursename
        courseTitleLabel.text = course.title
        
        userJoinedThisCourse = userJoinedCourses.contains { (joinedCourse) -> Bool in
            return course.id == joinedCourse.id
        }
        
        if userJoinedThisCourse {
            joinIndicateLabel.isHidden = false
            joinIndicateLabel.text = " Joined "
        } else {
            joinIndicateLabel.isHidden = true
//            operationBtn.layer.borderColor = self.tintColor.cgColor
        }
    }
    
    
    @IBAction func operationBtnPressed(_ sender: UIButton) {

        if userJoinedThisCourse {
            print("click quit")
            SocketIOManager.sharedInstance.dropCourse(cellCourse!.id!, completion: { (success, error) in

            })
            
        } else {
            print("click join \(User.userLang) = \(cellCourse!.id)")
            
            SocketIOManager.sharedInstance.joinCourse([cellCourse!.id!], languages: User.userLang) { (success, error) in
               
                
            }
        }
    }

}
