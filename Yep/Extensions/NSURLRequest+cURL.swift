//
//  NSURLRequest+cURL.swift
//  Yep
//
//  Created by nixzhu on 15/9/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

// ref https://github.com/dduan/cURLLook
// modify for Yep

public extension NSURLRequest {

    public var cURLCommandLine: String {
        get {
            return cURLCommandLineWithSession(nil)
        }
    }

    public func cURLCommandLineWithSession(session: NSURLSession?, credential: NSURLCredential? = nil) -> String {

        var components = ["\ncurl -i"]

        if let HTTPMethod = HTTPMethod where HTTPMethod != "GET" {
            components.append("-X \(HTTPMethod)")
        }

        components.append("\"\(URL!.absoluteString!)\"")

        if let credentialStorage = session?.configuration.URLCredentialStorage {

            let protectionSpace = NSURLProtectionSpace(
                host: URL!.host!,
                port: URL!.port?.integerValue ?? 0,
                `protocol`: URL!.scheme,
                realm: URL!.host!,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )

            if let credentials = credentialStorage.credentialsForProtectionSpace(protectionSpace)?.values {

                for credential in credentials {
                    components.append("-u \(credential.user!):\(credential.password!)")
                }

            } else {
                if credential != nil {
                    components.append("-u \(credential!.user!):\(credential!.password!)")
                }
            }
        }

        if session != nil && session!.configuration.HTTPShouldSetCookies {
            if let
                cookieStorage = session!.configuration.HTTPCookieStorage,
                cookies = cookieStorage.cookiesForURL(URL!) where !cookies.isEmpty {
                    let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value ?? String());" }
                    components.append("-b \"\(string.substringToIndex(string.endIndex.predecessor()))\"")
            }
        }

        if let headerFields = allHTTPHeaderFields as? [String: String] {

            for (field, value) in headerFields {
                switch field {
                case "Cookie":
                    continue
                default:
                    let escapedValue = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
                    components.append("-H \"\(field): \(escapedValue)\"")
                }
            }
        }

        if let additionalHeaders = session?.configuration.HTTPAdditionalHeaders as? [String: String] {

            for (field, value) in additionalHeaders {
                switch field {
                case "Cookie":
                    continue
                default:
                    let escapedValue = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
                    components.append("-H \"\(field): \(escapedValue)\"")
                }
            }
        }

        if let HTTPBody = HTTPBody, HTTPBodyString = NSString(data: HTTPBody, encoding: NSUTF8StringEncoding) {
            let escapedString = HTTPBodyString.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
            components.append("-d \"\(escapedString)\"")
        }

        return " ".join(components) + "\n"
    }
}

