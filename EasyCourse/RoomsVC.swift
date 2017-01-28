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
    var courseResults: [Course] = []
    var localRoomResults: Results<Room>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomTableView.delegate = self
        roomTableView.dataSource = self
        roomTableView.tableFooterView = UIView()
        roomTableView.register(UINib(nibName: "RoomsTVHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "RoomsTVHeaderView")
        
        

        
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
        
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
//        searchBar.tintColor = .white
        searchBar.setTextColor(color: .white)
        self.navigationItem.titleView = searchBar
        
        searchResultsTableView.frame = self.view.frame
        searchResultsTableView.backgroundColor = UIColor.groupTableViewBackground
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.tableFooterView = UIView()
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
//                vc.localRoomId = sortedRooms[indexPath.row].0.id
                
                if indexPath.section < User.currentUser!.joinedCourse.count {
                    // Course rooms
                    if let courseId = User.currentUser?.joinedCourse[indexPath.section].id {
                        let room = User.currentUser!.joinedRoom.filter("courseID = '\(courseId)'")[indexPath.row]
                        vc.localRoomId = room.id
                    } else {
                        print("segue error at index: \(indexPath)")
                    }
                } else {
                    // 'personal' rooms
                    let room = User.currentUser!.joinedRoom.filter("courseID = nil && isToUser = true")[indexPath.row]
                    vc.localRoomId = room.id
                }
            }
            
        }
        
    }
    
    func showAddRoom() {
        self.performSegue(withIdentifier: "showAddRoom", sender: self)
    }
    
    func doneSearching() {
        hideTabbar(hide: false)
        searchBar.resignFirstResponder()
        searchBar.text = ""
        courseResults = []
        searchResultsTableView.reloadData()
        let addRoomBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.showAddRoom))
        self.navigationItem.rightBarButtonItem = addRoomBtn
        searchResultsTableView.removeFromSuperview()
    }

}

extension RoomsVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == roomTableView {
            // + 1 is for the 'personal' (private chat and rooms without course)
            return User.currentUser!.joinedCourse.count + 1
        }
        
        if tableView == searchResultsTableView {
            if searchBar.text == "" {
                return 0
            } else if User.currentUser != nil && User.currentUser!.joinedRoom.count > 0 {
                return 2
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == roomTableView {
            if section < User.currentUser!.joinedCourse.count {
                // Course rooms
                if let course = User.currentUser?.joinedCourse[section] {
                    if course.collapseOnRoomMenu {
                        return 0
                    } else {
                        return User.currentUser!.joinedRoom.filter("courseID = '\(course.id!)'").count
                    }
                } else {
                    return 0
                }
            } else {
                // 'personal' rooms
                return User.currentUser!.joinedRoom.filter("courseID = nil").count
            }
        }
        
        if tableView == searchResultsTableView {
            if section == 0 {
                if localRoomResults != nil {
                    return localRoomResults!.count
                }
                return 0
            } else if section == 1 {
                return courseResults.count
            }
        }
        
        return 0
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == roomTableView {
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "RoomsTVHeaderView") as! RoomsTVHeaderView
            view.roomVC = self
            if section < User.currentUser!.joinedCourse.count {
                // Course rooms
                view.configureHeader(course: User.currentUser?.joinedCourse[section], isPersonal: false)
            } else {
                // 'Personal' rooms
                view.configureHeader(course: nil, isPersonal: true)
            }
            return view
        }
        
        if tableView == searchResultsTableView {
            let alertView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30))
            let alertLabel = UILabel(frame: CGRect(x: 16, y: 0, width: self.view.frame.width-32, height: 30))
            alertLabel.numberOfLines = 1
            alertView.backgroundColor = UIColor.groupTableViewBackground
            if section == 0 && localRoomResults?.count != 0 {
                alertLabel.text = "My Rooms"
            } else if section == 1 && courseResults.count != 0{
                alertLabel.text = "Courses"
            }
            alertView.addSubview(alertLabel)
            return alertView
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == roomTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsTVCell_v2", for: indexPath) as! RoomsTVCell_v2
            
            if indexPath.section < User.currentUser!.joinedCourse.count {
                // Course rooms
                if let courseId = User.currentUser?.joinedCourse[indexPath.section].id {
                    let room = User.currentUser!.joinedRoom.filter("courseID = '\(courseId)'")[indexPath.row]
                    cell.configureCell(room)
                } else {
                    print("course error at index: \(indexPath)")
                }
            } else {
                // 'personal' rooms
                let room = User.currentUser!.joinedRoom.filter("courseID = nil")[indexPath.row]
                cell.configureCell(room)
            }
            return cell
        }
        
        if tableView == searchResultsTableView {
            if indexPath.section == 0 {
//                let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsTVCell_v2", for: indexPath) as! RoomsTVCell_v2
                let room = localRoomResults![indexPath.row]
//                cell.configureCell(room)
                let cell = UITableViewCell()
                cell.textLabel?.text = room.roomname
                
                return cell
            } else if indexPath.section == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "UserCoursesTVCell", for: indexPath) as! UserCoursesTVCell
                cell.configureCell(courseResults[indexPath.row], userJoinedCourses: User.currentUser!.joinedCourse)
                return cell
            }
            
        }

        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchResultsTableView {
            let cell = tableView.cellForRow(at: indexPath)
            searchBar.resignFirstResponder()
            if indexPath.section == 0 {
                let storyboard = UIStoryboard(name: "Room", bundle: nil)
                let roomVC = storyboard.instantiateViewController(withIdentifier: "RoomsDialogVC") as! RoomsDialogVC
                let roomId = localRoomResults![indexPath.row].id
                roomVC.localRoomId = roomId
                self.navigationController?.pushViewController(roomVC, animated: true)
            } else if indexPath.section == 1 {
                let storyboard = UIStoryboard(name: "User", bundle: nil)
                let courseDetailVC = storyboard.instantiateViewController(withIdentifier: "CourseDetailVC") as! CourseDetailVC
                if let cell = tableView.cellForRow(at: indexPath) as? UserCoursesTVCell {
                    courseDetailVC.courseId = cell.cellCourse?.id
                    self.navigationController?.pushViewController(courseDetailVC, animated: true)
                }
            }
        } else {
            self.performSegue(withIdentifier: "gotoLocalRoom", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == searchResultsTableView {
            if indexPath.section == 0 {
                return 44
            } else if indexPath.section == 1 {
                return 65
            }
        }
        
        if tableView == roomTableView {
            return 55
        }
        return 0
    }

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == roomTableView {
            return 35
        }
        
        if tableView == searchResultsTableView {
            return 30
        }
        
        return 0
    }
    
    func tapHeader(course:Course?, isPersonal:Bool) {
        if isPersonal {
            
        } else if course != nil {
            
            // Must toggle first to let tableview insert/delete cell
            try! Realm().write {
                course!.collapseOnRoomMenu = !course!.collapseOnRoomMenu
            }
            
            if let section = User.currentUser!.joinedCourse.index(of: course!) {
                if course!.collapseOnRoomMenu {
                    var indexPaths:[IndexPath] = []
                    for i in 0..<self.roomTableView.numberOfRows(inSection: section) {
                        indexPaths.append(IndexPath(row: i, section: section))
                    }
                    self.roomTableView.deleteRows(at: indexPaths, with: .top)
                } else {
                    var indexPaths:[IndexPath] = []
                    for i in 0..<User.currentUser!.joinedRoom.filter("courseID = '\(course!.id!)'").count {
                        indexPaths.append(IndexPath(row: i, section: section))
                    }
                    self.roomTableView.insertRows(at: indexPaths, with: .top)
                }
            }
            
        }
    }
    
//    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 10
//    }
}

extension RoomsVC: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        hideTabbar(hide: true)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneSearching))
        navigationItem.rightBarButtonItem = doneBtn
        
        searchResultsTableView.alpha = 0
        self.view.addSubview(searchResultsTableView)
        
        UIView.animate(withDuration: 0.3) { 
            self.searchResultsTableView.alpha = 1
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        SocketIOManager.sharedInstance.searchCourse(searchText, universityId: User.currentUser!.universityId!, limit: 15, skip: 0, completion: { (courseArr, error) in
            if error == nil {
                self.courseResults = courseArr
                self.searchResultsTableView.reloadData()
            }
        })
        localRoomResults = User.currentUser?.joinedRoom.filter("roomname CONTAINS[c] '" + searchBar.text! + "'")
        self.searchResultsTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.endEditing(true)
    }

    
    func hideTabbar(hide:Bool) {
        print("tabbar: \(tabBarController!.tabBar.frame.origin.y) and \(self.view.frame.maxY)")
        if hide {
            if tabBarController!.tabBar.frame.origin.y < self.view.frame.maxY {
                return
            }
        } else {
            if tabBarController!.tabBar.frame.origin.y < self.view.frame.maxY {
                return
            }
        }
        
        var offsetY = -self.tabBarController!.tabBar.frame.size.height
        if hide {
            offsetY = -offsetY
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.tabBarController?.tabBar.frame = self.tabBarController!.tabBar.frame.offsetBy(dx: 0, dy: offsetY)
            return
        })
    }

}
