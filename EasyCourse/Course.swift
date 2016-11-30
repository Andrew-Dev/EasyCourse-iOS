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
    dynamic var universityId:String? = nil
    
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
    
    //New
    internal class func createOrUpdateCourse(_ data:NSDictionary) -> Course? {
        
        let realm = try! Realm()
        guard let id = data["_id"] as? String else {
            return nil
        }
        
        if let existedCourse = realm.object(ofType: Course.self, forPrimaryKey: id) {
            existedCourse.mapCourseWithData(data)
            return existedCourse
        } else {
            let course = Course()
            course.mapCourseWithData(data)
            return course
        }

    }
    
    //Updating object property
    func mapCourseWithData(_ data:NSDictionary) {
        try! Realm().write {
            if let id = data["_id"] as? String, self.id == nil {
                self.id = id
            }
            if let coursename = data["name"] as? String {
                self.coursename = coursename
            }
            if let title = data["title"] as? String {
                self.title = title
            }
            if let courseDescription = data["description"] as? String {
                self.courseDescription = courseDescription
            }
            if let creditHours = data["creditHours"] as? Int {
                self.creditHours.value = creditHours
            }
            if let university = data["university"] as? String {
                self.universityId = university
            }
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
