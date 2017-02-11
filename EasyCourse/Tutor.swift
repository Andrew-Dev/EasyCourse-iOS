//
//  Tutor.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/1/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import UIKit
import SwiftyJSON

class Tutor: NSObject {
    var id:String
    var price:Int?
    var grade:String?
    var gradeVerified:Bool = false
    var tutorDescription:String?
    var createdAt:Date?
    
    // Tutor user
    var tutorId:String
    var tutorName:String
    var tutorAvatarUrl:String?
    
    // Course
    var courseId:String
    var courseName:String
    var courseTitle:String
    
    // Subject
    var subject:String
    var university:String
    
    // Reviews
    var rating:Double?
    
//    init(id:String, tutorUser:User, course:Course, price:Int, grade:String?) {
//        self.id = id
//        self.tutorUser = tutorUser
//        self.course = course
//        self.price = price
//        self.grade = grade
//    }
    
    init?(data:NSDictionary) {
        let json = JSON(data)
        guard let id = json["_id"].string else {
            return nil
        }
        self.id = id
        
        // Tutor
        guard let tutorId = json["user"]["_id"].string else {
            return nil
        }
        guard let tutorName = json["user"]["displayName"].string else {
            return nil
        }
        self.tutorId = tutorId
        self.tutorName = tutorName
        if let tutorAvatarUrl = json["user"]["avatarUrl"].string {
            self.tutorAvatarUrl = tutorAvatarUrl
        }
        
        // Course
        guard let crsId = json["course"]["_id"].string else {
            return nil
        }
        guard let crsName = json["course"]["name"].string else {
            return nil
        }
        guard let crsTitle = json["course"]["title"].string else {
            return nil
        }
        guard let crsSubject = json["course"]["subject"].string else {
            return nil
        }
        guard let crsUniv = json["course"]["university"].string else {
            return nil
        }

        courseId = crsId
        courseName = crsName
        courseTitle = crsTitle
        subject = crsSubject
        university = crsUniv
        
        if let price = json["price"].int {
            self.price = price
        }
        if let rating = json["rating"].double {
            self.rating = rating
        }
        if let tutorDescription = json["description"].string {
            self.tutorDescription = tutorDescription
        }
        
        grade = json["grade"].string
        gradeVerified = json["gradeVerified"].bool ?? false
        
        
        

    }

}
