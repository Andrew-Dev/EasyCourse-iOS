//
//  UserRoomsVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

@objc protocol cellTableviewProtocol : NSObjectProtocol {
    func reloadTableView()-> Void
    @objc optional func displayViews(_ id: String)->Void
}

class UserRoomsVC: UIViewController, cellTableviewProtocol {
    
    @IBOutlet weak var roomsTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    let userRooms = try! Realm().objects(Room.self)
    var filterRooms:[Room] = []
    var isSearching = false
    var notificationToken: NotificationToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "My rooms"
        
        roomsTableView.delegate = self
        roomsTableView.dataSource = self
        roomsTableView.tableFooterView = UIView()
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        
        notificationToken = userRooms.addNotificationBlock({ (result) in
            self.roomsTableView.reloadData()
        })
    }
    
    deinit {
        notificationToken?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    @IBAction func searchRoomTextChanged(_ sender: UITextField) {
        let text = sender.text ?? ""
        filterRooms = []
        if !text.isEmpty {
            SocketIOManager.sharedInstance.searchRoom(text) { (rooms, error) in
                self.filterRooms = rooms
                self.isSearching = true
                self.roomsTableView.reloadData()
            }
        } else {
            isSearching = false
            self.roomsTableView.reloadData()
        }
    }
    
    func reloadTableView() {
        roomsTableView.reloadData()
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

extension UserRoomsVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}

extension UserRoomsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filterRooms.count : userRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserRoomsTVCell", for: indexPath) as! UserRoomsTVCell
        if isSearching {
            cell.configureCell(filterRooms[indexPath.row], userJoinedRooms: userRooms)
        } else {
            cell.configureCell(userRooms[indexPath.row], userJoinedRooms: userRooms)
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
