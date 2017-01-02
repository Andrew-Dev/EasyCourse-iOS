//
//  RoomDetailClassmatesTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 12/30/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomDetailClassmatesTVCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        avatarImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(user:User) {
        nameLabel.text = user.username ?? ""
        if let userImgUrlStr = user.profilePictureUrl {
            let URL = Foundation.URL(string: userImgUrlStr)
            avatarImageView.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
        } else {
            avatarImageView.image = Design.defaultAvatarImage
        }
    }

}
