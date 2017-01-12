//
//  MessageOutgoingTextCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/11/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class MessageOutgoingTextCell: UITableViewCell {
    
    @IBOutlet weak var timeSeperatorView: UIView!
    
    @IBOutlet weak var timeSeperatorHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userMessageLabel: UILabel!
        
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    
    @IBOutlet weak var bubbleMaxWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var errorAlertImgView: UIImageView!
    
    var delegate: popUpMessageProtocol?
    var message: Message?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        messageBubbleView.backgroundColor = Design.color.outgoingBubbleColor
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        
        userMessageLabel.textColor = Design.color.outgoingTextColor
        
        errorAlertImgView.isHidden = true
        errorAlertImgView.isUserInteractionEnabled = true
        let tapError = UITapGestureRecognizer(target: self, action: #selector(self.tapErrorImg))
        errorAlertImgView.addGestureRecognizer(tapError)
        
        bubbleMaxWidthConstraint.constant = UIScreen.main.bounds.width * 0.8
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        self.message = message
        messageBubbleView.message = message
        userMessageLabel.text = message.text
                
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
    
    func tapErrorImg() {
        delegate?.popUpResend(self.message!)
    }
    
}
