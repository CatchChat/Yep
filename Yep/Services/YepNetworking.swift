//
//  YepNetworking.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

public enum Method: String, Printable {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"

    public var description: String {
        return self.rawValue
    }
}

public struct Resource<A>: Printable {
    let path: String
    let method: Method
    let requestBody: NSData?
    let headers: [String:String]
    let parse: NSData -> A?

    public var description: String {
        let decodeRequestBody: [String: AnyObject]
        if let requestBody = requestBody {
            decodeRequestBody = decodeJSON(requestBody)!
        } else {
            decodeRequestBody = [:]
        }

        return "Resource(Method: \(method), path: \(path), headers: \(headers), requestBody: \(decodeRequestBody))"
    }
}

public enum Reason: Printable {
    case CouldNotParseJSON
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case Other(NSError)

    public var description: String {
        switch self {
        case .CouldNotParseJSON:
            return "CouldNotParseJSON"
        case .NoData:
            return "NoData"
        case .NoSuccessStatusCode:
            return "NoSuccessStatusCode"
        case .Other:
            return "Other"
        default:
            return ""
        }
    }
}

func defaultFailureHandler<A>(forResource resource:Resource<A>, withFailureReason reason: Reason, data: NSData?) {
    println("\n***************************** YepNetworking Failure *****************************")
    println("Request: \(resource)")
    println("Reason: \(reason)")
    if let string = NSString(data: data!, encoding: NSUTF8StringEncoding) {
        println("Data: \(string)")
    }
    println("\n")
}

public func apiRequest<A>(modifyRequest: NSMutableURLRequest -> (), baseURL: NSURL, resource: Resource<A>, failure: (Resource<A>, Reason, NSData?) -> (), completion: A -> ()) {
    let session = NSURLSession.sharedSession()
    let url = baseURL.URLByAppendingPathComponent(resource.path)
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = resource.method.rawValue
    request.HTTPBody = resource.requestBody

    modifyRequest(request)

    for (key, value) in resource.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                if let responseData = data {
                    if let result = resource.parse(responseData) {
                        completion(result)
                    } else {
                        failure(resource, Reason.CouldNotParseJSON, data)
                    }
                } else {
                    failure(resource, Reason.NoData, data)
                }
            } else {
                println("\nstatusCode: \(httpResponse.statusCode)")
                failure(resource, Reason.NoSuccessStatusCode(statusCode: httpResponse.statusCode), data)
            }
        } else {
            failure(resource, Reason.Other(error), data)
        }
    }

    task.resume()
}

// Here are some convenience functions for dealing with JSON APIs

public typealias JSONDictionary = [String: AnyObject]

func decodeJSON(data: NSData) -> JSONDictionary? {
    return NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? [String:AnyObject]
}

func encodeJSON(dict: JSONDictionary) -> NSData? {
    return dict.count > 0 ? NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.allZeros, error: nil) : nil
}

public func jsonResource<A>(#path: String, #method: Method, #requestParameters: JSONDictionary, #parse: JSONDictionary -> A?) -> Resource<A> {

    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    let headers = ["Content-Type": "application/json"]

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

public func authJsonResource<A>(#token: String, #path: String, #method: Method, #requestParameters: JSONDictionary, #parse: JSONDictionary -> A?) -> Resource<A> {
    
    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    let headers = [
        "Content-Type": "application/json",
        "Authorization": "Token token=\"\(token)\""
    ]

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

