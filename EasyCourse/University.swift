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
