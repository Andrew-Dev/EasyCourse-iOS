//
//  RoomsDialogAccGroupVC.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/5/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class RoomsDialogAccGroupVC: UIViewController {
    
    @IBOutlet weak var groupTableView: UITableView!

    var toRoom:Room!
    let rooms = try! Realm().objects(Room.self).filter("isToUser == false")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        groupTableView.delegate = self
        groupTableView.dataSource = self
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelBtnPressed))
        navigationItem.leftBarButtonItem = cancelBtn
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancelBtnPressed() {
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

extension RoomsDialogAccGroupVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return rooms.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Create New Room"
        default:
            cell.textLabel?.text = rooms[indexPath.row].roomname
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.performSegue(withIdentifier: "gotoCreateRoom", sender: self)
        } else {
            let alertController = UIAlertController(title: "Send this room", message: rooms[indexPath.row].roomname, preferredStyle: .alert)
            let sendAction = UIAlertAction(title: "Send", style: .default, handler: { (action) in
                let message = Message()
                message.initForCurrentUser(nil, image: nil, sharedRoom: self.rooms[indexPath.row].id, toRoom: self.toRoom.id, isToUser: self.toRoom.isToUser)
                message.saveToDatabase()
                SocketIOManager.sharedInstance.sendMessage(message, completion: { (success, error) in
                    //TODO: message sent response
                })
                self.dismiss(animated: true, completion: nil)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) in

            })
            alertController.addAction(sendAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
            
            
            
        }
        
    }
}
