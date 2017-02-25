//
//  StudentTutorDetailTVCell.swift
//  EasyCourse
//
//  Created by Andrew Arpasi on 2/25/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class StudentTutorDetailTVCell: UITableViewCell {

    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var acceptButton: UIButton!
    
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    var pending: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(user: User, pending: Bool, accepted: Bool) {
        self.pending = pending
        if !pending && accepted {
            statusLabel.isHidden = false
            statusLabel.text = "Accepted"
        } else if !pending && !accepted {
            statusLabel.isHidden = false
            statusLabel.text = "Rejected"
        } else if pending {
            acceptButton.isHidden = false
            rejectButton.isHidden = false
        }
        userLabel.text = user.username
        if let url = user.profilePictureUrl {
            let URL = Foundation.URL(string: url)
            self.profileImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
        }
    }
    
    @IBAction func accept(_ sender: Any) {
        print("accept btn")
    }
    
    @IBAction func reject(_ sender: Any) {
        print("reject btn")
    }
}
