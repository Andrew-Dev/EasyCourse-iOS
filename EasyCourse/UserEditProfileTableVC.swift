//
//  UserEditProfileTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/15/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import AlamofireImage
import JGProgressHUD
import Async

class UserEditProfileTableVC: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var userEmailLabel: UILabel!

    var tap:UITapGestureRecognizer?
    var picker = UIImagePickerController()
//    var profileImgModified = false
    var usernameModified = false
    var modifiedAvatar:UIImage?
    var userChoosedLang:[String] = User.currentUser!.userLang()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissSubView))
        picker.delegate = self
        picker.allowsEditing = true

        initData()
        
        
        usernameTextField.text = User.currentUser?.username
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveProfile))
        
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initData() {
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width/2
        profilePictureImageView.layer.masksToBounds = true
        if let avatarData = User.currentUser?.profilePicture {
            profilePictureImageView.image = UIImage(data: avatarData as Data)
        } else if let avatarUrl = User.currentUser?.profilePictureUrl {
            profilePictureImageView.af_setImage(withURL: URL(string: avatarUrl)!, placeholderImage: nil)
        } else {
            profilePictureImageView.image = Design.defaultAvatarImage
        }
        userEmailLabel.text = User.currentUser?.email
        
    }
    
    func keyboardWasShown(_ notification:Notification) {
        self.view.addGestureRecognizer(tap!)
    }
    
    func keyboardWillDisappear(_ notification:Notification) {
        self.view.removeGestureRecognizer(tap!)
    }
    
    func dismissSubView() {
        self.view.endEditing(true)
    }
    

    @IBAction func usernameTextFieldEditingChanged(_ sender: UITextField) {
//
    }
    
    func showChangeAvatarAlertView() {
        let alert = UIAlertController(title: "choose", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            self.openCamera()
        })
        let albumAction = UIAlertAction(title: "Gallery", style: .default, handler: { (action) in
            self.openGallary()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cameraAction)
        alert.addAction(albumAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: {
            //
        })
    }

    func openCamera() {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func openGallary() {
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    //PickerView Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismiss(animated: true, completion: nil)
        self.profilePictureImageView.image = image
        modifiedAvatar = image
    }
    
    func saveProfile() {
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.square = true
        var errorReason:String?
        if usernameTextField.text == nil {
            errorReason = "Username is empty"
        } else if usernameTextField.text!.trimWhiteSpace().isEmpty {
            errorReason = "Username is empty"
            
        }
        
        if errorReason != nil {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = errorReason
            hud.tapOutsideBlock = { (hu) in hud.dismiss() }
            hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
            hud.show(in: self.view)
            return
        }
        
//        hud.textLabel.text = "Uploading"
        hud.show(in: self.view)
        SocketIOManager.sharedInstance.syncUser(self.usernameTextField.text, userProfileImage: modifiedAvatar, userLang: nil) { (success, error) in
            if success {
                hud.textLabel.text = "Success"
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss(afterDelay: 1, animated: true)
                _ = self.navigationController?.popViewController(animated: true)
            } else {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
            }
        }
        
        
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    }

}

extension UserEditProfileTableVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                showChangeAvatarAlertView()
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "gotoResetPassword", sender: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 14
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if User.currentUser?.email != nil {
                return 3
            } else {
                return 2
            }
        } else if section == 1 {
            if User.currentUser?.fbUser.value == true {
                return 0
            } else {
                return 1
            }
        }
        return 0
    }
}
