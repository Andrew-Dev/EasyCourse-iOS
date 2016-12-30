//
//  RoomsAddRoomBelongingTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 12/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomBelongingTVCell: UITableViewCell {
    
    @IBOutlet weak var courseLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        courseLabel.text = "Please choose"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(courseChoosed: Bool, course: Course?) {
        if courseChoosed {
            if course == nil {
                courseLabel.text = "private"
            } else {
                courseLabel.text = course?.coursename ?? "-"
            }
        } else {
            courseLabel.text = "Please choose"
        }
    }
}
