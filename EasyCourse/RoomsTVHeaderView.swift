//
//  RoomsTVHeaderView.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/13/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class RoomsTVHeaderView: UITableViewHeaderFooterView {

    
    @IBOutlet weak var viewForBackground: UIView!
    
    @IBOutlet weak var sectionNameLabel: UILabel!
    
    @IBOutlet weak var unreadLabel: UILabel!
    
    @IBOutlet weak var tapLayerView: UIView!
    @IBOutlet weak var arrowIcon: UIImageView!
    
    var roomVC:RoomsVC?
    
    var course:Course?
    var isPersonal = false
    
    let upArrowTrans = CGAffineTransform(rotationAngle: 0)
    let downArrowTrans = CGAffineTransform(rotationAngle: (CGFloat(M_PI) - 0.00000000000001))

    override func awakeFromNib() {
        super.awakeFromNib()
        self.viewForBackground.backgroundColor = UIColor(white: 0.95, alpha: 1)
//        self.viewForBackground.backgroundColor = UIColor(red: 237/255, green: 239/255, blue: 242/255, alpha: 1)
        self.viewForBackground.layer.borderWidth = 0.5
        self.viewForBackground.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        sectionNameLabel.text = nil
        
//        unreadLabel.layer.cornerRadius = unreadLabel.frame.height / 2
//        unreadLabel.layer.masksToBounds = true
//        unreadLabel.backgroundColor = UIColor(white: 0.9, alpha: 1)
        
        arrowIcon.image = arrowIcon.image!.withRenderingMode(.alwaysTemplate)
        arrowIcon.tintColor = UIColor.darkGray
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapView))
        tapLayerView.isUserInteractionEnabled = true
        tapLayerView.addGestureRecognizer(tap)
    }
    
    func configureHeader(course: Course?, isPersonal:Bool) {
        self.isPersonal = isPersonal
        self.course = course
        var totalUnread = 0

        if !isPersonal {
            sectionNameLabel.text = course?.coursename ?? "Course"
            for room in User.currentUser!.joinedRoom.filter("courseID = '\(course!.id!)'") {
                totalUnread += room.unread
            }
            if course!.collapseOnRoomMenu && totalUnread > 0 {
                unreadLabel.isHidden = false
                unreadLabel.text = "\(totalUnread)"
            } else {
                unreadLabel.isHidden = true
            }
            if course!.collapseOnRoomMenu {
                self.arrowIcon.transform = self.upArrowTrans
            } else {
                self.arrowIcon.transform = self.downArrowTrans
            }
            arrowIcon.isHidden = false
        } else {
            sectionNameLabel.text = "Personal"
            unreadLabel.isHidden = true
            arrowIcon.isHidden = true
        }
        
        
        
    }
    
    func tapView() {
        
        roomVC?.tapHeader(course: course, isPersonal: isPersonal)
        if course != nil {
            if course!.collapseOnRoomMenu {
                UIView.animate(withDuration: 0.2, animations: {
                    self.arrowIcon.transform = self.upArrowTrans
                    
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.arrowIcon.transform = self.downArrowTrans
                    
                })
            }
        }
        
        
        if course != nil && course!.collapseOnRoomMenu {
            var totalUnread = 0
            for room in User.currentUser!.joinedRoom.filter("courseID = '\(course!.id!)'") {
                totalUnread += room.unread
            }
            if totalUnread > 0 {
                unreadLabel.text = "\(totalUnread)"
                unreadLabel.isHidden = false
            } else {
                unreadLabel.isHidden = true
            }
            
        } else {
            unreadLabel.isHidden = true
        }
    }

}
