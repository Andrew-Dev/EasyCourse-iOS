//
//  RoomDetailShareRoomVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 12/30/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift
import JGProgressHUD

class RoomDetailShareRoomVC: UIViewController {

    @IBOutlet weak var roomListTableView: UITableView!
    
    var sendRoomId:String!
    var sendRoom:Room?
    var roomList:List<Room>? = User.currentUser!.joinedRoom
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomListTableView.delegate = self
        roomListTableView.dataSource = self
        roomListTableView.register(UINib(nibName: "RoomListTVCell", bundle: nil), forCellReuseIdentifier: "RoomListTVCell")

        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.dismissView))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        sendRoom = try! Realm().object(ofType: Room.self, forPrimaryKey: sendRoomId)
        if sendRoom != nil && sendRoom!.roomname != nil {
            navigationItem.title = "Share \(sendRoom!.roomname!)"
        } else {
            navigationItem.title = "Share this room"
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
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

extension RoomDetailShareRoomVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if roomList == nil {
            return 0
        } else {
            return roomList!.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomListTVCell", for: indexPath) as! RoomListTVCell
        cell.configureCell(room: roomList![indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let toRoom = roomList![indexPath.row]
        var roomname = ""
        let sendRoomname = sendRoom?.roomname ?? "room"
        if toRoom.isToUser {
            if let user = try! Realm().object(ofType: User.self, forPrimaryKey: toRoom.id) {
                roomname = user.username ?? ""
            }
        } else {
            roomname = toRoom.roomname ?? ""
        }
        let alert = UIAlertController(title: "Share \(sendRoomname)", message: "to \(roomname)", preferredStyle: .alert)
        let send = UIAlertAction(title: "Send", style: .default, handler: { (UIAlertAction) in
            
            let message = Message()
            message.initForCurrentUser(nil, image: nil, sharedRoom: self.sendRoomId, toRoom: toRoom.id, isToUser: false)
            message.saveToDatabase()
            let hud = JGProgressHUD()
            hud.show(in: self.navigationController?.view)
            SocketIOManager.sharedInstance.sendMessage(message, completion: { (success, error) in
                if success {
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.dismiss()
                    self.dismiss(animated: true, completion: nil)
                } else {
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.textLabel.text = error!.description
                    hud.dismiss(afterDelay: 2)
                }
            })
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(send)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}
