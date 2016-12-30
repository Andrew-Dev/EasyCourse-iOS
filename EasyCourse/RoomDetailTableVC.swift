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
import AlamofireImage

class RoomDetailTableVC: UITableViewController {

    var room:Room!
    var viewFromPopUp = false
    var userJoinedThisRoom = true
    
    // Cell tag:
    // 5: course
    
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var roomPictureView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!

    @IBOutlet weak var founderNameLabel: UILabel!
    
    @IBOutlet weak var founderAvatarImageView: UIImageView!
    @IBOutlet weak var classmatesCountLabel: UILabel!
    
    @IBOutlet weak var quitOrJoinRoomLabel: UILabel!
    
    @IBOutlet weak var courseNameLabel: UILabel!
    
    var deleteThisRoom = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        notificationSwitch.isOn = room.silent
        roomNameLabel.text = room.roomname
        if room.courseID != nil {
            SocketIOManager.sharedInstance.getCourseInfo(room.courseID!, loadType: .cacheElseNetwork, completion: { (course, error) in
                self.courseNameLabel.text = course?.coursename ?? ""
            })
        }
        
        roomPictureView.image = Design.defaultRoomImage
        founderAvatarImageView.layer.cornerRadius = founderAvatarImageView.frame.height/2
        founderAvatarImageView.layer.masksToBounds = true
        if room.founderID != nil {
            SocketIOManager.sharedInstance.getUserInfo(room.founderID!, refresh: false, completion: { (user, error) in
                if user != nil {
                    self.founderNameLabel.isHidden = false
                    self.founderNameLabel.text = user?.username
                    if let avatarUrl = user?.profilePictureUrl {
                        let URL = Foundation.URL(string: avatarUrl)
                        self.founderAvatarImageView.af_setImage(withURL: URL!, placeholderImage: Design.defaultAvatarImage, imageTransition: .crossDissolve(0.2), runImageTransitionIfCached: false, completion: nil)
                    }
                } else {
                    self.founderNameLabel.isHidden = true
                }
            })
        }
        
        classmatesCountLabel.text = "\(room.memberCounts.value ?? 0)"
        
        
        
        if viewFromPopUp {
            let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelBtnPressed))
            navigationItem.leftBarButtonItem = cancelBtn
        }

        setupJoinOrQuitLabel()
        
        SocketIOManager.sharedInstance.getRoomMembers(room.id!, limit: 20, skip: 0, refresh: true) { (room, err) in
            print("called: \(err)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        if deleteThisRoom {
            let realm = try! Realm()
            if let quitRoom = realm.object(ofType: Room.self, forPrimaryKey: room.id) {
                try! realm.write {
                    realm.delete(quitRoom)
                }
            }
        }
    }
    
    func setupJoinOrQuitLabel() {
//        let realm = try! Realm()
//        let isJoinIn = realm.object(ofType: Room.self, forPrimaryKey: room.id)
        if User.currentUser?.joinedRoom.index(of: room) != nil {
            quitOrJoinRoomLabel.text = "Quit room"
            quitOrJoinRoomLabel.textColor = Design.color.deleteButtonColor()
            userJoinedThisRoom = true
        } else {
            quitOrJoinRoomLabel.text = "Join room"
            quitOrJoinRoomLabel.textColor = Design.color.lightBlueMalibu()
            userJoinedThisRoom = false
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        switch cell!.tag {
        case 1: //Subgroup Cell
            if room.isSystem.value! {
                self.performSegue(withIdentifier: "subgroupsSegue", sender: self)
            }
        case 2: //Classmates Cell
            self.performSegue(withIdentifier: "classmatesSegue", sender: self)
        case 3: //Join or quit room
            if userJoinedThisRoom {
                popUpQuitRoomAlert()
            } else {
                popUpJoinRoomAlert()
            }
        case 5: //Course
//            self.performSegue(withIdentifier: "courseSegue", sender: self)
            let sb = UIStoryboard(name: "User", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "CourseDetailVC") as! CourseDetailVC
            vc.courseId = room.courseID
            self.navigationController?.pushViewController(vc, animated: true)

        default:
            break
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            return 66
        case (0,1):
            if room.courseID != nil {
                return 44
            } else {
                return 0
            }
        case (0,2):
            if room.founderID != nil {
                return 44
            } else {
                return 0
            }
        case (1,1):
            if room.isSystem.value != true  {
                return 0
            }
        case (2,0):
            if !userJoinedThisRoom {
                return 0
            }
        default:
            return 44
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        switch section {
        case 0:
            return 20
        case 2:
            if !userJoinedThisRoom {
                return 0.01
            }
        default:
            return 0.01
        }
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 2:
            if !userJoinedThisRoom {
                return 0.01
            }
        default:
            return 20
        }
        return 20
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "courseSegue" {
//            let vc = segue.destination as! CourseDetailVC
//            vc.courseId = room.courseID!
//            
//        }
    }
    
    // MARK: - Button pressed
    
    @IBAction func notificationSwitchChanged(_ sender: UISwitch) {
        sender.isEnabled = false
        let realm = try! Realm()
        let hud = JGProgressHUD()
        hud.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        
        SocketIOManager.sharedInstance.silentRoom(room.id!, silent: sender.isOn) { (success, error) in
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

        }
        
    }

    
    
    func cancelBtnPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func popUpQuitRoomAlert() {
        let alert = UIAlertController(title: "Are you sure to quit?", message: nil, preferredStyle: .alert)
        let quit = UIAlertAction(title: "Quit Room", style: .destructive, handler: { (UIAlertAction) in
            let hud = JGProgressHUD(style: .extraLight)
            hud?.textLabel.text = "Loading"
            hud?.show(in: self.navigationController?.view)
            SocketIOManager.sharedInstance.quitRoom(self.room.id!, completion: { (success, error) in
                print("quit room: \(success)")
                if success {
                    if !self.viewFromPopUp {
                        hud?.dismiss()
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: { 
                            //
                        })
                    }
                    self.deleteThisRoom = true
                } else {
                    
                    hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud?.textLabel.text = error?.description
                    hud?.tapOutsideBlock = { (hu) in
                        hud?.dismiss()
                    }
                    hud?.tapOnHUDViewBlock = { (hu) in
                        hud?.dismiss()
                    }
                    
                }
                
            })
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(quit)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func popUpJoinRoomAlert() {
        let alert = UIAlertController(title: "Join this room", message: nil, preferredStyle: .alert)
        let join = UIAlertAction(title: "Confirm", style: .default, handler: { (UIAlertAction) in
            let hud = JGProgressHUD(style: .extraLight)
            hud?.textLabel.text = "Loading"
            hud?.show(in: self.navigationController?.view)
            SocketIOManager.sharedInstance.joinRoom(self.room.id!, completion: { (room, error) in
                if error == nil {
                    hud?.dismiss()
                    if !self.viewFromPopUp {
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: {
                            //
                        })
                    }
                } else {
                    hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud?.textLabel.text = "Connect Error"
                    hud?.tapOutsideBlock = { (hu) in
                        hud?.dismiss()
                    }
                    hud?.tapOnHUDViewBlock = { (hu) in
                        hud?.dismiss()
                    }
                }
            })
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(join)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }


    
}

