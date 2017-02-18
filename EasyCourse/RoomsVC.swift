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
import DZNEmptyDataSet

//import Cache

class RoomsVC: UIViewController {
    
    @IBOutlet weak var roomTableView: UITableView!
    
    lazy var message = try! Realm().objects(Message.self)
    lazy var rooms = User.currentUser!.joinedRoom
    var sortedRooms:[(room:Room,lastMessage:Message?)] = []
    var sortedRooms_v2:[String:[(room:Room,lastMessage:Message?)]] = [:]
    var roomUpdateNotif: NotificationToken? = nil
    var messageUpdateNotif: NotificationToken? = nil
    
    // Search bar
    let searchBar = UISearchBar()
    let searchResultsTableView = UITableView()
    var courseResults: [Course] = []
    var localRoomResults: Results<Room>? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User id: \(User.currentUser?.id)")
        roomTableView.delegate = self
        roomTableView.dataSource = self
        roomTableView.tableFooterView = UIView()
        roomTableView.register(UINib(nibName: "RoomsTVHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "RoomsTVHeaderView")
        
        sortRoom2()
//        sortRooms()
//        if rooms.count == 0 {
//            SocketIOManager.sharedInstance.syncUser()
//        }
        
        let addRoomBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.showAddRoom))
        navigationItem.rightBarButtonItem = addRoomBtn
        
        roomTableView.emptyDataSetSource = self
        roomTableView.emptyDataSetDelegate = self
        searchResultsTableView.emptyDataSetSource = self
        searchResultsTableView.emptyDataSetDelegate = self
        
        searchBar.placeholder = "Search course/section"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
//        searchBar.tintColor = .white
        searchBar.setTextColor(color: .white)
        self.navigationItem.titleView = searchBar
        
        searchResultsTableView.backgroundColor = UIColor.groupTableViewBackground
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.tableFooterView = UIView()
        searchResultsTableView.register(UINib(nibName: "CourseTVCell", bundle: nil), forCellReuseIdentifier: "UserCoursesTVCell")

    }
    
    deinit {
        print("room VC deinit")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        roomUpdateNotif = rooms.addNotificationBlock({ (result) in
            //            self.sortRooms()
            self.sortRoom2()
            self.roomTableView.reloadData()
            Tools.sharedInstance.setTabBarBadge()
        })
        messageUpdateNotif = message.addNotificationBlock({ (result) in
            print("room message update")
            //            self.sortRooms()
            self.sortRoom2()
            self.roomTableView.reloadData()
            Tools.sharedInstance.setTabBarBadge()

        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchResultsTableView.frame.size = self.view.frame.size

        roomTableView.reloadData()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        roomUpdateNotif?.stop()
        messageUpdateNotif?.stop()
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
    
    func sortRoom2() {
        sortedRooms_v2 = [:]
        rooms.forEach { (room) in
            let lastMessage = room.getMessage().last
            var roomKey = ""
            if room.courseID != nil {
                roomKey = room.courseID!
            } else if room.isToUser == true && room.id != User.currentUser!.id {
                roomKey = "Personal"
            }
            
            if sortedRooms_v2[roomKey] == nil {
                sortedRooms_v2[roomKey] = [(room,lastMessage)]
            } else {
                sortedRooms_v2[roomKey]?.append((room,lastMessage))
            }
            
        }

        
        sortedRooms_v2.forEach { (courseTuple) in
            sortedRooms_v2[courseTuple.key]?.sort { (a: (room:Room, msg:Message?), b: (room:Room, msg:Message?)) -> Bool in
                
                var aLastUpdate:Date?
                var bLastUpdata:Date?
                if a.room.lastUpdateTime != nil && a.msg?.createdAt != nil {
                    if a.room.lastUpdateTime!.compare(a.msg!.createdAt!) == .orderedDescending {
                        aLastUpdate = a.room.lastUpdateTime! as Date
                    } else {
                        aLastUpdate = a.msg!.createdAt!
                    }
                } else {
                    aLastUpdate = a.msg?.createdAt ?? a.room.lastUpdateTime as Date?
                }
                if aLastUpdate == nil { return false }
                if b.room.lastUpdateTime != nil && b.msg?.createdAt != nil {
                    if b.room.lastUpdateTime!.compare(b.msg!.createdAt!) == .orderedDescending {
                        bLastUpdata = b.room.lastUpdateTime! as Date
                    } else {
                        bLastUpdata = b.msg!.createdAt!
                    }
                } else {
                    bLastUpdata = b.msg?.createdAt ?? b.room.lastUpdateTime as Date?
                }
                if bLastUpdata == nil { return true }
                if aLastUpdate! > bLastUpdata! {
                    return true
                } else {
                    return false
                }
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
//                        let room = User.currentUser!.joinedRoom.filter("courseID = '\(courseId)'")[indexPath.row]
                        if let courseTuple = sortedRooms_v2[courseId] {
//                            cell.configureCell(courseTuple[indexPath.row].room)
                            vc.localRoomId = courseTuple[indexPath.row].room.id
                        }
//                        vc.localRoomId = room.id
                    } else {
                        print("segue error at index: \(indexPath)")
                    }
                } else {
                    // 'personal' rooms
                    if let courseTuple = sortedRooms_v2["Personal"] {
                        vc.localRoomId = courseTuple[indexPath.row].room.id
                    }
                }
            }
            
        }
        
    }
    
    func showAddRoom() {
        self.performSegue(withIdentifier: "showAddRoom", sender: self)
    }
    
    func doneSearching() {
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
            if User.currentUser!.joinedRoom.filter("courseID = nil").count > 0 {
                return User.currentUser!.joinedCourse.count + 1
            }
            return User.currentUser!.joinedCourse.count
        }
        
        if tableView == searchResultsTableView {
//            print("Text: " + searchBar.text!)
//            print("Local Results:")
//            print(localRoomResults)
//            print("Course Results")
//            print(courseResults)
            if searchBar.text == "" || (localRoomResults!.count == 0 && courseResults.count == 0) {
                return 0
            } else if User.currentUser != nil && User.currentUser!.joinedRoom.count > 0 && localRoomResults!.count > 0{
                return 2
            } else if User.currentUser!.joinedRoom.count == 0 || localRoomResults!.count == 0 {
                return 1
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
                        return sortedRooms_v2[course.id!]?.count ?? 0
                    }
                } else {
                    return 0
                }
            } else {
                // 'personal' rooms
                return sortedRooms_v2["Personal"]?.count ?? 0
            }
        }
        
        if tableView == searchResultsTableView {
            if section == 0 {
                if localRoomResults!.count > 0 {
                    return localRoomResults!.count
                } else {
                    return courseResults.count
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
            } else if (section == 0 && localRoomResults?.count == 0) || (section == 1 && courseResults.count != 0) {
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
                    if let courseTuple = sortedRooms_v2[courseId] {
                        cell.configureCell(courseTuple[indexPath.row].room)
                    }
                } else {
                    print("course error at index: \(indexPath)")
                }
            } else {
                // 'personal' rooms
                if let courseTuple = sortedRooms_v2["Personal"] {
                    cell.configureCell(courseTuple[indexPath.row].room)
                }
            }
            return cell
        }
        
        if tableView == searchResultsTableView {
            if indexPath.section == 0 && localRoomResults!.count > 0 {
                let room = localRoomResults![indexPath.row]
                let cell = UITableViewCell()
                cell.textLabel?.text = room.roomname
                return cell
            } else if (indexPath.section == 0 && localRoomResults!.count == 0) || indexPath.section == 1 {
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
            if indexPath.section == 0 && localRoomResults!.count > 0 {
                let storyboard = UIStoryboard(name: "Room", bundle: nil)
                let roomVC = storyboard.instantiateViewController(withIdentifier: "RoomsDialogVC") as! RoomsDialogVC
                let roomId = localRoomResults![indexPath.row].id
                roomVC.localRoomId = roomId
                self.navigationController?.pushViewController(roomVC, animated: true)
            } else if (indexPath.section == 0 && localRoomResults!.count == 0) || indexPath.section == 1 {
                let storyboard = UIStoryboard(name: "User", bundle: nil)
                let courseDetailVC = storyboard.instantiateViewController(withIdentifier: "CourseDetailVC") as! CourseDetailVC
                if let cell = tableView.cellForRow(at: indexPath) as? UserCoursesTVCell {
                    courseDetailVC.courseId = cell.cellCourse?.id
                    courseDetailVC.hidesBottomBarWhenPushed = true
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
            if indexPath.section == 0 && localRoomResults!.count > 0 {
                return 44
            } else if (indexPath.section == 0 && localRoomResults!.count == 0) || indexPath.section == 1 {
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
            } else {
                self.searchResultsTableView.reloadData()
            }
        })
        localRoomResults = User.currentUser?.joinedRoom.filter("roomname CONTAINS[c] '" + searchBar.text! + "'")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.endEditing(true)
    }

}

extension RoomsVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "DefaultRoom")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = ""
        if scrollView == searchResultsTableView {
            if searchBar.text == "" {
                text = "Search For Rooms/Courses"
            } else {
                text = "No results."
            }
        } else {
            text = "No Rooms Joined"
        }
        let attributedString = NSAttributedString(string: text, attributes: [ NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 18.0)! ])
        return attributedString
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var text = ""
        if scrollView == searchResultsTableView {
            if searchBar.text == "" {
                text = "Search for rooms and courses which you can join."
            } else {
                text = "No results could be found. Please try a different query."
            }
        }
        text = "Search for courses using the search bar above to join rooms."
        let attributedString = NSAttributedString(string: text, attributes: [ NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 14.0)! ])
        return attributedString
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        if scrollView == searchResultsTableView {
            return -scrollView.frame.height / 4
        }
        return 0
    }

}
