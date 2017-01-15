//
//  CourseDetailUnivCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class CourseDetailUnivCell: UITableViewCell {

    @IBOutlet weak var univLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        univLabel.text = "Create a section"
        //univLabel.textColor = Design.color.deepGreenPersianGreenColor()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(course:Course?) {
        univLabel.text = "-"
        guard let univId = course?.universityId else {
            return
        }

        SocketIOManager.sharedInstance.getUniversityInfo(univId, loadType: .cacheElseNetwork) { (university, error) in
            if university != nil {
                self.univLabel.text = university!.name
            } else {
                self.univLabel.text = "-"
            }
        }
    }
    

}
