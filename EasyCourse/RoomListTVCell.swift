//
//  RoomListTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 12/30/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class RoomListTVCell: UITableViewCell {

    @IBOutlet weak var roomAvatarImageView: UIImageView!
    
    @IBOutlet weak var roomNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(room:Room) {
        if room.isToUser {
            roomAvatarImageView.image = Design.defaultAvatarImage
            let user = try! Realm().object(ofType: User.self, forPrimaryKey: room.id)
            roomNameLabel.text = user?.username ?? "User"
            if let userImgUrlStr = user?.profilePictureUrl {
                let URL = Foundation.URL(string: userImgUrlStr)
                self.roomAvatarImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            }
        } else {
            roomAvatarImageView.image = Design.defaultRoomImage
            if room.avatarPictureUrl != nil {
                let URL = Foundation.URL(string: room.avatarPictureUrl!)
                self.roomAvatarImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultRoomImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            }
            roomNameLabel.text = room.roomname
        }
    }
    
}
