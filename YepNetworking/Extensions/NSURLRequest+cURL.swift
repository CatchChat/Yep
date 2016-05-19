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

extension NSURLRequest {

    var cURLCommandLine: String {
        get {
            return cURLCommandLineWithSession(nil)
        }
    }

    func cURLCommandLineWithSession(session: NSURLSession?, credential: NSURLCredential? = nil) -> String {

        var components = ["\ncurl -i"]

        if let HTTPMethod = HTTPMethod where HTTPMethod != "GET" {
            components.append("-X \(HTTPMethod)")
        }

        if let URLString = URL?.absoluteString {
            components.append("\"\(URLString)\"")
        }

        if let credentialStorage = session?.configuration.URLCredentialStorage {

            if let host = URL?.host, scheme = URL?.scheme {
                let port = URL?.port?.integerValue ?? 0

                let protectionSpace = NSURLProtectionSpace(
                    host: host,
                    port: port,
                    protocol: scheme,
                    realm: host,
                    authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                )

                if let credentials = credentialStorage.credentialsForProtectionSpace(protectionSpace)?.values {

                    for credential in credentials {
                        if let user = credential.user, password = credential.password {
                            components.append("-u \(user):\(password)")
                        }
                    }

                } else {
                    if let user = credential?.user, password = credential?.password {
                        components.append("-u \(user):\(password)")
                    }
                }
            }
        }

        if let session = session, URL = URL {
            if session.configuration.HTTPShouldSetCookies {
                if let
                    cookieStorage = session.configuration.HTTPCookieStorage,
                    cookies = cookieStorage.cookiesForURL(URL) where !cookies.isEmpty {
                        let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value ?? String());" }
                        components.append("-b \"\(string.substringToIndex(string.endIndex.predecessor()))\"")
                }
            }
        }

        if let headerFields = allHTTPHeaderFields {

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

        return components.joinWithSeparator(" ") + "\n"
    }
}

