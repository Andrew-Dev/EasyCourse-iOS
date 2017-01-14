//
//  RoomsAddRoomNameTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomNameTVCell: UITableViewCell, UITextFieldDelegate {

    
    
    @IBOutlet weak var nameTextField: UITextField!
    
    
    var delegate:RoomsAddRoomVCProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        nameTextField.becomeFirstResponder()
        nameTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(roomName:String) {
        nameTextField.text = roomName
    }
    
    
    @IBAction func nameTextFieldChanged(_ sender: AnyObject) {
        delegate?.nameTextFieldChanged(text: sender.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
