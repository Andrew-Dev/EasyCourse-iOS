//
//  LoadingTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 10/6/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit


// suggested default height: 55

class LoadingTVCell: UITableViewCell {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var resultLabelVerticalConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(loadingStatus: Constant.searchStatus, text:String?) {
        switch loadingStatus {
        case .isSearching:
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            resultLabel.text = "Loading..."
            self.layoutIfNeeded()
            resultLabelVerticalConstraint.constant = 10
        case .receivedEmptyResult:
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            resultLabel.text = "No results"
            self.layoutIfNeeded()
            resultLabelVerticalConstraint.constant = 0
        default:
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            resultLabel.text = text ?? "No results"
            self.layoutIfNeeded()
            resultLabelVerticalConstraint.constant = 0
            
        }
    }
    
}


