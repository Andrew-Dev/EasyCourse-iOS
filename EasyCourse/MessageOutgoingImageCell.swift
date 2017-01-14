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
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    
    @IBOutlet weak var messageBubbleHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageBubbleWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var errorAlertImgView: UIImageView!
    
    
    var delegate: popUpMessageProtocol?
    var message:Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        messageBubbleView.backgroundColor = Design.color.outgoingBubbleColor
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        messageBubbleWidthConstraint.constant = UIScreen.main.bounds.width * 0.5
        messageBubbleHeightConstraint.constant = 90
        
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
        messageBubbleView.message = message
        //        messageBubbleHeightConstraint.constant = min(90.0, message.imageHeight.value!/message.imageWidth.value!)
        let ratio = message.imageHeight.value!/message.imageWidth.value!
        if message.imageHeight.value!/message.imageWidth.value! > 1.8 {
            messageBubbleHeightConstraint.constant = 90
        } else {
            messageBubbleHeightConstraint.constant = messageBubbleWidthConstraint.constant * CGFloat(ratio)
        }

        if let data = message.imageData {
            self.messageImageView.image = UIImage(data: data)
        } else if message.imageUrl != nil {
            ServerHelper.sharedInstance.getNetworkImage(message.imageUrl!, completion: { (image, cached, error) in
                if image != nil {
                    self.messageImageView.image = image!
                    if !cached {
                        self.messageImageView.image = image!
                        self.messageImageView.alpha = 0
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                            self.messageImageView.alpha = 1
                        }, completion: nil)
                    }
                } else {
                    //TODO: deal with no picture
                }
                
            })
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
        
        if message.successSent.value == false {
            errorAlertImgView.isHidden = false
        } else {
            errorAlertImgView.isHidden = true
        }
        
    }
    
    func imageTapped() {
        delegate?.popUpImage(messageImageView, message: message!)
    }
    
}
