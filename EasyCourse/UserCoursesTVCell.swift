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
    
    @IBOutlet weak var operationBtn: UIButton!
    
    var enrolledIn = false
    var cellCourse:Course?
    var userJoinedThisCourse = false
    var delegate:cellTableviewProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        operationBtn.layer.cornerRadius = 6
        operationBtn.layer.borderWidth = 1
        operationBtn.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configureCell(_ course:Course, userJoinedCourses:Results<(Course)>) {
        cellCourse = course
        courseNameLabel.text = course.coursename
        courseTitleLabel.text = course.title
        
        userJoinedThisCourse = userJoinedCourses.contains { (joinedCourse) -> Bool in
            return course.id == joinedCourse.id
        }
        if userJoinedThisCourse {
            operationBtn.setTitle(" Drop ", for: UIControlState())
            operationBtn.setTitleColor(Design.color.deleteButtonColor(), for: UIControlState())
            operationBtn.layer.borderColor = Design.color.deleteButtonColor().cgColor
        } else {
            operationBtn.setTitle(" Join ", for: UIControlState())
            operationBtn.setTitleColor(self.tintColor, for: UIControlState())
            operationBtn.layer.borderColor = self.tintColor.cgColor
        }
    }
    
    
    @IBAction func operationBtnPressed(_ sender: UIButton) {
        if userJoinedThisCourse {
            print("click quit")
            SocketIOManager.sharedInstance.dropCourse(cellCourse!.id!, completion: { (success, error) in
                self.delegate?.reloadTableView()
            })
            
        } else {
            print("click join \(User.userLang) = \(cellCourse!.id)")
            ServerConst.sharedInstance.userChooseCourseAndLang(["lang":User.userLang, "course":[cellCourse!.id!]], completion: { (success, error) in
                self.delegate?.reloadTableView()
            })
        }
    }

}
