//
//  RealmTools.swift
//  EasyCourse
//
//  Created by ZengJintao on 9/12/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation
import RealmSwift

open class RealmTools {
    
    
    
    class func RealmMigration() {

        let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
            if oldSchemaVersion < 1 {
                migration.enumerateObjects(ofType: User.className()) { oldObject, newObject in
                    if oldSchemaVersion < 1 {
                                                print("success in block")
                        // combine name fields into a single field
                        //                        let firstName = oldObject!["firstName"] as! String
                        //                        let lastName = oldObject!["lastName"] as! String
                        //                        newObject?["fullName"] = "\(firstName) \(lastName)"
                    }
                }
            }
        }
        Realm.Configuration.defaultConfiguration.schemaVersion = 1
        Realm.Configuration.defaultConfiguration.migrationBlock = migrationBlock
        print("realm config: \(Realm.Configuration.defaultConfiguration)")
    }
    
    class func setDefaultRealmForUser(_ userid: String?) {
        let pathName = userid == nil ? "Default" : userid!
        var config = Realm.Configuration()
        
        // Use the default directory, but replace the filename with the username        
        config.fileURL = config.fileURL?.deletingLastPathComponent().appendingPathComponent("\(pathName).realm")
        
        // Set this as the configuration used for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        self.RealmMigration()
    }
}
