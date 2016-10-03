//
//  MessageOutgoingTextCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/11/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l < r
//  case (nil, _?):
//    return true
//  default:
//    return false
//  }
//}
//
//fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l > r
//  default:
//    return rhs < lhs
//  }
//}


class MessageOutgoingTextCell: UITableViewCell {
    
    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    
    @IBOutlet weak var userMessageLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: UIView!
    
    @IBOutlet weak var bubbleMaxWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        userAvatarImageView.layer.cornerRadius = userAvatarImageView.frame.size.width/2
        userAvatarImageView.layer.masksToBounds = true
        bubbleMaxWidthConstraint.constant = UIScreen.main.bounds.width * 0.6
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        userMessageLabel.text = message.text
        
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
