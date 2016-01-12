//
//  OpenGraphService.swift
//  Yep
//
//  Created by nixzhu on 16/1/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Alamofire
import Kanna

struct OpenGraph {

    var siteName: String?

    var title: String?
    var description: String?

    var imageURLString: String?
    var videoURLString: String?

    init() {
    }

    static func fromHTMLString(HTMLString: String) -> OpenGraph? {

        if let doc = Kanna.HTML(html: HTMLString, encoding: NSUTF8StringEncoding) {

            var openGraph = OpenGraph()

            if let metaSet = doc.head?.css("meta") {

                var openGraphInfo = [String: String]()

                for meta in metaSet {
                    if let property = meta["property"]?.lowercaseString {
                        if property.hasPrefix("og:") {
                            if let content = meta["content"] {
                                openGraphInfo[property] = content
                            }
                        }
                    }
                }

                openGraph.siteName = openGraphInfo["og:site_name"]
                openGraph.title = openGraphInfo["og:title"]
                openGraph.description = openGraphInfo["og:description"]
                openGraph.imageURLString = openGraphInfo["og:image"]
            }

            return openGraph
        }

        return nil
    }
}

func openGraphWithURLString(URLString: String, failureHandler: ((Reason, String?) -> Void)?, completion: OpenGraph -> Void) {

    Alamofire.request(.GET, URLString, parameters: nil, encoding: .URL).responseString { response in

        let error = response.result.error

        guard error == nil else {

            if let failureHandler = failureHandler {
                failureHandler(.Other(error), nil)
            } else {
                defaultFailureHandler(.Other(error), errorMessage: nil)
            }

            return
        }

        if let HTMLString = response.result.value {
            println("\n openGraphWithURLString: \(URLString)\n\(HTMLString)")

            if let openGraph = OpenGraph.fromHTMLString(HTMLString) {
                completion(openGraph)

                return
            }
        }

        if let failureHandler = failureHandler {
            failureHandler(.CouldNotParseJSON, nil)
        } else {
            defaultFailureHandler(.CouldNotParseJSON, errorMessage: nil)
        }
    }
}

