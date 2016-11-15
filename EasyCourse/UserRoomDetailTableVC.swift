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
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if(cell != nil && cell?.tag == 1) { //report
            report()
        }
    }
    
    @IBAction func silentSwitchChange(_ sender: UISwitch) {
        sender.isEnabled = false
        let realm = try! Realm()
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        ServerConst.sharedInstance.silentRoom(room.id!, silent: sender.isOn, completion: { (success, error) in
            sender.isEnabled = true
            print("finished")
            if success {
                hud.dismiss()
                try! realm.write {
                    self.room.silent = sender.isOn
                }
            } else {
                sender.isOn = !sender.isOn
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "Connect Error"
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
            }
        })
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
