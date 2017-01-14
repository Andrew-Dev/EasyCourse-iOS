//
//  RoomsAddRoomVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/3/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

protocol RoomsAddRoomVCProtocol : NSObjectProtocol {
//    func nameConfirmed() -> Void
    func nameTextFieldChanged(text:String) -> Void
    func courseSelect(course:Course?) -> Void
}

class RoomsAddRoomVC: UIViewController {

    @IBOutlet weak var addRoomTableView: UITableView!
    
    //Section 0: room name
    var roomName = ""
    var belongedCourse:Course?
    var belongedCourseChoosed = false
    var coursePickerIsOpen = false
    
    //Section 1: List existing rooms
    var existedRooms:[Room] = []
    var userJoinedCourse = User.currentUser?.joinedCourse
    var roomsearchStatus = Constant.searchStatus.notSearching
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addRoomTableView.delegate = self
        addRoomTableView.dataSource = self
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelBtnPressed))
        navigationItem.leftBarButtonItem = cancelBtn
        
        let createBtn = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.saveBtnPressed))
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
        let hud = JGProgressHUD()
        if roomName.isEmpty {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Room name required"
            hud.show(in: self.navigationController?.view)
            hud.dismiss(afterDelay: 1)
            return
        }
        if !belongedCourseChoosed {
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.textLabel.text = "Room belonging required"
            hud.show(in: self.navigationController?.view)
            hud.tapOutsideBlock = { (hu) in
                hud.dismiss()
            }
            hud.tapOnHUDViewBlock = { (hu) in
                hud.dismiss()
            }
            return
        }
        
        for room in existedRooms {
            if room.roomname == roomName {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = "Duplicated room name in this course"
                hud.show(in: self.navigationController?.view)
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
                return
            }
        }
        
        hud.indicatorView = JGProgressHUDIndicatorView()
        hud.show(in: self.navigationController?.view)
        
        SocketIOManager.sharedInstance.createRoom(roomName, course: belongedCourse?.id) { (room, error) in
            print("create room \(error)")
            if error != nil {
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.textLabel.text = error!.description
                hud.show(in: self.navigationController?.view)
                hud.tapOutsideBlock = { (hu) in
                    hud.dismiss()
                }
                hud.tapOnHUDViewBlock = { (hu) in
                    hud.dismiss()
                }
            } else {
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss()
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func reloadSubRooms() {
        if roomName.isEmpty || belongedCourse == nil {
            roomsearchStatus = .notSearching
            self.addRoomTableView.reloadSections([1], with: .automatic)
            return
        }
        
        SocketIOManager.sharedInstance.getCourseSubrooms(roomName, courseId: belongedCourse!.id!, skip: 0, limit: 20, completion: { (rooms, error) in
            if error != nil {
                self.roomsearchStatus = .receivedError
            } else {
                self.existedRooms = rooms!
                self.roomsearchStatus = self.existedRooms.isEmpty ? .receivedEmptyResult : .receivedResult
            }
            self.addRoomTableView.reloadSections([1], with: .automatic)
        })
    }
    
    func cancelBtnPressed() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension RoomsAddRoomVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if coursePickerIsOpen {
                return 3
            } else {
                return 2
            }
        case 1:
            return roomsearchStatus == .receivedResult ? existedRooms.count : 0
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
                cell.configureCell(roomName: roomName)
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomBelongingTVCell") as! RoomsAddRoomBelongingTVCell
//                cell.delegate = self
                cell.configureCell(courseChoosed: belongedCourseChoosed, course: belongedCourse)
                return cell
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomBelongingPickerTVCell") as! RoomsAddRoomBelongingPickerTVCell
                cell.delegate = self
//                cell.configureCell(roomName: roomName)
                return cell
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RoomsAddRoomNameListTVCell") as! RoomsAddRoomNameListTVCell
            cell.configureCell(existedRooms[indexPath.row], showJoinBtn: true)
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

        case 1:
            if belongedCourse != nil && roomsearchStatus == .receivedResult {
                return "Rooms in \(belongedCourse!.coursename!)"
            } else {
                return nil
            }

        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (0,1):
            belongedCourseChoosed = true
            addRoomTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            coursePickerIsOpen = !coursePickerIsOpen
            if coursePickerIsOpen {
                let a = IndexPath(row: 2, section: 0)
                addRoomTableView.insertRows(at: [a], with: .top)
            } else {
                let a = IndexPath(row: 2, section: 0)
                addRoomTableView.deleteRows(at: [a], with: .top)
            }
        default:
            break
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (0,2):
            return 144
        case (1,_):
            return 56
        default:
            return 44
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if roomsearchStatus == .receivedResult {
            view.endEditing(true)
        }
        
    }
    
    
}

extension RoomsAddRoomVC: RoomsAddRoomVCProtocol {

    func courseSelect(course: Course?) {
        belongedCourse = course
        existedRooms.removeAll()
        addRoomTableView.reloadSections([1], with: .automatic)
        addRoomTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        reloadSubRooms()
    }
    
    func nameTextFieldChanged(text: String) {
        roomName = text
        existedRooms.removeAll()
        self.addRoomTableView.reloadSections([1], with: .automatic)
        if belongedCourse != nil {
            reloadSubRooms()
        }
    }

}
