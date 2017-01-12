//
//  RoomsVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/25/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import SocketIO
import Alamofire
import RealmSwift
import SwiftMessages
import UserNotifications

//import Cache

class RoomsVC: UIViewController {
    
    @IBOutlet weak var roomTableView: UITableView!
    
    lazy var message = try! Realm().objects(Message.self)
//    lazy var rooms = try! Realm().objects(Room.self)
    lazy var rooms = User.currentUser!.joinedRoom
    var sortedRooms:[(room:Room,lastMessage:Message?)] = []
    var roomUpdateNotif: NotificationToken? = nil
    var messageUpdateNotif: NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomTableView.delegate = self
        roomTableView.dataSource = self
        roomTableView.tableFooterView = UIView()
        sortRooms()
//        if rooms.count == 0 {
//            SocketIOManager.sharedInstance.syncUser()
//        }
        
        let addRoomBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.showAddRoom))
        navigationItem.rightBarButtonItem = addRoomBtn
        
        roomUpdateNotif = rooms.addNotificationBlock({ (result) in
            self.sortRooms()
            self.roomTableView.reloadData()
        })
        messageUpdateNotif = message.addNotificationBlock({ (result) in
            print("room message update")
            self.sortRooms()
            self.roomTableView.reloadData()
        })
        
    }
    
    deinit {
        roomUpdateNotif?.stop()
        messageUpdateNotif?.stop()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UserSetting.shouldAskPushNotif {
            let alert = UIAlertController(title: "Tips", message: "Using push notifications may help you to receive more information on class.", preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: { (UIAlertAction) in
                self.registerPushNotif()
                UserSetting.shouldAskPushNotif = false
            })
            alert.addAction(okay)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerPushNotif() {
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func sortRooms() {
        sortedRooms = []
        rooms.forEach { (room) in

//            let lastMessage = try! Realm().objects(Message.self).filter("toRoom = '\(room.id!)'").sorted(byProperty: "createdAt", ascending: true).last
            if room.id != User.currentUser?.id {
                let lastMessage = room.getMessage().last
                sortedRooms.append((room,lastMessage))
            }
            
        }
        sortedRooms.sort { (a: (room:Room, msg:Message?), b: (room:Room, msg:Message?)) -> Bool in
            
            var aLastUpdate:Date?
            var bLastUpdata:Date?
            if a.room.lastUpdateTime != nil && a.msg?.createdAt != nil {
                if a.room.lastUpdateTime!.compare(a.msg!.createdAt!) == .orderedDescending {
                    aLastUpdate = a.room.lastUpdateTime! as Date
                } else {
                    aLastUpdate = a.msg!.createdAt!
                }
            } else {
                aLastUpdate = a.room.lastUpdateTime as Date? ?? a.msg?.createdAt
            }
            if aLastUpdate == nil { return false }
            if b.room.lastUpdateTime != nil && b.msg?.createdAt != nil {
                if b.room.lastUpdateTime!.compare(b.msg!.createdAt!) == .orderedDescending {
                    bLastUpdata = b.room.lastUpdateTime! as Date
                } else {
                    bLastUpdata = b.msg!.createdAt!
                }
            } else {
                bLastUpdata = b.room.lastUpdateTime as Date? ?? b.msg?.createdAt
            }
            if bLastUpdata == nil { return true }
            if aLastUpdate! > bLastUpdata! {
                return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoLocalRoom" {
            if let indexPath = roomTableView.indexPathForSelectedRow {
                let vc = segue.destination as! RoomsDialogVC
//                vc.localRoom = sortedRooms[indexPath.row].0
                vc.localRoomId = sortedRooms[indexPath.row].0.id
            }
            
        }
        
    }
    
    func showAddRoom() {
        self.performSegue(withIdentifier: "showAddRoom", sender: self)
    }
}

extension RoomsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsTVCell", for: indexPath) as! RoomsTVCell
        cell.configureCell(sortedRooms[(indexPath as NSIndexPath).row].0, lastMessage: sortedRooms[(indexPath as NSIndexPath).row].1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "gotoLocalRoom", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
