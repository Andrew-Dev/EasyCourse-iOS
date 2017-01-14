//
//  UserResetPasswordTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/8/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import JVFloatLabeledTextField
import JGProgressHUD

class UserResetPasswordTableVC: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var oldPwTextField: JVFloatLabeledTextField!
    
    @IBOutlet weak var newPwTextField: JVFloatLabeledTextField!
    
    @IBOutlet weak var newPwConfirmTextField: JVFloatLabeledTextField!
    
    @IBOutlet weak var newPwAlertImgView: UIImageView!
    
    @IBOutlet weak var newPwConfirmAlertImgView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.postResetPassword))

        self.navigationItem.rightBarButtonItem = saveButton
        
        oldPwTextField.delegate = self
        newPwTextField.delegate = self
        newPwConfirmTextField.delegate = self
        
        oldPwTextField.returnKeyType = .next
        newPwTextField.returnKeyType = .next
        newPwConfirmTextField.returnKeyType = .done
        
        newPwAlertImgView.isHidden = true
        newPwConfirmAlertImgView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 40
        }
        return 14
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let alertView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 40))
            let alertLabel = UILabel(frame: CGRect(x: 16, y: 0, width: self.view.frame.width-32, height: 40))
            alertLabel.numberOfLines = 2
            alertLabel.textColor = UIColor.lightGray
            alertLabel.font = UIFont.systemFont(ofSize: 12)
            alertLabel.text = "Password needs to be 8-32 characters without space and special characters"
            alertView.addSubview(alertLabel)
            return alertView
        }
        return nil
    }
    
    @IBAction func oldPwChanged(_ sender: UITextField) {
    }
    
    @IBAction func newPwChanged(_ sender: UITextField) {
        if sender.text != nil {
            if sender.text!.removeSpecialCharsFromString().characters.count != sender.text!.characters.count {
                newPwAlertImgView.isHidden = false
                return
            }
            if sender.text!.characters.count < 8 || sender.text!.characters.count > 32{
                newPwAlertImgView.isHidden = false
            } else {
                newPwAlertImgView.isHidden = true
            }
        } else {
            newPwAlertImgView.isHidden = false
        }

    }
    
    @IBAction func confirmPwChanged(_ sender: UITextField) {
        if sender.text != nil {
            if sender.text != newPwTextField.text {
                newPwConfirmAlertImgView.isHidden = false
            } else {
                newPwConfirmAlertImgView.isHidden = true
            }
        } else {
            newPwConfirmAlertImgView.isHidden = false
        }

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == oldPwTextField {
            newPwTextField.becomeFirstResponder()
        } else if textField == newPwTextField {
            newPwConfirmTextField.becomeFirstResponder()
        } else if textField == newPwConfirmTextField {
            newPwConfirmTextField.resignFirstResponder()
        }
        return true
    }
    
    
    func postResetPassword() {
        self.view.endEditing(true)
        let oldPw = oldPwTextField.text
        let newPw = newPwTextField.text
        let hud = JGProgressHUD()
        hud.show(in: self.view)
        hud.backgroundColor = UIColor(white: 0, alpha: 0.5)
        var errorMsg:String?
        if User.currentUser?.email == nil {
            errorMsg = "This user doesn't set with email"
        } else if oldPw == nil || oldPw == "" {
            errorMsg = "Please fill the current password"
        } else if newPw == nil || newPw == "" {
            errorMsg = "Please fill the new password"
        } else if newPw!.removeSpecialCharsFromString().characters.count != newPw!.characters.count {
            errorMsg = "New password cannot contain space or special character"
        } else if newPw!.characters.count < 8 {
            errorMsg = "New password needs to be greater than 8 characters"
        } else if newPw!.characters.count > 32 {
            errorMsg = "New password needs to be less than 32 characters"
        } else if newPw != newPwConfirmTextField.text {
            errorMsg = "Please confirm new password"
        }
        if errorMsg != nil {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = errorMsg
            hud.tapOutsideBlock = { (hu) in hud.dismiss() }
            hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
            return
        }
        
        ServerConst.sharedInstance.resetPassword(User.currentUser!.email!, oldPassword: oldPw!, newPassword: newPw!) { (success, error) in
            if success {
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss()
                _ = self.navigationController?.popViewController(animated: true)
            } else {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description
                hud.tapOutsideBlock = { (hu) in hud.dismiss() }
                hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
            }
        }
        
    }

}
