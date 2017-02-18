//
//  TutorMyPostsTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/18/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit

class TutorMyPostsTVCell: UITableViewCell {

    @IBOutlet weak var courseLabel: UILabel!
    
    @IBOutlet weak var applicationCntLabel: UILabel!
    
    @IBOutlet weak var pendingCntLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!

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
        priceLabel.text = "$\(tutor.price ?? 0)/h"
        pendingCntLabel.text = "\(tutor.pendingCount ?? 0)"
        applicationCntLabel.text = "\(tutor.applicationCount ?? 0)"
    }

}
