//
//  RoomsAddRoomNameListCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomNameListTVCell: UITableViewCell {

    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var membersCntLabel: UILabel!
    
    @IBOutlet weak var founderImageView: UIImageView!
    
    @IBOutlet weak var founderNameLabel: UILabel!
    
    @IBOutlet weak var joinOrQuitBtn: UIButton!

    var room:Room?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        joinOrQuitBtn.layer.cornerRadius = 6
        joinOrQuitBtn.layer.borderWidth = 1
        joinOrQuitBtn.layer.masksToBounds = true
        
        founderImageView.layer.cornerRadius = founderImageView.frame.height/2
        founderImageView.layer.masksToBounds = true
        founderImageView.alpha = 0.75
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(_ room: Room, showJoinBtn: Bool) {
        self.room = room
        roomNameLabel.text = room.roomname
        if let memCntDes = room.memberCountsDescription {
            membersCntLabel.text = "(\(memCntDes))"
        }
        founderImageView.image = Design.defaultRoomImage
        
        if room.isSystem.value == true {
            founderNameLabel.text = "Official"
        } else if room.founderID != nil {
            founderNameLabel.text = ""
            SocketIOManager.sharedInstance.getUserInfo(room.founderID!, refresh: false, completion: { (user, error) in
                if user != nil {
                    self.founderNameLabel.text = user?.username ?? ""
                    if user?.profilePictureUrl != nil {
                        let URL = Foundation.URL(string: user!.profilePictureUrl!)
                        self.founderImageView.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
                    }
                    
                }
            })
            
        }
        
        if showJoinBtn {
            joinOrQuitBtn.isHidden = false
            if User.currentUser!.joinedRoom.index(of: room) != nil {
                joinOrQuitBtn.setTitle(" Quit ", for: UIControlState())
                joinOrQuitBtn.setTitleColor(Design.color.deleteButtonColor(), for: UIControlState())
                joinOrQuitBtn.layer.borderColor = Design.color.deleteButtonColor().cgColor
            } else {
                joinOrQuitBtn.setTitle(" Join ", for: UIControlState())
                joinOrQuitBtn.setTitleColor(Design.color.deepGreenPersianGreenColor(), for: UIControlState())
                joinOrQuitBtn.layer.borderColor = Design.color.deepGreenPersianGreenColor().cgColor
            }
        } else {
            joinOrQuitBtn.isHidden = true
        }
        
    }
    
    @IBAction func joinOrQuitBtnPressed(_ sender: UIButton) {
        if User.currentUser!.joinedRoom.index(of: room!) != nil {
//            delegate?.joinOrDropRoom(join: false, roomId: room!.id!)
        } else {
//            delegate?.joinOrDropRoom(join: true, roomId: room!.id!)
        }
    }

}
