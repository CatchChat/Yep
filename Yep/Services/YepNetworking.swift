//
//  YepNetworking.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

public enum Method: String, CustomStringConvertible {
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

public struct Resource<A>: CustomStringConvertible {
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

public enum Reason: CustomStringConvertible {
    case CouldNotParseJSON
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case Other(NSError?)

    public var description: String {
        switch self {
        case .CouldNotParseJSON:
            return "CouldNotParseJSON"
        case .NoData:
            return "NoData"
        case .NoSuccessStatusCode(let statusCode):
            return "NoSuccessStatusCode: \(statusCode)"
        case .Other(let error):
            return "Other, Error: \(error?.description)"
        }
    }
}

public typealias FailureHandler = (reason: Reason, errorMessage: String?) -> Void

let defaultFailureHandler: FailureHandler = { reason, errorMessage in
    println("\n***************************** YepNetworking Failure *****************************")
    println("Reason: \(reason)")
    if let errorMessage = errorMessage {
        println("errorMessage: >>>\(errorMessage)<<<\n")
    }
}

func queryComponents(key: String, value: AnyObject) -> [(String, String)] {
    func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }

    var components: [(String, String)] = []
    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += queryComponents("\(key)[\(nestedKey)]", value: value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents("\(key)[]", value: value)
        }
    } else {
        components.appendContentsOf([(escape(key), escape("\(value)"))])
    }

    return components
}

var yepNetworkActivityCount = 0 {
    didSet {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = (yepNetworkActivityCount > 0)
    }
}

private let yepSuccessStatusCodeRange = Range<Int>(start: 200, end: 300)

#if STAGING
class SessionDelegate: NSObject, NSURLSessionDelegate {

    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        completionHandler(.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
    }
}

let _sessionDelegate = SessionDelegate()
#endif

public func apiRequest<A>(modifyRequest: NSMutableURLRequest -> (), baseURL: NSURL, resource: Resource<A>?, failure: FailureHandler?, completion: A -> Void) {

    guard let resource = resource else {
        failure?(reason: .Other(nil), errorMessage: "No resource")
        return
    }

#if STAGING
    let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    let session = NSURLSession(configuration: sessionConfig, delegate: _sessionDelegate, delegateQueue: nil)
#else
    let session = NSURLSession.sharedSession()
#endif

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
        for key in Array(parameters.keys).sort(<) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key, value: value)
        }

        return (components.map{"\($0)=\($1)"} as [String]).joinWithSeparator("&")
    }

    func handleParameters() {
        if needEncodesParametersForMethod(resource.method) {
            guard let URL = request.URL else {
                println("Invalid URL of request: \(request)")
                return
            }

            if let requestBody = resource.requestBody {
                if let URLComponents = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) {
                    URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(decodeJSON(requestBody)!)
                    request.URL = URLComponents.URL
                }
            }

        } else {
            request.HTTPBody = resource.requestBody
        }
    }

    handleParameters()

    modifyRequest(request)

    for (key, value) in resource.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    #if DEBUG
    //println(request.cURLCommandLineWithSession(session))
    #endif

    let _failure: FailureHandler

    if let failure = failure {
        _failure = failure
    } else {
        _failure = defaultFailureHandler
    }

    let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in

        if let httpResponse = response as? NSHTTPURLResponse {

            if yepSuccessStatusCodeRange.contains(httpResponse.statusCode) {

                if let responseData = data {

                    if let result = resource.parse(responseData) {
                        completion(result)

                    } else {
                        let dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
                        println(dataString)
                        
                        _failure(reason: .CouldNotParseJSON, errorMessage: errorMessageInData(data))
                        println("\(resource)\n")
                        println(request.cURLCommandLine)
                    }

                } else {
                    _failure(reason: .NoData, errorMessage: errorMessageInData(data))
                    println("\(resource)\n")
                    println(request.cURLCommandLine)
                }

            } else {
                _failure(reason: .NoSuccessStatusCode(statusCode: httpResponse.statusCode), errorMessage: errorMessageInData(data))
                println("\(resource)\n")
                println(request.cURLCommandLine)

                // 对于 401: errorMessage: >>>HTTP Token: Access denied<<<
                // 用户需要重新登录，所以

                if httpResponse.statusCode == 401 {

                    // 确保是自家服务
                    if let requestHost = request.URL?.host where requestHost == yepBaseURL.host {
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.maybeUserNeedRelogin()
                        }
                    }
                }
            }

        } else {
            _failure(reason: .Other(error), errorMessage: errorMessageInData(data))
            println("\(resource)")
            println(request.cURLCommandLine)
        }

        dispatch_async(dispatch_get_main_queue()) {
            yepNetworkActivityCount--
        }
    }

    task.resume()

    dispatch_async(dispatch_get_main_queue()) {
        yepNetworkActivityCount++
    }
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

    if data.length > 0 {
        guard let result = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) else {
            return JSONDictionary()
        }
        
        if let dictionary = result as? JSONDictionary {
            return dictionary
        } else if let array = result as? [JSONDictionary] {
            return ["data": array]
        } else {
            return JSONDictionary()
        }

    } else {
        return JSONDictionary()
    }
}

func encodeJSON(dict: JSONDictionary) -> NSData? {
    return dict.count > 0 ? (try? NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())) : nil
}

public func jsonResource<A>(path path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A> {
    return jsonResource(token: nil, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func authJsonResource<A>(path path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A>? {
    guard let token = YepUserDefaults.v1AccessToken.value else {
        println("No token for auth")
        return nil
    }
    return jsonResource(token: token, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func jsonResource<A>(token token: String?, path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A> {
    
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

    let locale = NSLocale.autoupdatingCurrentLocale()
    if let
        languageCode = locale.objectForKey(NSLocaleLanguageCode) as? String,
        countryCode = locale.objectForKey(NSLocaleCountryCode) as? String {
            headers["Accept-Language"] = languageCode + "-" + countryCode
    }

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

