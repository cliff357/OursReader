//
//  ErrorHelper.swift
//  OursReader
//
//  Created by Cliff Chan on 25/5/2024.
//

import Foundation

extension Error {
    public var asAPIError: APIError {
        self as? APIError ?? .undefined(message: "")
    }
}

public enum APIError: Hashable, Error {
    case httpError(error: HttpError)
    case undefined(message: String)
    
    var errorMsg: String {
        switch self {
        case .httpError(let error):
            return error.errorMsg
        case .undefined(let message):
            return message
        }
    }
}

public enum HttpError {
    case timedOut
    case networkConnectionLost
    
    //TODO: localize
    var errorMsg: String {
        switch self {
        case .timedOut:
            return "Time out"
        case .networkConnectionLost:
            return "Network Connection Lost"
        }
    }
    
    static func getHttpError(code: Int) -> HttpError? {
        switch code {
        case NSURLErrorTimedOut:
            return .timedOut
        case NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorDataNotAllowed:
            return .networkConnectionLost
        default:
            return nil
        }
    }
}
