//
//  RoomsAddRoomVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

protocol RoomsAddRoomVCProtocol : NSObjectProtocol {
    func nameConfirmed() -> Void
    func nameTextFieldChanged(text:String) -> Void
}

class RoomsAddRoomVC: UIViewController {

    @IBOutlet weak var addRoomTableView: UITableView!
    
    //Section 0: room name
    var nameIsConfirmed:Bool?
    var roomName = ""
    var existedRooms:[Room] = []
    var userJoinedCourse = try! Realm().objects(Course.self)
    var roomsearchStatus = Constant.searchStatus.notSearching
    
    //Section 2: choosed belonged course
    var belongedCourse:Course?
    var belongedCourseChoosed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addRoomTableView.delegate = self
        addRoomTableView.dataSource = self
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelBtnPressed))
        navigationItem.leftBarButtonItem = cancelBtn
        
        let createBtn = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.saveBtnPressed))
        createBtn.isEnabled = false
        navigationItem.rightBarButtonItem = createBtn
        
        
        navigationItem.title = "New Room"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func saveBtnPressed() {
        SocketIOManager.sharedInstance.createRoom(roomName, course: belongedCourse?.id) { (success, error) in
            print("success \(success)")
            //TODO: error situation
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelBtnPressed() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension RoomsAddRoomVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            if nameIsConfirmed == true {
                return 0
            }
            let roomsRowsCount = min(10, existedRooms.count)
            return roomsearchStatus == .receivedResult ? roomsRowsCount : 0
        case 2:
            return belongedCourseChoosed ? 1 : userJoinedCourse.count + 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomNameTVCell") as! RoomsAddRoomNameTVCell
                cell.delegate = self
                cell.configureCell(roomName: roomName, nameIsConfirmed: nameIsConfirmed)
                return cell
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomNameListTVCell") as! RoomsAddRoomNameListTVCell
            cell.configureCell(roomName: existedRooms[indexPath.row].roomname ?? "", roomImageUrl: nil)
            return cell
        case 2:
            let cell = UITableViewCell()
            if belongedCourseChoosed {
                cell.textLabel?.text = belongedCourse?.coursename ?? "Not belonged to any course"
            } else {
                if indexPath.row == 0 {
                    cell.textLabel?.text = "Not belonged to any course"
                } else {
                    cell.textLabel?.text = userJoinedCourse[indexPath.row - 1].coursename
                }
            }
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomNameTVCell") as! RoomsAddRoomNameTVCell
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomNameTVCell") as! RoomsAddRoomNameTVCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Name (required)"
        case 1:
            if nameIsConfirmed == true {
                return nil
            }
            return roomsearchStatus == .receivedResult ? "Existed rooms" : nil
        case 2:
            return "From course (required)"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 2:
            if belongedCourseChoosed {
                belongedCourse = nil
                belongedCourseChoosed = false
            } else {
                if indexPath.row != 0 {
                    belongedCourse = userJoinedCourse[indexPath.row - 1]
                }
                belongedCourseChoosed = true
            }
            addRoomTableView.reloadSections([2], with: .automatic)
        default:
            break
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if roomsearchStatus == .receivedResult {
            view.endEditing(true)
        }
        
    }
    
    
}

extension RoomsAddRoomVC: RoomsAddRoomVCProtocol {
    func nameConfirmed() {
        nameIsConfirmed = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        addRoomTableView.reloadSections([1], with: .automatic)
    }
    
    func nameTextFieldChanged(text: String) {
        roomName = text
        nameIsConfirmed = false
        if text.isEmpty {
            roomsearchStatus = .notSearching
            self.addRoomTableView.reloadSections([1], with: .automatic)
            return
        }
        SocketIOManager.sharedInstance.searchRoom(text, limit: 10, skip: 0) { (rooms, error) in
            if error != nil {
                self.roomsearchStatus = .receivedError
            } else {
                self.existedRooms = rooms
                self.roomsearchStatus = self.existedRooms.isEmpty ? .receivedEmptyResult : .receivedResult
            }
            print("search room status: \(self.roomsearchStatus) \(self.existedRooms.count)")
            self.addRoomTableView.reloadSections([1], with: .automatic)
        }
    }

}
