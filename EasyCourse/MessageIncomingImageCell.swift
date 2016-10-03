//
//  MessageIncomingImageCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/11/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MessageIncomingImageCell: UITableViewCell {
    
    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userAvatarImageView: UIImageView!
    
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: UIView!
    
    @IBOutlet weak var messageBubbleHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageBubbleWidthConstraint: NSLayoutConstraint!
    
    var delegate: popUpImageProtocol?
    var message:Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        messageBubbleWidthConstraint.constant = UIScreen.main.bounds.width * 0.4
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
        //        messageBubbleHeightConstraint.constant = min(90.0, message.imageHeight.value!/message.imageWidth.value!)
        self.message = message
        let ratio = message.imageHeight.value!/message.imageWidth.value!
        if message.imageHeight.value!/message.imageWidth.value! > 1.8 {
            messageBubbleHeightConstraint.constant = 90
        } else {
            messageBubbleHeightConstraint.constant = messageBubbleWidthConstraint.constant * CGFloat(ratio)
        }
        
        if let img = ServerHelper.sharedInstance.cachedImage(message.imageUrl!) {
            print("cached img")
            messageImageView.image = img
        } else {
            print("uncached img")
            ServerHelper.sharedInstance.getNetworkImage(message.imageUrl!, completion: { (data, error) in
                if data != nil {
                    self.messageImageView.image = UIImage(data: data!)
                    self.messageImageView.alpha = 0
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                        self.messageImageView.alpha = 1
                        }, completion: nil)
                } else {
                    //TODO: deal with no picture
                }
                
            })
        }
        
        self.userAvatarImageView.image = nil

        
        ServerConst.sharedInstance.getUserInfo(message.senderId!,refresh: false) { (user, joinedCourse, error) in
            self.userNameLabel.text = user?.username
            if let userImgUrlStr = user?.profilePictureUrl {
                let URL = Foundation.URL(string: userImgUrlStr)
                self.userAvatarImageView.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            } else {
                self.userAvatarImageView.image = Design.defaultAvatarImage
            }
        }
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        if lastMessage == nil || message.createdAt?.timeIntervalSince((lastMessage?.createdAt)! as Date) > 60 * 5 {
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
