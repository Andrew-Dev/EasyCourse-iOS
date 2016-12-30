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
    case LocalError(reason: String)
    
    var description: String {
        switch self {
        case .NoResponse:
            return "No response from server"
        case .ServerError(let reason):
            return reason ?? "Server error"
        case .ParseJSONError:
            return "Server error"
        case .LocalError(let reason):
            return reason 
        default:
            return "Network error"
        }
    }
}
