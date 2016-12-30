//
//  University.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/4/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import RealmSwift

class University: Object {
    dynamic var id:String? = nil
    dynamic var name:String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    internal class func createOrUpdateUniversity(_ data:NSDictionary) -> University? {
        let realm = try! Realm()
        guard let id = data["_id"] as? String else {
            return nil
        }
        
        if let existedUniv = realm.object(ofType: University.self, forPrimaryKey: id) {
            existedUniv.mapUnivWithData(data)
            return existedUniv
        } else {
            let univ = University()
            univ.mapUnivWithData(data)
            return univ
        }
    }
    
    func mapUnivWithData(_ data:NSDictionary) {
        print("univmapdata: \(data)")
        let realm = try! Realm()
        try! realm.write {
            if let id = data["_id"] as? String, self.id == nil {
                self.id = id
            }
            if let univName = data["name"] as? String {
                self.name = univName
            }
            realm.add(self, update: true)
        }

    }
    
    internal class func initUniv(_ data:NSDictionary) {
        let univ = University()
        if let id = data["_id"] as? String {
            univ.id = id
            univ.name = data["name"] as? String
            let realm = try! Realm()
            try! realm.write {
                realm.add(univ, update: true)
            }
        }
    }
    
    internal class func removeAllUniv() {
        let realm = try! Realm()
        let allUniv = realm.objects(University.self)
        try! realm.write {
            for course in allUniv {
                realm.delete(course)
            }
        }
    }
    
    internal class func getAllUnivArr() -> [University] {
        let realm = try! Realm()
        let allUniv = realm.objects(University.self)
        var univArray:[University] = []
        for univ in allUniv {
            univArray.append(univ)
        }
        return univArray
    }
}
