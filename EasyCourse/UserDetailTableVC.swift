//
//  UserDetailTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/16/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD
import RealmSwift
import Async

class UserDetailTableVC: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var messageBtn: UIButton!
    
    @IBOutlet weak var reportBtn: UIButton!
    
    @IBOutlet weak var messageBtnWidthConstraint: NSLayoutConstraint!
    
    var user:User?
    var userId:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width/2
        avatarImageView.layer.masksToBounds = true
        avatarImageView.image = Design.defaultAvatarImage
        
        messageBtnWidthConstraint.constant = UIScreen.main.bounds.width * 0.8
        messageBtn.layer.cornerRadius = messageBtnWidthConstraint.constant/8/2
        messageBtn.layer.masksToBounds = true
        
        SocketIOManager.sharedInstance.getUserInfo(userId!, loadType: .cacheAndNetwork) { (user, error) in
            if error != nil {
                //TODO: no user
                return
            }
            self.user = user
            self.usernameLabel.text = user?.username
            if let userImgUrlStr = user?.profilePictureUrl {
                let URL = Foundation.URL(string: userImgUrlStr)
                self.avatarImageView.af_setImage(withURL: URL!, placeholderImage: nil, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
            } else {
                self.avatarImageView.image = Design.defaultAvatarImage
            }

        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func messageBtnPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RoomsDialogVC") as! RoomsDialogVC
        let realm = try! Realm()
        if let room = realm.object(ofType: Room.self, forPrimaryKey: self.userId) {
//            vc.localRoom = room
            vc.localRoomId = room.id
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            try! realm.write({
                let room = Room()
                room.id = self.userId
                room.isToUser = true
                realm.add(room, update: true)
//                vc.localRoom = room
                vc.localRoomId = room.id
                self.navigationController?.pushViewController(vc, animated: true)
            })
        }
        


    }
    
    
    @IBAction func reportBtnPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Report", message: "Please fill the reason", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Reason"
        })
        let report = UIAlertAction(title: "Report", style: .destructive, handler: { (UIAlertAction) in
            ServerConst.sharedInstance.reportToServer(self.user!.id!, reason: alert.textFields![0].text, completion: { (success, error) in
                print("report successful \(success)")
                let hud = JGProgressHUD()
                hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                hud.textLabel.text = "Posting"
                hud.show(in: self.view)
                if success {
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.textLabel.text = "Success!"
                    hud.dismiss(afterDelay: 2, animated: true)
                } else {
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.textLabel.text = "Fail to report"
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
        alert.addAction(report)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    

}
