//
//  UserRoomsTVCell.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class UserRoomsTVCell: UITableViewCell {

    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var membersCountLabel: UILabel!
    
    @IBOutlet weak var courseRelatedLabel: UILabel!
    
    @IBOutlet weak var FounderLabel: UILabel!
    
    @IBOutlet weak var operationBtn: UIButton!
    
    var enrolledIn = false
    var cellRoom:Room?
    var userJoinedThisRoom = false
    var delegate:cellTableviewProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        operationBtn.layer.cornerRadius = 6
        operationBtn.layer.borderWidth = 1
        operationBtn.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func configureCell(_ room:Room, userJoinedRooms:Results<(Room)>) {
        cellRoom = room
        roomNameLabel.text = room.roomname ?? "-"
        if let membersCnt = room.memberCounts.value {
            membersCountLabel.text = "\(membersCnt) people"
        }
//        courseRelatedLabel.text = room.courseName
        if room.isSystem.value == true {
            FounderLabel.text = "system"
        }
        
        
        userJoinedThisRoom = userJoinedRooms.contains { (joinedRoom) -> Bool in
            return room.id == joinedRoom.id
        }
        if userJoinedThisRoom {
            operationBtn.setTitle(" Quit ", for: UIControlState())
            operationBtn.setTitleColor(Design.color.deleteButtonColor(), for: UIControlState())
            operationBtn.layer.borderColor = Design.color.deleteButtonColor().cgColor
        } else {
            operationBtn.setTitle(" Join ", for: UIControlState())
            operationBtn.setTitleColor(self.tintColor, for: UIControlState())
            operationBtn.layer.borderColor = self.tintColor.cgColor
        }
    }
    
    @IBAction func operationBtnPressed(_ sender: UIButton) {
        if userJoinedThisRoom {
            print("click quit")
//            SocketIOManager.sharedInstance.quitRoom(cellRoom!.id!) { (success, error) in
//                self.delegate!.reloadTableView()
//            }
            SocketIOManager.sharedInstance.quitRoom(cellRoom!.id!, completion: { (success, error) in
                
                self.delegate!.reloadTableView()
            })
        } else {
            print("click join \(cellRoom?.roomname), \(cellRoom?.id)")
            SocketIOManager.sharedInstance.joinRoom(cellRoom!.id!, completion: { (success, error) in
                print("click join success: \(success) \(error)")
                self.delegate!.reloadTableView()
            })
        }
        
    }
    

}
