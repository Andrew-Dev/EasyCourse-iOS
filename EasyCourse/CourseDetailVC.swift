//
//  CourseDetailVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/29/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import JGProgressHUD
import RealmSwift

protocol CourseDetailVCProtocol : NSObjectProtocol {
    // true is join and false is drop
    func joinOrDropCourse(join:Bool) -> Void
    func joinOrDropRoom(join:Bool, roomId:String) -> Void
}

class CourseDetailVC: UIViewController {

    
    @IBOutlet weak var courseTableView: UITableView!
    
    var rooms:[Room] = []
    var courseId:String!
    var course:Course?
    var userHasJoinThisCourse = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        courseTableView.delegate = self
        courseTableView.dataSource = self
        courseTableView.estimatedRowHeight = 44
        courseTableView.rowHeight = UITableViewAutomaticDimension
        courseTableView.tableFooterView = UIView()
        
        
        reloadTableView()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadSubrooms() {
        SocketIOManager.sharedInstance.getCourseSubrooms(nil, courseId: courseId, skip: 0, limit: 20) { (roomArray, error) in
            if roomArray == nil {
                //TODO
            } else {
                self.rooms = roomArray!
                self.courseTableView.reloadSections([1], with: .automatic)
            }
        }
    }
    
    func reloadTableView() {
        userHasJoinThisCourse = User.currentUser!.hasJoinedCourse(courseId)
        SocketIOManager.sharedInstance.getCourseInfo(courseId, loadType: .cacheAndNetwork) { (crs, error) in
            if crs == nil {
                //TODO:
            } else {
                self.course = crs!
                self.courseTableView.reloadSections([0], with: .automatic)
            }
        }
        
        loadSubrooms()
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


extension CourseDetailVC:UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return rooms.count + 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "CourseDetailTitleCell", for: indexPath) as! CourseDetailTitleCell
            cell.delegate = self
            cell.configureCell(course: course)
            return cell
        case (1,0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "CourseDetailUnivCell", for: indexPath) as! CourseDetailUnivCell
//            cell.configureCell(course: course)
            return cell
        case (1,1...rooms.count):
            let cell = tableView.dequeueReusableCell(withIdentifier: "CourseDetailSubroomCell", for: indexPath) as! CourseDetailSubroomCell
            cell.delegate = self
            cell.configureCell(rooms[indexPath.row - 1], showJoinBtn: userHasJoinThisCourse)
            return cell
        default:
            return UITableViewCell()
        }
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        switch (indexPath.section, indexPath.row) {
//        case (0,0):
//            return 67
//        default:
//            return 44
//        }
//    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 10
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Rooms"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            let sb = UIStoryboard(name: "Room", bundle: nil)
            let vc = sb.instantiateViewController(withIdentifier: "RoomsAddRoomVC") as! RoomsAddRoomVC
            if let course = try! Realm().object(ofType: Course.self, forPrimaryKey: self.courseId) {
                vc.belongedCourse = course
                vc.belongedCourseChoosed = true
            }
            let navi = UINavigationController(rootViewController: vc)
            self.navigationController?.present(navi, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension CourseDetailVC: CourseDetailVCProtocol {

    func joinOrDropCourse(join: Bool) {
        
        if join {
            let hud = JGProgressHUD(style: .extraLight)
            hud?.show(in: self.view, animated: true)
            SocketIOManager.sharedInstance.joinCourse([courseId], languages: nil, completion: { (success, error) in
                if success {
                    hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud?.dismiss()
                    self.reloadTableView();
                } else {
                    hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud?.textLabel.text = error?.description ?? "Error, try again"
                    hud?.tapOutsideBlock = { (hu) in
                        hud?.dismiss()
                    }
                    hud?.tapOnHUDViewBlock = { (hu) in
                        hud?.dismiss()
                    }
                }
            })
        } else {
            let alert = UIAlertController(title: "Important", message: "If you drop a course, then you will automatically quit all rooms belongs to this course", preferredStyle: .alert)
            let drop = UIAlertAction(title: "Drop course", style: .destructive, handler: { (UIAlertAction) in
                let hud = JGProgressHUD(style: .extraLight)
                hud?.show(in: self.view, animated: true)
                
                SocketIOManager.sharedInstance.dropCourse(self.courseId, completion: { (success, error) in
                    if success {
                        hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                        hud?.dismiss()
                        self.reloadTableView()
                    } else {
                        hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud?.textLabel.text = error?.description ?? "Error, try again"
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
            alert.addAction(drop)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    func joinOrDropRoom(join: Bool, roomId: String) {
        let hud = JGProgressHUD(style: .extraLight)
        hud?.show(in: self.view, animated: true)
        if join {
            SocketIOManager.sharedInstance.joinRoom(roomId, completion: { (room, error) in
                if error == nil {
                    hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud?.dismiss()
                    self.courseTableView.reloadData()
                } else {
                    hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud?.textLabel.text = error?.description ?? "Error, try again"
                    hud?.tapOutsideBlock = { (hu) in
                        hud?.dismiss()
                    }
                    hud?.tapOnHUDViewBlock = { (hu) in
                        hud?.dismiss()
                    }
                }
            })
        } else {
            SocketIOManager.sharedInstance.quitRoom(roomId, completion: { (success, error) in
                if success {
                    hud?.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud?.dismiss()
                    self.courseTableView.reloadData()
                } else {
                    hud?.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud?.textLabel.text = error?.description ?? "Error, try again"
                    hud?.tapOutsideBlock = { (hu) in
                        hud?.dismiss()
                    }
                    hud?.tapOnHUDViewBlock = { (hu) in
                        hud?.dismiss()
                    }
                }
            })
        }
    }
    
    
}
