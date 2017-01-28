//
//  UserTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class UserTableVC: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var logoutBtn: UIButton!
    
    @IBOutlet weak var logoutBtnWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var versionLabel: UILabel!
        
    @IBOutlet weak var univLabel: UILabel!
    
    
    var userInfoNotif:NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        avatarImageView.layer.masksToBounds = true
        
        logoutBtnWidthConstraint.constant = UIScreen.main.bounds.width * 0.8
        logoutBtn.layer.cornerRadius = logoutBtnWidthConstraint.constant/8/2
        logoutBtn.layer.masksToBounds = true
        
        let dictionary = Bundle.main.infoDictionary!
        if let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String {
            versionLabel.text = "v\(version).\(build)"
        } else {
            versionLabel.text = nil
        }
        
        if let univId = User.currentUser?.universityId {
            SocketIOManager.sharedInstance.getUniversityInfo(univId, loadType: .cacheElseNetwork, completion: { (univ, error) in
                if error == nil {
                    self.univLabel.text = univ?.name
                }
            })

        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.loadUserInfo), name: Constant.NotificationKey.SyncUser, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadUserInfo() {
        if let avatarData = User.currentUser?.profilePicture {
            self.avatarImageView.image = UIImage(data: avatarData)
        } else if let avatarUrl = User.currentUser?.profilePictureUrl {
            let URL = Foundation.URL(string: avatarUrl)
            self.avatarImageView.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
        } else {
            self.avatarImageView.image = Design.defaultAvatarImage
        }
        usernameLabel.text = User.currentUser?.username

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 14
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            self.performSegue(withIdentifier: "gotoUserProfileVC", sender: self)
        case (0,1):
            self.performSegue(withIdentifier: "gotoChooseLanguage", sender: self)
        case (1,0):
            let alert = UIAlertController(title: "Current version doesn't support switch university", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        case (1,1):
            self.performSegue(withIdentifier: "gotoUserCoursesVC", sender: self)
        case (2,0):
            self.performSegue(withIdentifier: "gotoUserRecruiteVC", sender: self)
        case (2,1):
            self.performSegue(withIdentifier: "gotoUserTermsVC", sender: self)
        case (2,2):
            self.performSegue(withIdentifier: "gotoUserFeedbackVC", sender: self)
        default: break
            //
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    @IBAction func logoutBtnPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Sign out", message: nil, preferredStyle: .actionSheet)
        let signOut = UIAlertAction(title: "Sign out", style: .destructive, handler: { (UIAlertAction) in
            let hud = JGProgressHUD()
            hud.show(in: self.view)
            SocketIOManager.sharedInstance.logout { (success, error) in
                if !success {
                    hud.backgroundColor = UIColor(white: 0, alpha: 0.3)
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.textLabel.text = error?.description ?? "Fail sign out"
                    hud.tapOutsideBlock = { (hu) in hud.dismiss() }
                    hud.tapOnHUDViewBlock = { (hu) in hud.dismiss() }
                } else {
                    hud.dismiss()
                }
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(signOut)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "gotoChooseLanguage" {
//            let vc = segue.destination as! UserEditProfileChooseLangVC
//        }
    }

}
