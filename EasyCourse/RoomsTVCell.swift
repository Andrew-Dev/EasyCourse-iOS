//
//  RoomsTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class RoomsTVCell: UITableViewCell {
    
    @IBOutlet weak var roomProfilePicture: UIImageView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var lastMessageLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    
    @IBOutlet weak var unreadLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        roomProfilePicture.layer.cornerRadius = roomProfilePicture.frame.width/2
        roomProfilePicture.layer.masksToBounds = true
        roomProfilePicture.image = Design.defaultRoomImage
        unreadLabel.layer.cornerRadius = 8
        unreadLabel.layer.masksToBounds = true
        unreadLabel.backgroundColor = Design.color.brightRedPomegranate()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ room:Room, lastMessage: Message?) {
        roomNameLabel.text = room.roomname
        timeLabel.text = ""
        lastMessageLabel.text = ""
        if room.unread != 0 {
            unreadLabel.isHidden = false
            unreadLabel.text = "\(room.unread)"
        } else {
            unreadLabel.isHidden = true
        }
        if lastMessage != nil {
            var content = "user: "
            if lastMessage!.senderId == User.currentUser!.id {
                content = "\((User.currentUser?.username)!): "
            } else {
                ServerConst.sharedInstance.getUserInfo(lastMessage!.senderId!,refresh: false) { (user, joinedCourse, error) in
                    if error != nil {
                        
                    } else if user != nil {
                        content = "\(user!.username!): "
                    }
                }
                
                
            }
            
            if lastMessage!.imageUrl != nil || lastMessage!.imageData != nil {
                lastMessageLabel.text = content + "[image]"
            } else if lastMessage!.text != nil {
                lastMessageLabel.text = content + lastMessage!.text!
            } else {
                lastMessageLabel.text = content + "..."
            }
            timeLabel.text = Tools.sharedInstance.timeAgoSinceDatePrefered(lastMessage!.createdAt!)
        }
    }
    
}
