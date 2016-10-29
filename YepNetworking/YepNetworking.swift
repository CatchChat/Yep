//
//  YepNetworking.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

public enum Method: String, CustomStringConvertible {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    public var description: String {
        return self.rawValue
    }
}

public struct Resource<A>: CustomStringConvertible {
    let path: String
    let method: Method
    let requestBody: Data?
    let headers: [String: String]
    let parse: (Data) -> A?

    public var description: String {
        let decodeRequestBody: JSONDictionary
        if let requestBody = requestBody {
            decodeRequestBody = decodeJSON(requestBody) ?? [:]
        } else {
            decodeRequestBody = [:]
        }

        return "Resource(Method: \(method), path: \(path), headers: \(headers), requestBody: \(decodeRequestBody))"
    }

    public init(path: String, method: Method, requestBody: Data?, headers: [String: String], parse: @escaping (Data) -> A?) {
        self.path = path
        self.method = method
        self.requestBody = requestBody
        self.headers = headers
        self.parse = parse
    }
}

public enum ErrorCode: String {
    case blockedByRecipient = "rejected_your_message"
    case notYetRegistered = "not_yet_registered"
    case userWasBlocked = "user_was_blocked"
}

public enum Reason: CustomStringConvertible {
    case couldNotParseJSON
    case noData
    case noSuccessStatusCode(statusCode: Int, errorCode: ErrorCode?)
    case other(Error?)

    public var description: String {
        switch self {
        case .couldNotParseJSON:
            return "CouldNotParseJSON"
        case .noData:
            return "NoData"
        case .noSuccessStatusCode(let statusCode):
            return "NoSuccessStatusCode: \(statusCode)"
        case .other(let error):
            return "Other, Error: \(error)"
        }
    }
}

public typealias FailureHandler = (_ reason: Reason, _ errorMessage: String?) -> Void

public let defaultFailureHandler: FailureHandler = { (reason, errorMessage) in
    print("\n***************************** YepNetworking Failure *****************************")
    print("Reason: \(reason)")
    if let errorMessage = errorMessage {
        print("errorMessage: >>>\(errorMessage)<<<\n")
    }
}

func queryComponents(_ key: String, value: Any) -> [(String, String)] {

    func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? string
    }

    var components: [(String, String)] = []
    if let dictionary = value as? JSONDictionary {
        for (nestedKey, value) in dictionary {
            components += queryComponents("\(key)[\(nestedKey)]", value: value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents("\(key)[]", value: value)
        }
    } else {
        components.append(contentsOf: [(escape(key), escape("\(value)"))])
    }

    return components
}

var yepNetworkActivityCount = 0 {
    didSet {
        Manager.networkActivityCountChangedAction?(yepNetworkActivityCount)
    }
}

private let yepSuccessStatusCodeRange: CountableRange<Int> = 200..<300

public func apiRequest<A>(_ modifyRequest: (URLRequest) -> (), baseURL: URL, resource: Resource<A>?, failure: FailureHandler?, completion: @escaping (A) -> Void) {

    let failure: FailureHandler = { (reason, errorMessage) in
        defaultFailureHandler(reason, errorMessage)
        failure?(reason, errorMessage)
    }

    guard let resource = resource else {
        failure(.other(nil), "No resource")
        return
    }

    let session = URLSession.shared

    let url = baseURL.appendingPathComponent(resource.path)
    var request = URLRequest(url: url)
    request.httpMethod = resource.method.rawValue

    func needEncodesParametersForMethod(_ method: Method) -> Bool {
        switch method {
        case .get, .head, .delete:
            return true
        default:
            return false
        }
    }

    func query(_ parameters: JSONDictionary) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sorted(by: <) {
            if let value = parameters[key] {
                components += queryComponents(key, value: value)
            }
        }

        return (components.map{"\($0)=\($1)"} as [String]).joined(separator: "&")
    }

    func handleParameters() {
        if needEncodesParametersForMethod(resource.method) {
            guard let URL = request.url else {
                print("Invalid URL of request: \(request)")
                return
            }

            if let requestBody = resource.requestBody {
                if var URLComponents = URLComponents(url: URL, resolvingAgainstBaseURL: false) {
                    URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(decodeJSON(requestBody) ?? [:])
                    request.url = URLComponents.url
                }
            }

        } else {
            request.httpBody = resource.requestBody
        }
    }

    handleParameters()

    modifyRequest(request)

    for (key, value) in resource.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    #if DEBUG
    print(request.cURLCommandLineWithSession(session))
    #endif

    let task = session.dataTask(with: request, completionHandler: { (data, response, error) in

        if let httpResponse = response as? HTTPURLResponse {

            if yepSuccessStatusCodeRange.contains(httpResponse.statusCode) {

                if let responseData = data {

                    if let result = resource.parse(responseData) {
                        completion(result)

                    } else {
                        if let dataString = String(data: responseData, encoding: .utf8) {
                            print(dataString)
                        }
                        failure(.couldNotParseJSON, errorMessageInData(data))
                        print("\(resource)\n")
                        print(request.cURLCommandLine)
                    }

                } else {
                    failure(.noData, errorMessageInData(data))
                    print("\(resource)\n")
                    print(request.cURLCommandLine)
                }

            } else {
                let errorCode = errorCodeInData(data)
                failure(.noSuccessStatusCode(statusCode: httpResponse.statusCode, errorCode: errorCode), errorMessageInData(data))
                print("\(resource)\n")
                print(request.cURLCommandLine)

                // 对于 401: errorMessage: >>>HTTP Token: Access denied<<<
                // 用户需要重新登录，所以

                if let host = request.url?.host {
                    Manager.authFailedAction?(httpResponse.statusCode, host)
                }
            }

        } else {
            failure(.other(error), errorMessageInData(data))
            print("\(resource)")
            print(request.cURLCommandLine)
        }

        DispatchQueue.main.async {
            yepNetworkActivityCount -= 1
        }
    }) 

    task.resume()

    DispatchQueue.main.async {
        yepNetworkActivityCount += 1
    }
}

func errorMessageInData(_ data: Data?) -> String? {
    if let data = data {
        if let json = decodeJSON(data) {
            if let errorMessage = json["error"] as? String {
                return errorMessage
            }
        }
    }

    return nil
}

func errorCodeInData(_ data: Data?) -> ErrorCode? {
    if let data = data {
        if let json = decodeJSON(data) {
            print("error json: \(json)")
            if let errorCodeString = json["code"] as? String {
                return ErrorCode(rawValue: errorCodeString)
            }
        }
    }

    return nil
}

// Here are some convenience functions for dealing with JSON APIs

public typealias JSONDictionary = [String: Any]

public func decodeJSON(_ data: Data) -> JSONDictionary? {

    guard data.count > 0 else {
        return [:] // 允许不返回数据，只有状态码
    }

    guard let result = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) else {
        return nil
    }
    
    if let dictionary = result as? JSONDictionary {
        return dictionary
    } else if let array = result as? [JSONDictionary] {
        return ["data": array]
    } else {
        return nil
    }
}

public func encodeJSON(_ dict: JSONDictionary) -> Data? {
    return dict.count > 0 ? (try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())) : nil
}

public func jsonResource<A>(path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (JSONDictionary) -> A?) -> Resource<A> {
    return jsonResource(token: nil, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func authJsonResource<A>(path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (JSONDictionary) -> A?) -> Resource<A>? {

    guard let token = Manager.accessToken?() else {
        print("No token for auth")
        return nil
    }

    return jsonResource(token: token, path: path, method: method, requestParameters: requestParameters, parse: parse)
}

public func jsonResource<A>(token: String?, path: String, method: Method, requestParameters: JSONDictionary, parse: @escaping (JSONDictionary) -> A?) -> Resource<A> {
    
    let jsonParse: (Data) -> A? = { data in
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

    let locale = Locale.autoupdatingCurrent
    if let
        languageCode = (locale as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String,
        let countryCode = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
            headers["Accept-Language"] = languageCode + "-" + countryCode
    }

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

