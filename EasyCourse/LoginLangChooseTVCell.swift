//
//  LoginLangChooseTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class LoginLangChooseTVCell: UITableViewCell {
    
    @IBOutlet weak var langLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func configureCell(langText:String, choosed:Bool) {
        langLabel.text = langText
        if choosed {
            self.accessoryType = .checkmark
        } else {
            self.accessoryType = .none
        }
    }
    
}
