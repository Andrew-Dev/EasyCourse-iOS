//
//  TutorStudent.swift
//  EasyCourse
//
//  Created by ZengJintao on 2/25/17.
//  Copyright © 2017 ZengJintao. All rights reserved.
//

import Foundation

enum TutorStudentStatus {
    case Pending, Endrolled, Reject
}

enum InvalidTutorStudentDataError: Error {
    case NoStatus
}

struct TutorStudent {
    let user: User
    var status: TutorStudentStatus
    
    init(_user:User, _status:String) throws {
        self.user = _user
        switch _status {
        case "Pending":
            status = .Pending
        case "Enrolled":
            status = .Endrolled
        case "Reject":
            status = .Reject
        default:
            throw InvalidTutorStudentDataError.NoStatus
        }
    }
}
