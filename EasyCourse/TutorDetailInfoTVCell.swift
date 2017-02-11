//
//  TutorDetailTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/4/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class TutorDetailInfoTVCell: UITableViewCell {

    @IBOutlet weak var tutorAvatarImageView: UIImageView!
    
    @IBOutlet weak var tutorNameLabel: UILabel!
    
    @IBOutlet weak var courseLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var gradeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(tutor:Tutor) {
        courseLabel.text = tutor.courseName
        tutorNameLabel.text = tutor.tutorName
        if let price = tutor.price {
            priceLabel.text = "$\(price)/h"
        } else {
            priceLabel.text = "-"
        }
        descriptionLabel.text = tutor.tutorDescription
        gradeLabel.text = tutor.grade
        
        if let url = tutor.tutorAvatarUrl {
            let URL = Foundation.URL(string: url)
            self.tutorAvatarImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
        }
    }
}
