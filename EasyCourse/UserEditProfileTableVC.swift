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

class UserEditProfileTableVC: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    var tap:UITapGestureRecognizer?
    var picker = UIImagePickerController()
    var profileImgModified = false
    var usernameModified = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissSubView))
        picker.delegate = self
        picker.allowsEditing = true

        
        initProfilePicture()
        
        usernameTextField.text = User.currentUser?.username
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveProfile))
        
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initProfilePicture() {
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width/2
        profilePictureImageView.layer.masksToBounds = true
        if let avatarData = User.currentUser?.profilePicture {
            profilePictureImageView.image = UIImage(data: avatarData as Data)
        } else if let avatarUrl = User.currentUser?.profilePictureUrl {
//            profilePictureImageView.af_setImageWithURL(URL(string: avatarUrl)!, placeholderImage: nil)
            profilePictureImageView.af_setImage(withURL: URL(string: avatarUrl)!, placeholderImage: nil)
        } else {
            profilePictureImageView.image = Design.defaultAvatarImage
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 0 {
            if (indexPath as NSIndexPath).row == 0 {
                showChangeAvatarAlertView()
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
        if sender.text == nil {
            
        } else if sender.text! != User.currentUser?.username {
            
        }
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
        profileImgModified = true
    }
    
    func saveProfile() {
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.square = true
        if usernameTextField.text == User.currentUser?.username && !profileImgModified {
            //NOTHING changed
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Nothing changed"
            hud.tapOutsideBlock = { (hu) in
                hud.dismiss()
            }
            hud.tapOnHUDViewBlock = { (hu) in
                hud.dismiss()
            }
            hud.show(in: self.view)
            return
        } else if usernameTextField.text == nil {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Username is empty"
            hud.tapOutsideBlock = { (hu) in
                hud.dismiss()
            }
            hud.tapOnHUDViewBlock = { (hu) in
                hud.dismiss()
            }
            hud.show(in: self.view)
            return
        }
        
        hud.textLabel.text = "Uploading"
        hud.show(in: self.view)
        if profileImgModified {
            ServerConst.sharedInstance.uploadImage(self.profilePictureImageView.image!, uploadType: .avatar, room: nil, completion: { (imageUrl, progress, error) in
                print("image URL: \(imageUrl)")
                if imageUrl != nil {
                    SocketIOManager.sharedInstance.updateUser(self.usernameTextField.text, userProfileImageUrl: imageUrl!)
                    hud.textLabel.text = "Success"
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.dismiss(afterDelay: 1, animated: true)
                    Async.main(after: 1, { 
                        self.navigationController?.popViewController(animated: true)
                    })
                } else if error != nil {
                    //TODO: fail situation
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.textLabel.text = "Error"
                    hud.tapOutsideBlock = { (hu) in
                        hud.dismiss()
                    }
                    hud.tapOnHUDViewBlock = { (hu) in
                        hud.dismiss()
                    }
                }
            })
        } else {
            SocketIOManager.sharedInstance.updateUser(self.usernameTextField.text, userProfileImageUrl: nil)
            hud.textLabel.text = "Success"
            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            hud.dismiss(afterDelay: 1, animated: true)
            Async.main(after: 1, {
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
}
