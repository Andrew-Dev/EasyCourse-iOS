//
//  Course.swift
//  EasyCourse
//
//  Created by ZengJintao on 8/31/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import UIKit
import RealmSwift

class Course: Object {
    dynamic var id:String? = nil
    dynamic var coursename:String? = nil
    dynamic var coursePicture: Data? = nil
    dynamic var coursePictureUrl:String? = nil
    dynamic var title:String? = nil
    dynamic var courseDescription:String? = nil
    let creditHours = RealmOptional<Int>()
    dynamic var universityID:String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    internal class func initCourseAndSave(_ data:NSDictionary) {
        let course = Course()
        if let id = data["_id"] as? String {
            course.id = id
            course.coursename = data["name"] as? String
            course.courseDescription = data["description"] as? String
            course.title = data["title"] as? String
            let realm = try! Realm()
            try! realm.write {
                realm.add(course)
            }
        }
    }
    
    internal class func initCourse(_ data:NSDictionary) -> Course? {
        let course = Course()
        if let id = data["_id"] as? String {
            course.id = id
            course.coursename = data["name"] as? String
            course.courseDescription = data["description"] as? String
            course.title = data["title"] as? String
            return course
        } else {
            return nil
        }
    }
    
    internal class func removeAllCourse() {
        let realm = try! Realm()
        let allCourse = realm.objects(Course.self)
        try! realm.write {
            for course in allCourse {
                realm.delete(course)
            }
        }
    }
    
    internal class func syncCourse(_ courses:[Course]) {
        var syncCoursesIDArray = [String]()
        var localCoursesIDArray = [String]()
        
        let realm = try! Realm()
        let localCourse = realm.objects(Course.self)
        
        localCourse.forEach { (course) in
            localCoursesIDArray.append(course.id!)
        }
        
        courses.forEach { (room) in
            syncCoursesIDArray.append(room.id!)
        }
        
        print("local course: \(localCoursesIDArray)")
        print("get course: \(syncCoursesIDArray)")
        
        try! realm.write({
            for course in localCourse where syncCoursesIDArray.index(of: course.id!) == nil {
                print("delete course \(course.coursename)")
                realm.delete(course)
                
            }
            for course in courses where localCoursesIDArray.index(of: course.id!) == nil {
                print("add course \(course.coursename)")
                realm.add(course)
            }
        })
    }
    
    
}
