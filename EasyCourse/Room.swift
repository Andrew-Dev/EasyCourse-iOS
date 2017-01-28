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
    //When isToUser == true, the room is one to one message
    dynamic var isToUser = false
    
    //Basic info of the room
    dynamic var id:String? = nil
    dynamic var roomname:String? = nil
    let messageList = List<Message>()
    dynamic var unread = 0
    dynamic var silent = false
    
    //Group chatting
    dynamic var courseID:String? = nil
    dynamic var university:String? = nil
    let memberList = List<User>()
    let memberCounts = RealmOptional<Int>()
    dynamic var memberCountsDescription:String? = nil
    dynamic var language:String? = nil
    dynamic var avatarPictureUrl:String? = nil

    
    //User built room
    dynamic var founderID:String? = nil
    dynamic var isPublic = false
    
    //SYSTEM
    let isSystem = RealmOptional<Bool>()
    
    //Local
    dynamic var lastUpdateTime: NSDate? = nil
    dynamic var removed = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getMessage() -> Results<(Message)> {
        if self.isToUser {
            return try! Realm().objects(Message.self).filter("(senderId = '\(self.id!)' OR toRoom = '\(self.id!)') AND isToUser = true").sorted(byProperty: "createdAt", ascending: true)
        } else {
            return try! Realm().objects(Message.self).filter("toRoom = '\(self.id!)' AND isToUser = false").sorted(byProperty: "createdAt", ascending: true)
        }
    }

    func getMessageContainsImage() -> Results<(Message)> {
//        return try! Realm().objects(Message.self).filter("toRoom = '\(self.id!)' AND imageUrl != nil").sorted(byProperty: "createdAt", ascending: true)
        if self.isToUser {
            return try! Realm().objects(Message.self).filter("(senderId = '\(self.id!)' OR toRoom = '\(self.id!)') AND isToUser = true AND (imageUrl != nil OR imageData != nil)").sorted(byProperty: "createdAt", ascending: true)
        } else {
            return try! Realm().objects(Message.self).filter("toRoom = '\(self.id!)' AND isToUser = false AND (imageUrl != nil OR imageData != nil)").sorted(byProperty: "createdAt", ascending: true)
        }
    }
    
    func initRoomWithData(_ data:NSDictionary, isToUser: Bool) -> Room? {
        if let id = data["_id"] as? String {
            self.id = id
            self.roomname = data["name"] as? String
            self.avatarPictureUrl = data["avatarPictureUrl"] as? String
            self.memberCounts.value = data["memberCounts"] as? Int
            self.courseID = data["course"] as? String
            self.university = data["university"] as? String
            self.founderID = data["founder"] as? String
            self.isSystem.value = data["isSystem"] as? Bool
            self.language = data["language"] as? String
            self.isPublic = data["isPublic"] as? Bool ?? false
            self.isToUser = isToUser
            return self
        } else {
            return nil
        }
    }
    
    internal class func createOrUpdateRoomWithData(data:NSDictionary, isToUser: Bool) -> Room? {
        if let id = data["_id"] as? String {
//            print("room data: \(data)")
            let realm = try! Realm()
            var room = realm.object(ofType: Room.self, forPrimaryKey: id)
            if room == nil {
                room = Room()
                room!.id = id
                room!.isToUser = isToUser
                try! realm.write {
                    realm.add(room!, update: true)
                }
            }
            if isToUser {
                _ = User.createOrUpdateUserWithData(data)
            } else {
                try! realm.write {
                    if let name = data["name"] as? String {
                        room!.roomname = name
                    }
                    if let avatarUrl = data["avatarUrl"] as? String {
                        room!.avatarPictureUrl = avatarUrl
                    }
                    if let memberCounts = data["memberCounts"] as? Int {
                        room!.memberCounts.value = memberCounts
                    }
                    if let memberCountsDescription = data["memberCountsDescription"] as? String {
                        room!.memberCountsDescription = memberCountsDescription
                    }
                    if let course = data["course"] as? String {
                        room!.courseID = course
                    }
                    if let university = data["university"] as? String {
                        room!.university = university
                    }
                    if let founder = data["founder"] as? String {
                        room!.founderID = founder
                    } else if let founderData = data["founder"] as? NSDictionary,
                        let founderId = founderData["_id"] as? String {
                        room!.founderID = founderId
                        
                    }
                    if let isSystem = data["isSystem"] as? Bool {
                        room!.isSystem.value = isSystem
                    }
                    if let language = data["language"] as? String {
                        room!.language = language
                    }
                    if let isPublic = data["isPublic"] as? Bool {
                        room!.isPublic = isPublic
                    }
                    room!.isToUser = isToUser
                }
                if let founderData = data["founder"] as? NSDictionary {
                    _ = User.createOrUpdateUserWithData(founderData)
                }
            }
            
            return room
        } else {
            return nil
        }
    }

    
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
            }
            for room in rooms where localRoomsIDArray.index(of: room.id!) == nil {
                print("add room \(room.roomname)")
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
    
//    func saveToDatabase() {
//        print("room: \(self)")
//        let realm = try! Realm()
//        try! realm.write({
//            realm.add(self, update: true)
//        })
//    }
    

    
}
