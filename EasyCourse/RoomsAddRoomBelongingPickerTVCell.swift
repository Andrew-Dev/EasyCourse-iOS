//
//  RoomsAddRoomBelongingPickerTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 12/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomBelongingPickerTVCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {

    
    @IBOutlet weak var coursePicker: UIPickerView!
    
    var courseList = User.currentUser!.joinedCourse
    var delegate:RoomsAddRoomVCProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coursePicker.delegate = self
        coursePicker.dataSource = self
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return courseList.count + 1
    }
    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return courseList[row].coursename
//    }
//    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var text = ""
        if row == 0 {
            text = "private"
        } else {
            text = courseList[row - 1].coursename ?? ""
        }
        let attrText = NSMutableAttributedString(string: text)
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .right
        let fontStyle = UIFont.systemFont(ofSize: 12)
        let color = UIColor.darkGray
        let range = NSMakeRange(0, text.characters.count)
        attrText.addAttribute(NSParagraphStyleAttributeName, value: textStyle, range: range)
        attrText.addAttribute(NSUnderlineColorAttributeName, value: color, range: range)
        attrText.addAttribute(NSFontAttributeName, value: fontStyle, range: range)
        return attrText
    }
    
//    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        var label = UILabel()
//        if view == nil {
//            
//        }
//        
//    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            delegate?.courseSelect(course: nil)
        } else {
            delegate?.courseSelect(course: courseList[row - 1])
        }
    }
    

}
