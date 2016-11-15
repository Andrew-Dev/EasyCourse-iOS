//
//  MessageOutgoingImageCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/11/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class MessageOutgoingImageCell: UITableViewCell {
    
    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: UIView!
    
    @IBOutlet weak var messageBubbleHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageBubbleWidthConstraint: NSLayoutConstraint!
    
    var delegate: popUpImageProtocol?
    var message:Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        messageBubbleWidthConstraint.constant = UIScreen.main.bounds.width * 0.5
        messageBubbleHeightConstraint.constant = 90
        userAvatarImageView.layer.cornerRadius = userAvatarImageView.frame.size.width/2
        userAvatarImageView.layer.masksToBounds = true
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(self.imageTapped))
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGestureRecognizer)

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        self.message = message
        //        messageBubbleHeightConstraint.constant = min(90.0, message.imageHeight.value!/message.imageWidth.value!)
        let ratio = message.imageHeight.value!/message.imageWidth.value!
        if message.imageHeight.value!/message.imageWidth.value! > 1.8 {
            messageBubbleHeightConstraint.constant = 90
        } else {
            messageBubbleHeightConstraint.constant = messageBubbleWidthConstraint.constant * CGFloat(ratio)
        }

        if let data = message.imageData {
            self.messageImageView.image = UIImage(data: data as Data)
        }
        
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
    
    func imageTapped() {
        delegate?.popUpImage(messageImageView,message: message!)
    }
    
}
