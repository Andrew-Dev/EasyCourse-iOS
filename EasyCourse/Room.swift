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
    //BASIC
    //true if it is one to one message
    dynamic var isToUser = false
    dynamic var isJoinIn = false
    
    //store room ID or other user ID
    dynamic var id:String? = nil
    dynamic var roomname:String? = nil
    let messageList = List<Message>()
    dynamic var unread = 0
    dynamic var silent = false
    
    //GROUP CHATTING
    dynamic var courseID:String? = nil
    dynamic var courseName:String? = nil
    dynamic var university:String? = nil
    let memberList = List<User>()
    let memberCounts = RealmOptional<Int>()
    let language = RealmOptional<Int>()
    
    //user built room
    dynamic var founderID:String? = nil
    dynamic var isPublic = false
    
    //SYSTEM
    let isSystem = RealmOptional<Bool>()
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
//    func getMessage() -> Results<(Message)> {
//        return try! Realm().objects(Message.self).filter("roomId = '\(self.id!)'").sorted(byProperty: "createdAt", ascending: true)
//    }
//    
    func getMessageContainsImage() -> Results<(Message)> {
        return try! Realm().objects(Message.self).filter("toRoom = '\(self.id!)' AND imageUrl != nil").sorted(byProperty: "createdAt", ascending: true)
    }
    
    func initRoomWithData(_ data:NSDictionary, isToUser: Bool) -> Room? {
        if let id = data["_id"] as? String {
            self.id = id
            self.roomname = data["name"] as? String
            self.memberCounts.value = data["memberCounts"] as? Int
            self.courseID = data["course"] as? String
            self.courseName = data["courseName"] as? String
            self.university = data["university"] as? String
            self.founderID = data["founder"] as? String
            self.isSystem.value = data["isSystem"] as? Bool
            self.language.value = data["language"] as? Int
            self.isPublic = data["isPublic"] as? Bool ?? false
            self.isToUser = isToUser
            self.isJoinIn = true
            return self
        } else {
            return nil
        }
    }
    
    internal class func createOrUpdateRoomWithData(data:NSDictionary, isToUser: Bool) -> Room? {
        if let id = data["_id"] as? String {
            let realm = try! Realm()
            var room = realm.object(ofType: Room.self, forPrimaryKey: id)
            if room == nil {
                room = Room()
                room!.id = id
                try! realm.write {
                    realm.add(room!, update: true)
                }
            }
            try! realm.write {
                if let name = data["name"] as? String {
                    room!.roomname = name
                }
                if let memberCounts = data["memberCounts"] as? Int {
                    room!.memberCounts.value = memberCounts
                }
                if let course = data["course"] as? String {
                    room!.courseID = course
                }
                if let courseName = data["courseName"] as? String {
                    room!.courseName = courseName
                }
                if let university = data["university"] as? String {
                    room!.university = university
                }
                if let founder = data["founder"] as? String {
                    room!.founderID = founder
                }
                if let isSystem = data["isSystem"] as? Bool {
                    room!.isSystem.value = isSystem
                }
                if let language = data["language"] as? Int {
                    room!.language.value = language
                }
                if let isPublic = data["isPublic"] as? Bool {
                    room!.isPublic = isPublic
                }
                room!.isToUser = isToUser
                room!.isJoinIn = true
            }
            return room
        } else {
            return nil
        }
    }

    
//    func initContactsWithData(_ data: NSDictionary) -> Room? {
//        if let id = data["_id"] as? String {
//            self.id = id
//            self.isGroupChat = false
//            return self
//        } else {
//            return nil
//        }
//    }
    
//    internal class func initRoomAndSave(_ data:NSDictionary) {
//        let room = Room()
//        if let id = data["_id"] as? String {
//            room.id = id
//            room.roomname = data["name"] as? String
//            room.memberCounts.value = data["memberCounts"] as? Int
//            room.courseID = data["course"] as? String
//            room.courseName = data["courseName"] as? String
//            room.university = data["university"] as? String
//            room.founderID = data["founder"] as? String
//            room.isSystem.value = data["isSystem"] as? Bool
//            room.language.value = data["language"] as? Int
//            
//            let realm = try! Realm()
//            try! realm.write {
//                realm.add(room, update: true)
//            }
//        }
//    }
    
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
                print("leave room \(room.roomname)")

                NotificationCenter.default.post(name: Constant.NotificationKey.RoomDelete, object: room.id)
//                realm.delete(room)
                room.isJoinIn = false
            }
            for room in rooms where localRoomsIDArray.index(of: room.id!) == nil {
                print("add room \(room.roomname)")
                room.isJoinIn = true
                realm.add(room, update: true)
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
    
    func saveToDatabase() {
        let realm = try! Realm()
        try! realm.write({
            realm.add(self, update: true)
        })
    }

    
}
