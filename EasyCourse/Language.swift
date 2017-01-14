//
//  Language.swift
//  EasyCourse
//
//  Created by ZengJintao on 1/3/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import Foundation
import RealmSwift

class Language: Object {
    dynamic var code:String? = nil
    dynamic var name:String? = nil
    dynamic var displayName:String? = nil


    override static func primaryKey() -> String? {
        return "code"
    }
    
    func initWith(code: String, name: String?, displayName: String?) -> Language {
        self.code = code
        self.name = name
        self.displayName = displayName
        return self
    }
    
    func saveToDatabase() {
        let realm = try! Realm()
        try! realm.write {
            realm.add(self, update: true)
        }
        
    }
    
    internal class func findOrCreate(code: String) -> Language {
        let realm = try! Realm()
        if let lang = realm.object(ofType: Language.self, forPrimaryKey: code) {
            return lang
        } else {
            let lang = Language().initWith(code: code, name: nil, displayName: nil)
            lang.saveToDatabase()
            return lang
        }
        
    }
}
