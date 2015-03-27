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

func defaultFailureHandler(reason: Reason, errorMessage: String?) {
    println("\n***************************** YepNetworking Failure *****************************")
    println("Reason: \(reason)")
    if let errorMessage = errorMessage {
        println("errorMessage: >>>\(errorMessage)<<<\n")
    } else {
        println()
    }
}

func queryComponents(key: String, value: AnyObject) -> [(String, String)] {
    func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as! String
    }

    var components: [(String, String)] = []
    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += queryComponents("\(key)[\(nestedKey)]", value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents("\(key)[]", value)
        }
    } else {
        components.extend([(escape(key), escape("\(value)"))])
    }

    return components
}

public func apiRequest<A>(modifyRequest: NSMutableURLRequest -> (), baseURL: NSURL, resource: Resource<A>, failure: (Reason, String?) -> (), completion: A -> Void) {
    let session = NSURLSession.sharedSession()
    let url = baseURL.URLByAppendingPathComponent(resource.path)
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = resource.method.rawValue


    func needEncodesParametersForMethod(method: Method) -> Bool {
        switch method {
        case .GET, .HEAD, .DELETE:
            return true
        default:
            return false
        }
    }

    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in sorted(Array(parameters.keys), <) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key, value)
        }

        return join("&", components.map{"\($0)=\($1)"} as [String])
    }

    if needEncodesParametersForMethod(resource.method) {
        if let requestBody = resource.requestBody {
            if let URLComponents = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false) {
                URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(decodeJSON(requestBody)!)
                request.URL = URLComponents.URL
            }
        }

    } else {
        request.HTTPBody = resource.requestBody
    }

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
                        println("\(resource)")
                        failure(Reason.CouldNotParseJSON, errorMessageInData(data))
                    }

                } else {
                    println("\(resource)")
                    failure(Reason.NoData, errorMessageInData(data))
                }

            } else {
                println("\(resource)")
                println("\nstatusCode: \(httpResponse.statusCode)")
                failure(Reason.NoSuccessStatusCode(statusCode: httpResponse.statusCode), errorMessageInData(data))

                // 对于 401: errorMessage: >>>HTTP Token: Access denied<<<
                // 用户需要重新登录，所以

                if httpResponse.statusCode == 401 {
                    dispatch_async(dispatch_get_main_queue()) {
                        YepUserDefaults.userNeedRelogin()
                    }
                }
            }

        } else {
            println("\(resource)")
            failure(Reason.Other(error), errorMessageInData(data))
        }
    }

    task.resume()
}

func errorMessageInData(data: NSData?) -> String? {
    if let data = data {
        if let json = decodeJSON(data) {
            if let errorMessage = json["error"] as? String {
                return errorMessage
            }
        }
    }

    return nil
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
    return jsonResource(token: nil, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func authJsonResource<A>(#path: String, #method: Method, #requestParameters: JSONDictionary, #parse: JSONDictionary -> A?) -> Resource<A> {
    let token = YepUserDefaults.v1AccessToken()
    return jsonResource(token: token, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func jsonResource<A>(#token: String?, #path: String, #method: Method, #requestParameters: JSONDictionary, #parse: JSONDictionary -> A?) -> Resource<A> {
    
    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    var headers = [
        "Content-Type": "application/json",
    ]
    if let token = token {
        headers["Authorization"] = "Token token=\"\(token)\""
    }

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}
