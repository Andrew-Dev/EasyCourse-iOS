//
//  RoomsAddRoomNameTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit

class RoomsAddRoomNameTVCell: UITableViewCell, UITextFieldDelegate {

    
    @IBOutlet weak var cameraBtn: UIButton!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var nameConfirmBtn: UIButton!
    
    @IBOutlet weak var nameConfirmBtnWidthConstraint: NSLayoutConstraint!
    
    var delegate:RoomsAddRoomVCProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        nameConfirmBtn.isHidden = true
        nameConfirmBtnWidthConstraint.constant = 56
        nameTextField.becomeFirstResponder()
        nameTextField.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(roomName:String, nameIsConfirmed:Bool?) {
        nameTextField.text = roomName
        showConfirmBtn(showBtn: !(nameIsConfirmed ?? true), showKeyboard: nil)
    }
    
    func showConfirmBtn(showBtn:Bool, showKeyboard:Bool?) {
        nameConfirmBtn.isHidden = !showBtn
        nameConfirmBtnWidthConstraint.constant = showBtn ? 56 : 0
        self.layoutIfNeeded()
        if showKeyboard != nil {
            if showKeyboard! {
                nameTextField.becomeFirstResponder()
            } else {
                nameTextField.resignFirstResponder()
            }

        }
    }
    
    @IBAction func nameConfirmBtnPressed(_ sender: UIButton) {
        showConfirmBtn(showBtn: false, showKeyboard: false)
        delegate?.nameConfirmed()
    }

    @IBAction func cameraBtnPressed(_ sender: UIButton) {
    }
    
    @IBAction func nameTextFieldChanged(_ sender: AnyObject) {
        if nameConfirmBtn.isHidden {
            showConfirmBtn(showBtn: true, showKeyboard: true)
        }
        delegate?.nameTextFieldChanged(text: sender.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.nameConfirmed()
        showConfirmBtn(showBtn: false, showKeyboard: false)
        return true
    }
    
}
