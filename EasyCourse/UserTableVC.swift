//
//  UserTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class UserTableVC: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var logoutBtn: UIButton!
    
    @IBOutlet weak var logoutBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var versionLabel: UILabel!
    
    var userInfoNotif:NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        avatarImageView.layer.masksToBounds = true
        logoutBtn.layer.cornerRadius = logoutBtn.frame.height/2
        logoutBtn.layer.masksToBounds = true
        logoutBtnWidthConstraint.constant = UIScreen.main.bounds.width * 0.8
        
        
        let dictionary = Bundle.main.infoDictionary!
        if let version = dictionary["CFBundleShortVersionString"] as? String, let build = dictionary["CFBundleVersion"] as? String {
            versionLabel.text = "v\(version).\(build)"
        } else {
            versionLabel.text = nil
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
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0,0):
            self.performSegue(withIdentifier: "gotoUserProfileVC", sender: self)
        case (1,0):
            self.performSegue(withIdentifier: "gotoUserCoursesVC", sender: self)
        case (2,0):
            self.performSegue(withIdentifier: "gotoUserRecruiteVC", sender: self)
        case (2,1):
            self.performSegue(withIdentifier: "gotoUserTermsVC", sender: self)
        default: break
            //
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    @IBAction func logoutBtnPressed(_ sender: UIButton) {
        SocketIOManager.sharedInstance.logout { (success, error) in
            //
            
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
