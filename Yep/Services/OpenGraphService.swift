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

    enum Kind {
        case Default
        case AppleMusic
        case AppleMovie
        case AppleEBook
    }

    var kind: Kind = .Default

    var siteName: String?

    var title: String?
    var description: String?

    var previewImageURLString: String?
    var previewVideoURLString: String?
    var previewAudioURLString: String?

    struct AppleMusic {
        var artistName: String?

        var artworkURLString30: String?
        var artworkURLString60: String?
        var artworkURLString100: String?
        var artworkURLString160: String?

        var collectionType: String?
        var collectionName: String?
        var collectionViewURLString: String?

        var trackTimeMillis: Int?
    }
    var appleMusic: AppleMusic?

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

                openGraph.previewImageURLString = openGraphInfo["og:image"]
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

                var openGraph = openGraph

                if let URL = response.response?.URL, host = URL.host {

                    switch host {

                    case "itunes.apple.com":

                        if let lookupID = URL.yep_iTunesArtworkID {
                            iTunesLookupWithID(lookupID, failureHandler: nil, completion: { artworkInfo in
                                //println("iTunesLookupWithID: \(lookupID), \(artworkInfo)")

                                if let kind = artworkInfo["kind"] as? String {

                                    switch kind.lowercaseString {

                                    case "song":
                                        openGraph.kind = .AppleMusic

                                        openGraph.previewAudioURLString = artworkInfo["previewUrl"] as? String

                                        var appleMusic = OpenGraph.AppleMusic()

                                        appleMusic.artistName = artworkInfo["artistName"] as? String

                                        appleMusic.artworkURLString30 = artworkInfo["artworkUrl30"] as? String
                                        appleMusic.artworkURLString60 = artworkInfo["artworkUrl60"] as? String
                                        appleMusic.artworkURLString100 = artworkInfo["artworkUrl100"] as? String

                                        appleMusic.collectionName = artworkInfo["collectionName"] as? String
                                        appleMusic.collectionViewURLString = artworkInfo["collectionViewUrl"] as? String

                                        appleMusic.trackTimeMillis = artworkInfo["trackTimeMillis"] as? Int

                                        openGraph.appleMusic = appleMusic

                                    case "feature-movie":
                                        openGraph.kind = .AppleMovie

                                        openGraph.previewVideoURLString = artworkInfo["previewUrl"] as? String

                                    case "ebook":
                                        openGraph.kind = .AppleEBook

                                    default:
                                        break
                                    }
                                }

                                if let collectionType = artworkInfo["collectionType"] as? String {

                                    switch collectionType.lowercaseString {

                                    case "album":

                                        var appleMusic = OpenGraph.AppleMusic()

                                        appleMusic.artistName = artworkInfo["artistName"] as? String

                                        appleMusic.artworkURLString100 = artworkInfo["artworkUrl100"] as? String
                                        appleMusic.artworkURLString160 = artworkInfo["artworkUrl160"] as? String

                                        appleMusic.collectionType = collectionType
                                        appleMusic.collectionName = artworkInfo["collectionName"] as? String
                                        appleMusic.collectionViewURLString = artworkInfo["collectionViewUrl"] as? String

                                        openGraph.appleMusic = appleMusic

                                    default:
                                        break
                                    }
                                }

                                completion(openGraph)
                            })
                        }

                    default:
                        completion(openGraph)
                    }
                }

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

private enum iTunesCountry: String {
    case China = "cn"
    case USA = "us"
}

private func iTunesLookupWithID(lookupID: String, inCountry country: iTunesCountry, failureHandler: ((Reason, String?) -> Void)?, completion: JSONDictionary? -> Void) {

    let lookUpURLString = "https://itunes.apple.com/lookup?id=\(lookupID)&country=\(country.rawValue)"

    Alamofire.request(.GET, lookUpURLString).responseJSON { response in

        println("iTunesLookupWithID \(lookupID): \(response)")

        guard
            let info = response.result.value as? JSONDictionary,
            let resultCount = info["resultCount"] as? Int where resultCount > 0,
            let result = (info["results"] as? [JSONDictionary])?.first
        else {
            completion(nil)
            return
        }

        completion(result)
    }
}

private func iTunesLookupWithID(lookupID: String, failureHandler: ((Reason, String?) -> Void)?, completion: JSONDictionary -> Void) {

    iTunesLookupWithID(lookupID, inCountry: .China, failureHandler: failureHandler, completion: { result in
        if let result = result {
            completion(result)

        } else {
            iTunesLookupWithID(lookupID, inCountry: .USA, failureHandler: failureHandler, completion: { result in
                if let result = result {
                    completion(result)

                } else {
                    if let failureHandler = failureHandler {
                        failureHandler(.NoData, nil)
                    } else {
                        defaultFailureHandler(.NoData, errorMessage: nil)
                    }
                }
            })
        }
    })
}

