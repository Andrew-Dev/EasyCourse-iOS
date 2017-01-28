//
//  UserRoomDetailTableVC.swift
//  EasyCourse
//
//  Created by Andrew Arpasi on 11/12/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class UserRoomDetailTableVC: UITableViewController {

    var room:Room!
    var user:User?
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var silentSwitch: UISwitch!
    @IBOutlet weak var roomPictureView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        silentSwitch.isOn = room.silent
        usernameLabel.text = user?.username
        roomPictureView.image = Design.defaultAvatarImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            removeFriendAlert()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 20
        }
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    @IBAction func silentSwitchChange(_ sender: UISwitch) {
        sender.isEnabled = false
        let realm = try! Realm()
        let hud = JGProgressHUD()
        hud.show(in: self.view)
        SocketIOManager.sharedInstance.silentFriend(user!.id!, silent: sender.isOn) { (afterSilent, error) in
            if error != nil {
                sender.isOn = !sender.isOn
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error?.description
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
            } else {
                hud.dismiss()
                try! realm.write {
                    self.room.silent = sender.isOn
                }
            }
            sender.isEnabled = true
        }
    }
    
    func removeFriendAlert() {
        let otherUserName = user!.username ?? "user"
        let alert = UIAlertController(title: "Remove friend", message: "You will no longer receive \(otherUserName)'s message. You can message him/her to allow him/her to talk to you again.", preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Remove", style: .destructive, handler: { (UIAlertAction) in
            let hud = JGProgressHUD()
            hud.show(in: self.view)
            SocketIOManager.sharedInstance.removeFriend(self.user!.id!, completion: { (success, error) in
                if success {
                    hud.dismiss()
                    _ = self.navigationController?.popToRootViewController(animated: true)
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
            })
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(delete)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func report() {
        let alert = UIAlertController(title: "Report", message: "Please fill the reason", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Reason"
        })
        let report = UIAlertAction(title: "Report", style: .destructive, handler: { (UIAlertAction) in
            ServerConst.sharedInstance.reportToServer((self.user?.id)!, reason: alert.textFields![0].text, completion: { (success, error) in
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
