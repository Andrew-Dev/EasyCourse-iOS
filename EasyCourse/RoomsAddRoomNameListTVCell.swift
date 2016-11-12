//
//  RoomsAddRoomNameListCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomNameListTVCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roomImageView: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(roomName: String, roomImageUrl:String?) {
        nameLabel.text = roomName
        
    }

}
