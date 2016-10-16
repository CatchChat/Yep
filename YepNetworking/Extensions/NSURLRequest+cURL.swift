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

extension URLRequest {

    var cURLCommandLine: String {
        get {
            return cURLCommandLineWithSession(nil)
        }
    }

    func cURLCommandLineWithSession(_ session: URLSession?, credential: URLCredential? = nil) -> String {

        var components = ["\ncurl -i"]

        if let HTTPMethod = httpMethod, HTTPMethod != "GET" {
            components.append("-X \(HTTPMethod)")
        }

        if let URLString = url?.absoluteString {
            components.append("\"\(URLString)\"")
        }

        if let credentialStorage = session?.configuration.urlCredentialStorage {

            if let host = url?.host, let scheme = url?.scheme {
                let port = (url as NSURL?)?.port?.intValue ?? 0

                let protectionSpace = URLProtectionSpace(
                    host: host,
                    port: port,
                    protocol: scheme,
                    realm: host,
                    authenticationMethod: NSURLAuthenticationMethodHTTPBasic
                )

                if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {

                    for credential in credentials {
                        if let user = credential.user, let password = credential.password {
                            components.append("-u \(user):\(password)")
                        }
                    }

                } else {
                    if let user = credential?.user, let password = credential?.password {
                        components.append("-u \(user):\(password)")
                    }
                }
            }
        }

        if let session = session, let URL = url {
            if session.configuration.httpShouldSetCookies {
                if let
                    cookieStorage = session.configuration.httpCookieStorage,
                    let cookies = cookieStorage.cookies(for: URL), !cookies.isEmpty {
                        let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
                        components.append("-b \"\(string.substring(to: string.characters.index(before: string.endIndex)))\"")
                }
            }
        }

        if let headerFields = allHTTPHeaderFields {

            for (field, value) in headerFields {
                switch field {
                case "Cookie":
                    continue
                default:
                    let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
                    components.append("-H \"\(field): \(escapedValue)\"")
                }
            }
        }

        if let additionalHeaders = session?.configuration.httpAdditionalHeaders as? [String: String] {

            for (field, value) in additionalHeaders {
                switch field {
                case "Cookie":
                    continue
                default:
                    let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
                    components.append("-H \"\(field): \(escapedValue)\"")
                }
            }
        }

        if let HTTPBody = httpBody, let HTTPBodyString = String(data: HTTPBody, encoding: .utf8) {
            let escapedString = HTTPBodyString.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escapedString)\"")
        }

        return components.joined(separator: " ") + "\n"
    }
}

