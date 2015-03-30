//
//  YepNetworking.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import MobileCoreServices.UTType

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

// MARK: Upload

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// :param: string       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

/// Create body of the multipart/form-data request
///
/// :param: parameters   The optional dictionary containing keys and values to be passed to web service
/// :param: filePathKey  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
/// :param: paths        The optional array of file paths of the files to be uploaded
/// :param: boundary     The multipart/form-data boundary
///
/// :returns:            The NSData of the body of the request

func createBodyWithParameters(parameters: [String: String]?, #filePathKey: String?, #paths: [String]?, #boundary: String) -> NSData {
    let body = NSMutableData()
    
    if parameters != nil {
        for (key, value) in parameters! {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
    }
    
    if paths != nil {
        for path in paths! {
            let filename = path.lastPathComponent
            let data = NSData(contentsOfFile: path)
            let mimetype = mimeTypeForPath(path)
            
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
            body.appendString("Content-Type: \(mimetype)\r\n\r\n")
            body.appendData(data!)
            body.appendString("\r\n")
        }
    }
    
    body.appendString("--\(boundary)--\r\n")
    return body
}

/// Create boundary string for multipart/form-data request
///
/// :returns:            The boundary string that consists of "Boundary-" followed by a UUID string.

func generateBoundaryString() -> String {
    return "Boundary-\(NSUUID().UUIDString)"
}

/// Determine mime type on the basis of extension of a file.
///
/// This requires MobileCoreServices framework.
///
/// :param: path         The path of the file for which we are going to determine the mime type.
///
/// :returns:            Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.

func mimeTypeForPath(path: String) -> String {
    let pathExtension = path.pathExtension
    
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
        if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
    }
    return "application/octet-stream";
}
