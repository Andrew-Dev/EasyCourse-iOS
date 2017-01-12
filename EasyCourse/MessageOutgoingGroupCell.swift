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
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var roomImageView: UIImageView!
    
    @IBOutlet weak var bubbleMaxWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var errorAlertImgView: UIImageView!
    
    @IBOutlet weak var roomTextLabel: UILabel!
    
    var delegate: popUpMessageProtocol?
    var message:Message?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.layoutIfNeeded()
        messageBubbleView.backgroundColor = Design.color.outgoingBubbleColor
        messageBubbleView.layer.cornerRadius = 10
        messageBubbleView.layer.masksToBounds = true
        bubbleMaxWidthConstraint.constant = UIScreen.main.bounds.width * 0.6
        
        roomNameLabel.textColor = Design.color.outgoingTextColor
        roomTextLabel.textColor = Design.color.outgoingTextColor
        
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(self.groupTapped))
        messageBubbleView.isUserInteractionEnabled = true
        messageBubbleView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ message:Message, lastMessage: Message?) {
        self.message = message
        messageBubbleView.message = message
        
        if let room = try! Realm().object(ofType: Room.self, forPrimaryKey: message.sharedRoom) {
            roomNameLabel.text = room.roomname ?? "room"
        } else {
            SocketIOManager.sharedInstance.getRoomInfo(message.sharedRoom!, refresh: false, completion: { (room, error) in
                if room != nil {
                    self.roomNameLabel.text = room?.roomname ?? "room"
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
    
    func groupTapped() {
        delegate?.popUpSharedRoom(message!)
    }

}
