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
        self.layoutIfNeeded()
        roomProfilePicture.image = Design.defaultRoomImage
        roomProfilePicture.layer.cornerRadius = roomProfilePicture.frame.width/2
        roomProfilePicture.layer.masksToBounds = true

        unreadLabel.layer.cornerRadius = 8
        unreadLabel.layer.masksToBounds = true
        unreadLabel.backgroundColor = Design.color.brightRedPomegranate()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ room:Room, lastMessage: Message?) {
        roomProfilePicture.image = Design.defaultAvatarImage
        timeLabel.text = ""
        lastMessageLabel.text = ""
        
        if room.isToUser {
            let user = try! Realm().object(ofType: User.self, forPrimaryKey: room.id)
            roomNameLabel.text = user?.username ?? "User"
            if let userImgUrlStr = user?.profilePictureUrl {
                let URL = Foundation.URL(string: userImgUrlStr)
                self.roomProfilePicture.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            }
        } else {
            roomNameLabel.text = room.roomname
        }
        
        
        if room.unread != 0 {
            unreadLabel.isHidden = false
            unreadLabel.text = "\(room.unread)"
        } else {
            unreadLabel.isHidden = true
        }
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
            } else if lastMessage?.sharedRoom != nil {
                lastMessageLabel.text = content + " shared a room"
            } else {
                lastMessageLabel.text = content + ": ..."
            }
            timeLabel.text = Tools.sharedInstance.timeAgoSinceDatePrefered(lastMessage!.createdAt!)
        }
    }
    
}
