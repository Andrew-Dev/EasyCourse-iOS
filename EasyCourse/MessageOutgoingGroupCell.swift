//
//  MessageOutgoingGroupCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class MessageOutgoingGroupCell: UITableViewCell {

    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: UIView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var roomImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        let roomName = try! Realm().object(ofType: Room.self, forPrimaryKey: message.sharedRoom)?.roomname
        roomNameLabel.text = roomName ?? "room"
        
        if let avatarData = User.currentUser?.profilePicture {
            self.userAvatarImageView.image = UIImage(data: avatarData as Data)
        } else {
            self.userAvatarImageView.image = Design.defaultAvatarImage
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        
        if lastMessage == nil || message.createdAt!.timeIntervalSince(lastMessage!.createdAt!) > 60 * 5 {
            timeLabel.text = formatter.string(from: message.createdAt! as Date)
            timeSeperatorView.isHidden = false
            timeSeperatorHeightConstraint.constant = 18
        } else {
            timeSeperatorView.isHidden = true
            timeSeperatorHeightConstraint.constant = 0
        }
        
    }

}
