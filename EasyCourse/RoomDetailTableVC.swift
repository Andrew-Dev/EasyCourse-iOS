//
//  RoomDetailTableVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class RoomDetailTableVC: UITableViewController {

    var room:Room!
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var roomPictureView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var subgroupsFounderLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationSwitch.isOn = room.silent
        roomNameLabel.text = room.roomname
        roomPictureView.image = Design.defaultRoomImage
        if room.isSystem.value! {
            subgroupsFounderLabel.text = "Subgroups"
        } else {
            subgroupsFounderLabel.text = "Founder"
            /*ServerConst.sharedInstance.getUserInfo(room.founderID!, refresh: true, completion: {(user,courses,error) in
                if error == nil {
                    if user == nil || user?.username == nil {
                        print("user nil")
                    } else {
                        self.subgroupsFounderLabel.text = "Founder: " + (user?.username!)!
                    }
                }
            })*/
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.tag == 1 {
            if room.isSystem.value! {
                self.performSegue(withIdentifier: "subgroupsSegue", sender: self)
            }
        } else if cell?.tag == 2 {
            self.performSegue(withIdentifier: "classmatesSegue", sender: self)
        }
    }
    
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
