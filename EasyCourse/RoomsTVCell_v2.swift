//
//  RoomsTVCell_v2.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/13/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class RoomsTVCell_v2: UITableViewCell {

    @IBOutlet weak var roomProfilePicture: UIImageView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var lastMessageLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var unreadLabelView: UIView!
    
    @IBOutlet weak var unreadLabel: UILabel!
    
    @IBOutlet weak var attributeLabel: UILabel!
    
    
    @IBOutlet weak var unreadLabelWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        roomProfilePicture.image = Design.defaultRoomImage
        roomProfilePicture.layer.cornerRadius = roomProfilePicture.frame.width/2
        roomProfilePicture.layer.masksToBounds = true
        
        unreadLabelView.layer.cornerRadius = unreadLabelView.frame.height/2
        unreadLabelView.layer.masksToBounds = true
        unreadLabelView.backgroundColor = Design.color.brightRedPomegranate()
        
        attributeLabel.layer.cornerRadius = 4
        attributeLabel.layer.borderWidth = 1
        attributeLabel.layer.masksToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ room:Room) {
        timeLabel.text = ""
        lastMessageLabel.text = ""
        attributeLabel.text = nil
        
        if room.isToUser {
            roomProfilePicture.image = Design.defaultAvatarImage
            let user = try! Realm().object(ofType: User.self, forPrimaryKey: room.id)
            roomNameLabel.text = user?.username ?? "User"
            if let userImgUrlStr = user?.profilePictureUrl {
                let URL = Foundation.URL(string: userImgUrlStr)
                self.roomProfilePicture.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            }
        } else {
            roomProfilePicture.image = Design.defaultRoomImage
            if room.avatarPictureUrl != nil {
                let URL = Foundation.URL(string: room.avatarPictureUrl!)
                self.roomProfilePicture.af_setImage(withURL: URL!, placeholderImage: Design.defaultRoomImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            }
            roomNameLabel.text = room.roomname
//            if room.isSystem.value == true {
//                attributeLabel.text = " Official "
//                attributeLabel.textColor = Design.color.lightBlueMalibu()
//                attributeLabel.layer.borderColor = Design.color.lightBlueMalibu().cgColor
//            }
        }
        
        
        if room.unread > 0 {
            unreadLabelView.isHidden = false
            let unreadText = "\(room.unread)"
            unreadLabel.text = unreadText
            unreadLabelWidthConstraint.constant = unreadLabel.frame.height + CGFloat(unreadText.characters.count - 1) * 4
        } else {
            unreadLabelView.isHidden = true
        }
        
        let lastMessage = room.getMessage().last
        if lastMessage != nil {
            var content = "user"
            if lastMessage!.senderId == User.currentUser!.id {
                content = "\((User.currentUser?.username)!)"
            } else {
                ServerConst.sharedInstance.getUserInfo(lastMessage!.senderId!,refresh: false) { (user, joinedCourse, error) in
                    if error != nil {
                        
                    } else if user != nil {
                        content = "\(user!.username!)"
                    }
                }
                
                
            }
            
            if lastMessage!.imageUrl != nil || lastMessage!.imageData != nil {
                lastMessageLabel.text = content + " share an image"
            } else if lastMessage!.text != nil {
                lastMessageLabel.text = content + ": " + lastMessage!.text!
                //                lastMessageLabel.text =  lastMessage!.text!
            } else if lastMessage?.sharedRoom != nil {
                lastMessageLabel.text = content + " shared a room"
            } else {
                lastMessageLabel.text = content + ": ..."
            }
            timeLabel.text = Tools.sharedInstance.timeAgoSinceDatePrefered(lastMessage!.createdAt!)
        } else {
            if let welcomeMsg = room.roomname {
                lastMessageLabel.text = "Welcome to \(welcomeMsg)"
            } 
            
            if room.lastUpdateTime != nil {
                timeLabel.text = Tools.sharedInstance.timeAgoSinceDatePrefered(room.lastUpdateTime! as Date)
            }
        }
    }
}
