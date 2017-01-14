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
    let searchBar = UISearchBar()
    let searchResultsTableView = UITableView()
    var searchResults: [Course] = []
    
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
        
        searchBar.placeholder = "Search Courses"
        searchBar.delegate = self
        self.navigationItem.titleView = searchBar
        searchResultsTableView.register(UINib(nibName: "CourseTVCell", bundle: nil), forCellReuseIdentifier: "UserCoursesTVCell")
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
    
    func doneSearching() {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchResults = []
        searchResultsTableView.reloadData()
        let addRoomBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.showAddRoom))
        self.navigationItem.rightBarButtonItem = addRoomBtn
        searchResultsTableView.removeFromSuperview()
    }

}

extension RoomsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchResultsTableView {
            return searchResults.count
        }
        return sortedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchResultsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCoursesTVCell", for: indexPath) as! UserCoursesTVCell
            cell.configureCell(searchResults[indexPath.row], userJoinedCourses: User.currentUser!.joinedCourse)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsTVCell", for: indexPath) as! RoomsTVCell
        cell.configureCell(sortedRooms[(indexPath as NSIndexPath).row].0, lastMessage: sortedRooms[(indexPath as NSIndexPath).row].1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTableView {
            let storyboard = UIStoryboard(name: "User", bundle: nil)
            let courseDetailVC = storyboard.instantiateViewController(withIdentifier: "CourseDetailVC") as! CourseDetailVC
            if let cell = tableView.cellForRow(at: indexPath) as? UserCoursesTVCell {
                courseDetailVC.courseId = cell.cellCourse?.id
                self.navigationController?.pushViewController(courseDetailVC, animated: true)
            }

        } else {
            self.performSegue(withIdentifier: "gotoLocalRoom", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension RoomsVC: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneSearching))
        navigationItem.rightBarButtonItem = doneBtn
        searchResultsTableView.frame = roomTableView.frame
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.rowHeight = 65
        self.view.addSubview(searchResultsTableView)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        SocketIOManager.sharedInstance.searchCourse(searchText, universityId: User.currentUser!.universityId!, limit: 15, skip: 0, completion: { (courseArr, error) in
            if error == nil {
                self.searchResults = courseArr
                self.searchResultsTableView.reloadData()
            }
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
