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
    
    @IBOutlet weak var operationImgView: UIImageView!
    
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
            self.backgroundColor = Design.color.cellSelectedGreen()
            operationImgView.image = UIImage(named: "close-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            operationImgView.tintColor = UIColor.red
        } else {
            self.backgroundColor = UIColor.white
            operationImgView.image = UIImage(named: "plus-ion")!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            operationImgView.tintColor = UIColor(red: 0, green: 200/255, blue: 7/255, alpha: 1)
        }
    }
    
}
