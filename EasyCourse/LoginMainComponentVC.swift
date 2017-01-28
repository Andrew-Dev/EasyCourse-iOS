//
//  LoginMainComponentVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/28/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD
import RealmSwift
import FBSDKLoginKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class LoginMainComponentVC: UIViewController, UITextFieldDelegate {
    
    //    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    
    @IBOutlet weak var passwordTextfield: UITextField!
    
    
    @IBOutlet weak var userNameTextField: UITextField!
    
    //    @IBOutlet weak var confirmPasswordTextfield: UITextField!
    
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var signupBtn: UIButton!
    
    @IBOutlet weak var facebookLoginBtn: UIButton!
    
    @IBOutlet weak var emailBtn: UIButton!
    
    @IBOutlet weak var loginBtnToFBBtnVerticleConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var FBBtnToVerCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var FBBtnWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var FBBtnHeightConstraint: NSLayoutConstraint!
    
    //    @IBOutlet weak var loginBtnWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var confirmPasswordHeightConstraint: NSLayoutConstraint!
    
    var emailFieldIsClosed = true
    var tap:UITapGestureRecognizer?
    
    weak var delegate: loginProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.view.backgroundColor = Design.color.DarkGunPowder()
        titleLabel.textColor = UIColor.white
        
        emailBtn.tintColor = UIColor.white
        
        tap =  UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        
        emailTextField.delegate = self
        passwordTextfield.delegate = self
        userNameTextField.delegate = self
        
        emailTextField.isHidden = true
        passwordTextfield.isHidden = true
        userNameTextField.isHidden = true
        loginBtn.isHidden = true
        signupBtn.isHidden = true
        
        emailTextField.alpha = 0
        passwordTextfield.alpha = 0
        userNameTextField.alpha = 0
        loginBtn.alpha = 0
        signupBtn.alpha = 0
        
        facebookLoginBtn.alpha = 0.95
        FBBtnWidthConstraint.constant = UIScreen.main.bounds.width * 0.9
        FBBtnHeightConstraint.constant = FBBtnWidthConstraint.constant * 0.13
        
        if FBBtnHeightConstraint.constant > 37.5 {
            FBBtnHeightConstraint.constant = FBBtnHeightConstraint.constant + 5
        }
        
        facebookLoginBtn.backgroundColor = Design.color.facebookColor()
        facebookLoginBtn.setTitleColor(UIColor.white, for: UIControlState())
        facebookLoginBtn.setTitleColor(UIColor.white, for: .selected)
        facebookLoginBtn.layer.cornerRadius = FBBtnHeightConstraint.constant/2
        facebookLoginBtn.layer.masksToBounds = true
        
        
        setLoginbtnHighlighted()
        
        
        
        //Constraint
        loginBtnToFBBtnVerticleConstraint.constant = -50
        confirmPasswordHeightConstraint.constant = 0
        
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillAppear(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(self.keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MessageAlert.sharedInstance.closeAlert()
    }
    
    func setLoginbtnHighlighted() {
        loginBtn.alpha = 0.95
        loginBtn.backgroundColor = Design.color.lighterGreenMountainMead()
        loginBtn.setTitleColor(UIColor.white, for: UIControlState())
        loginBtn.setTitleColor(UIColor.white, for: .selected)
        loginBtn.layer.cornerRadius = FBBtnHeightConstraint.constant/2
        loginBtn.layer.masksToBounds = true
        loginBtn.layer.borderWidth = 0
        
        
        signupBtn.alpha = 0.95
        signupBtn.setTitleColor(UIColor.white, for: UIControlState())
        signupBtn.setTitleColor(UIColor.white, for: .selected)
        signupBtn.layer.cornerRadius = FBBtnHeightConstraint.constant/2
        signupBtn.layer.borderColor = UIColor.white.cgColor
        signupBtn.layer.borderWidth = 2
        signupBtn.layer.masksToBounds = true
        signupBtn.backgroundColor = nil
    }
    
    func setSignupbtnHighlighted() {
        signupBtn.backgroundColor = Design.color.lighterGreenMountainMead()
        signupBtn.setTitleColor(UIColor.white, for: UIControlState())
        signupBtn.setTitleColor(UIColor.white, for: .selected)
        signupBtn.layer.borderWidth = 0
        
        
        loginBtn.setTitleColor(UIColor.white, for: UIControlState())
        loginBtn.setTitleColor(UIColor.white, for: .selected)
        loginBtn.layer.borderColor = UIColor.white.cgColor
        loginBtn.layer.borderWidth = 2
        loginBtn.backgroundColor = nil
    }
    
//    override func viewWillLayoutSubviews() {
//        print("called")
//        
//    }
//    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Buttons
    @IBAction func emailBtnPressed(_ sender: UIButton) {

        self.view.endEditing(true)
        emailBtn.isEnabled = false
        
        if emailFieldIsClosed {
            emailTextField.isHidden = false
            passwordTextfield.isHidden = false
            loginBtn.isHidden = false
            signupBtn.isHidden = false
            
            
            
            self.emailBtn.setTitle("", for: .selected)
            self.emailBtn.setTitle("", for: UIControlState())
            self.emailBtn.setImage(UIImage(named: "up-arrow-circled"), for: .selected)
            self.emailBtn.setImage(UIImage(named: "up-arrow-circled"), for: UIControlState())
//            self.view.layoutIfNeeded()
            
            
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.loginBtnToFBBtnVerticleConstraint.constant = 8
                self.FBBtnToVerCenterConstraint.constant = 90
                self.emailTextField.alpha = 1
                self.passwordTextfield.alpha = 1
                self.loginBtn.alpha = 0.95
                self.signupBtn.alpha = 0.95
                
                print("view: \(self.emailTextField.isHidden), \(self.emailTextField.frame), \(self.emailTextField.alpha)")
                
                self.view.layoutIfNeeded()
                }, completion: { (success) in
                    if success {
                        self.emailFieldIsClosed = false
                        self.emailBtn.isEnabled = true
                    }
            })
            
        } else {
            self.emailBtn.setImage(nil, for: .selected)
            self.emailBtn.setImage(nil, for: UIControlState())
            self.emailBtn.setTitle("E-mail", for: .selected)
            self.emailBtn.setTitle("E-mail", for: UIControlState())
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.loginBtnToFBBtnVerticleConstraint.constant = -50
                self.FBBtnToVerCenterConstraint.constant = 60
                self.confirmPasswordHeightConstraint.constant = 0
                
                self.emailTextField.alpha = 0
                self.passwordTextfield.alpha = 0
                self.userNameTextField.alpha = 0
                self.loginBtn.alpha = 0
                self.signupBtn.alpha = 0
                
                self.view.layoutIfNeeded()
                }, completion: { (success) in
                    if success {
                        self.userNameTextField.text = nil
                        self.passwordTextfield.text = nil
                        self.emailTextField.isHidden = true
                        self.passwordTextfield.isHidden = true
                        self.userNameTextField.isHidden = true
                        self.loginBtn.isHidden = true
                        self.signupBtn.isHidden = true
                        
                        self.emailFieldIsClosed = true
                        self.emailBtn.isEnabled = true
                        
                        self.setLoginbtnHighlighted()
                    }
            })
            
            
        }
        
    }
    
    @IBAction func facebookLoginBtnPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        ServerConst.sharedInstance.loginWithFacebook(self) { (success, error) in
            if success {
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss(afterDelay: 1, animated: true)
                self.gotoNextScreen()
            } else if error != nil {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description ?? "Error"
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
            } else {
                hud.dismiss()
            }
        }
        
        
    }
    
    @IBAction func loginBtnPressed(_ sender: UIButton) {
        self.view.endEditing(true)
        setLoginbtnHighlighted()
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.confirmPasswordHeightConstraint.constant = 0
            self.userNameTextField.alpha = 0
            self.view.layoutIfNeeded()
            
        }) { (success) in
            if success {
                if self.userNameTextField.isHidden == false {
                    self.userNameTextField.isHidden = true
                    return
                }
                self.userNameTextField.isHidden = true
                
                //                if !self.checkUsernamePassword(false) { return }
                if !self.validateInput(false) { return }
                let hud = JGProgressHUD()
                hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                //hud.square = true
                
//                if Reachability.isConnectedToNetwork() == true {
                    hud.textLabel.text = "Loading"
                    hud.show(in: self.view)
                    
                    //MARK: user log in
                    ServerConst.sharedInstance.loginWithEmail(self.emailTextField.text!, password: self.passwordTextfield.text!, completion: { (success, error) in
                        if success {
                            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                            hud.dismiss(afterDelay: 1, animated: true)
                            self.gotoNextScreen()
                        } else {
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.textLabel.text = error?.description ?? "Error"
                            hud.tapOutsideBlock = { (hu) in
                                hud.dismiss()
                            }
                            hud.tapOnHUDViewBlock = { (hu) in
                                hud.dismiss()
                            }
                        }
                    })
//                } else {
//                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
//                    hud.textLabel.text = "Network error!"
//                    hud.show(in: self.navigationController?.view)
//                    hud.dismiss(afterDelay: 2, animated: true)
//                }
                
            }
        }
    }
    
    @IBAction func signUpBtnPressed(_ sender: UIButton) {
        setSignupbtnHighlighted()
        if userNameTextField.isHidden == true {
            userNameTextField.isHidden = false
            
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.userNameTextField.alpha = 1
                self.confirmPasswordHeightConstraint.constant = self.FBBtnHeightConstraint.constant
                self.view.layoutIfNeeded()
            }) { (success) in
                if !self.emailTextField.text!.isEmpty && !self.passwordTextfield.text!.isEmpty {
                    self.userNameTextField.becomeFirstResponder()
                }
            }
        } else {
            self.view.endEditing(true)
            if !self.validateInput(true) { return }
            
            
            let alert = UIAlertController(title: "Terms & privacy", message: "By signing up, you agree to our EasyCourse Terms and have read our privacy at the bottom of the page.", preferredStyle: .alert)
            let signUp = UIAlertAction(title: "Sign up", style: .default, handler: { (UIAlertAction) in
                let hud = JGProgressHUD()
                hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                hud.show(in: self.view)
                //MARK:sign up
                ServerConst.sharedInstance.signupWithEmail(self.emailTextField.text!, password: self.passwordTextfield.text!, username: self.userNameTextField.text!, completion: { (success, error) in
                    if success {
                        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                        hud.textLabel.text = "Success!"
                        hud.dismiss(afterDelay: 1, animated: true)
                        self.gotoNextScreen()
                    } else {
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.textLabel.text = error?.description ?? "Error"
                        hud.tapOutsideBlock = { (hu) in
                            hud.dismiss()
                        }
                        hud.tapOnHUDViewBlock = { (hu) in
                            hud.dismiss()
                        }
                    }
                })
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(signUp)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
            
            
            
            
        }
        
    }
    
    //MARK: - Check username password
    func validateInput(_ isSignUp:Bool) -> Bool {
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        print("email is: \(emailTextField.text!) + \(emailTextField.text!.isValidEmail())")
        if !emailTextField.text!.isValidEmail() {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = emailTextField.text!.isEmpty ? "Email required" : "Email format incorrect"
            hud.show(in: self.view)
            hud.tapOutsideBlock = { (hu) in
                hud.dismiss()
            }
            hud.tapOnHUDViewBlock = { (hu) in
                hud.dismiss()
            }
            return false
        }
        
        if passwordTextfield.text!.isEmpty {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Password required"
            hud.show(in: self.view)
            hud.tapOutsideBlock = { (hu) in
                hud.dismiss()
            }
            hud.tapOnHUDViewBlock = { (hu) in
                hud.dismiss()
            }
            return false
        }
        
        if isSignUp {
            if passwordTextfield.text?.characters.count < 8 {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = passwordTextfield.text!.isEmpty ? "Password required" : "Password should have at least 8 characters"
                hud.show(in: self.view)
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
                return false
            }
            
            if userNameTextField.text!.isEmpty {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "Please enter username"
                hud.show(in: self.view)
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
                return false
            }
            
            if passwordTextfield.text?.characters.count > 24 {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "Username cannot exceeds 24 characters"
                hud.show(in: self.view)
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
                return false
            }
            
        }
        return true
    }
    
    
    //    func presentMainScreenVC() {
    //        let sb = UIStoryboard(name: "Main", bundle: nil)
    //        let mainTabBarController = sb.instantiateViewControllerWithIdentifier("BaseTabBarController") as! UITabBarController
    //        self.presentViewController(mainTabBarController, animated: true, completion: nil)
    //    }
    
    //MARK: - Textfield
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextfield.becomeFirstResponder()
        } else if textField == passwordTextfield {
            if userNameTextField.isHidden == true {
                passwordTextfield.resignFirstResponder()
            } else {
                userNameTextField.becomeFirstResponder()
            }
            
        } else if textField == userNameTextField {
            userNameTextField.resignFirstResponder()
        }
        return true
    }
    
    //MARK: - Keyboard Changed
    func keyboardWillAppear(_ notification: Notification){
        // Do something here
        view.addGestureRecognizer(tap!)
    }
    
    func keyboardWillDisappear(_ notification: Notification){
        // Do something here
        view.removeGestureRecognizer(tap!)
    }
    
    func dismissKeyboard(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
    func gotoNextScreen() {
        let realm = try! Realm()
        print("goto next screen: user=\(User.currentUser), course: \(realm.objects(Course.self))")
        if User.currentUser?.universityId == nil {
            delegate?.moveToVC(0)
        } else if realm.objects(Course.self).count == 0 {
            delegate?.moveToVC(1)
        } else {
            delegate?.showMainTabBarVC(false)
        }
    }
    
    @IBAction func termsPressed(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string: "http://www.easycourse.io/docs")! as URL)
    }    
    
}
