//
//  NetworkErrorType.swift
//  EasyCourse
//
//  Created by ZengJintao on 11/13/16.
//  Copyright © 2016 ZengJintao. All rights reserved.
//

import Foundation

enum NetworkError: Error, CustomStringConvertible {
    case NoResponse
    case ServerError(reason: String?)
    case ParseJSONError
    
    var description: String {
        switch self {
        case .NoResponse:
            return "No response from server"
        case .ServerError(let reason):
            if reason != nil {
                return "Server error. Reason: \(reason)"
            }
            fallthrough
        case .ParseJSONError:
            return "Server error"
        default:
            return "Network error"
        }
    }
}
