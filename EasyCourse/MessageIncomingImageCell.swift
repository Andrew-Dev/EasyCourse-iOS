//
//  MessageIncomingImageCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/11/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class MessageIncomingImageCell: UITableViewCell {
    
    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    
    @IBOutlet weak var messageBubbleHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageBubbleWidthConstraint: NSLayoutConstraint!
    
    var popUpDelegate: popUpMessageProtocol?
    var cellDelegate: cellTableviewProtocol?
    var message:Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        messageBubbleView.backgroundColor = Design.color.incomingBubbleColor
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        messageBubbleWidthConstraint.constant = UIScreen.main.bounds.width * 0.4
        messageBubbleHeightConstraint.constant = 90
        
        userAvatarImageView.layer.cornerRadius = userAvatarImageView.frame.size.width/2
        userAvatarImageView.layer.masksToBounds = true
        userNameLabel.textColor = Design.color.incomingUsernameColor
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(self.imageTapped))
        messageImageView.isUserInteractionEnabled = true
        messageImageView.addGestureRecognizer(tapGestureRecognizer)
        
        let tapImage = UITapGestureRecognizer(target: self, action: #selector(self.tapUserAvatar))
        userAvatarImageView.addGestureRecognizer(tapImage)
        userAvatarImageView.isUserInteractionEnabled = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        //        messageBubbleHeightConstraint.constant = min(90.0, message.imageHeight.value!/message.imageWidth.value!)
        self.message = message
        messageBubbleView.message = message
        
        let ratio = message.imageHeight.value!/message.imageWidth.value!
        if message.imageHeight.value!/message.imageWidth.value! > 1.8 {
            messageBubbleHeightConstraint.constant = 90
        } else {
            messageBubbleHeightConstraint.constant = messageBubbleWidthConstraint.constant * CGFloat(ratio)
        }
        
        let URL = Foundation.URL(string: message.imageUrl!)
        messageImageView.af_setImage(withURL: URL!, placeholderImage: Design.imagePlaceHolder, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
        
        // User
        userNameLabel.text = " "
        userAvatarImageView.image = Design.defaultAvatarImage
        
        SocketIOManager.sharedInstance.getUserInfo(message.senderId!, loadType: .cacheElseNetwork) { (user, error) in
            if error == nil {
                self.userNameLabel.text = user?.username
                if let userImgUrlStr = user?.profilePictureUrl {
                    let URL = Foundation.URL(string: userImgUrlStr)
                    self.userAvatarImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
                } else {
                    self.userAvatarImageView.image = Design.defaultAvatarImage
                }
            }
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
        popUpDelegate?.popUpImage(messageImageView, message: message!)
    }
    
    func tapUserAvatar() {
        cellDelegate?.displayViews!((message?.senderId)!)
    }
    
}
