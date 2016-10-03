//
//  Room.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/31/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class Room: Object {
    dynamic var id:String? = nil
    dynamic var roomname:String? = nil
    dynamic var coursePicture: Data? = nil
    dynamic var coursePictureUrl:String? = nil
    let memberCounts = RealmOptional<Int>()
    dynamic var courseID:String? = nil
    dynamic var courseName:String? = nil
    dynamic var university:String? = nil
    let memberList = List<User>()
    let messageList = List<Message>()
    dynamic var unread = 0
    
    //user built room
    dynamic var founderID:String? = nil
    
    //system
    let isSystem = RealmOptional<Bool>()
    let language = RealmOptional<Int>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getMessage() -> Results<(Message)> {
        return try! Realm().objects(Message.self).filter("roomId = '\(self.id!)'").sorted(byProperty: "createdAt", ascending: true)
    }
    
    func getMessageContainsImage() -> Results<(Message)> {
        return try! Realm().objects(Message.self).filter("roomId = '\(self.id!)' AND imageUrl != nil").sorted(byProperty: "createdAt", ascending: true)
    }
    
    internal class func initRoom(_ data:NSDictionary) -> Room? {
        if let id = data["_id"] as? String {
            let room = Room()
            room.id = id
            room.roomname = data["name"] as? String
            room.memberCounts.value = data["memberCounts"] as? Int
            room.courseID = data["course"] as? String
            room.courseName = data["courseName"] as? String
            room.university = data["university"] as? String
            room.founderID = data["founder"] as? String
            room.isSystem.value = data["isSystem"] as? Bool
            room.language.value = data["language"] as? Int
            return room
        } else {
            return nil
        }
    }
    
    internal class func initRoomAndSave(_ data:NSDictionary) {
        let room = Room()
        if let id = data["_id"] as? String {
            room.id = id
            room.roomname = data["name"] as? String
            room.memberCounts.value = data["memberCounts"] as? Int
            room.courseID = data["course"] as? String
            room.courseName = data["courseName"] as? String
            room.university = data["university"] as? String
            room.founderID = data["founder"] as? String
            room.isSystem.value = data["isSystem"] as? Bool
            room.language.value = data["language"] as? Int
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(room, update: true)
            }
        }
    }
    
    //    internal class func removeAllRoom() {
    //        let realm = try! Realm()
    //        let allRoom = realm.objects(Room)
    ////        realm.beginWrite()
    //        try! realm.write {
    //            for room in allRoom {
    //                realm.delete(room)
    //            }
    //        }
    //
    //    }
    
    internal class func syncRoom(_ rooms:[Room]) {
        var syncRoomsIDArray = [String]()
        var localRoomsIDArray = [String]()
        
        let realm = try! Realm()
        let localRooms = realm.objects(Room.self)
        
        localRooms.forEach { (room) in
            localRoomsIDArray.append(room.id!)
        }
        
        rooms.forEach { (room) in
            syncRoomsIDArray.append(room.id!)
        }
//        print("localroom: \(localRoomsIDArray)")
//        print("get rooms: \(syncRoomsIDArray)")
        
        try! realm.write({
            for room in localRooms where syncRoomsIDArray.index(of: room.id!) == nil {
                print("delete room \(room.roomname)")

                NotificationCenter.default.post(name: Constant.NotificationKey.RoomDelete, object: room.id)
                realm.delete(room)
                
            }
            for room in rooms where localRoomsIDArray.index(of: room.id!) == nil {
                print("add room \(room.roomname)")
                realm.add(room)
            }
        })
    }
    
    internal class func getAllRoom() -> [Room] {
        let realm = try! Realm()
        var rooms:[Room] = []
        let roomArr = realm.objects(Room.self)
        for room in roomArr {
            rooms.append(room)
        }
        return rooms
    }
    
    internal class func quitRoom(_ id: String) -> Bool {
        let realm = try! Realm()
        if let room = realm.object(ofType: Room.self, forPrimaryKey: id) {
            NotificationCenter.default.post(name: Constant.NotificationKey.RoomDelete, object: room.id)
            try! realm.write({
                realm.delete(room)
            })
            return true
        }
        return false
    }
}
