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

    var URL: NSURL

    var siteName: String?

    var title: String?
    var description: String?

    var previewImageURLString: String?
    var previewVideoURLString: String?
    var previewAudioURLString: String?

    var isValid: Bool {

        guard
            let siteName = siteName?.trimming(.WhitespaceAndNewline) where !siteName.isEmpty,
            let title = title?.trimming(.WhitespaceAndNewline) where !title.isEmpty,
            let description = description?.trimming(.WhitespaceAndNewline) where !description.isEmpty,
            let _ = previewImageURLString
        else {
            return false
        }

        return true
    }

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
        var trackViewURLString: String?
    }
    var appleMusic: AppleMusic?

    struct AppleMovie {

        var artistName: String?

        var artworkURLString30: String?
        var artworkURLString60: String?
        var artworkURLString100: String?

        var shortDescription: String?
        var longDescription: String?

        var trackTimeMillis: Int?
        var trackViewURLString: String?
    }
    var appleMovie: AppleMovie?

    struct AppleEBook {

        var artistName: String?

        var artworkURLString60: String?
        var artworkURLString100: String?

        var description: String?

        var trackName: String?  // book name
        var trackViewURLString: String?
    }
    var appleEBook: AppleEBook?

    init(URL: NSURL) {
        self.URL = URL.yep_appleAllianceURL
    }

    static func fromHTMLString(HTMLString: String, forURL URL: NSURL) -> OpenGraph? {

        if let doc = Kanna.HTML(html: HTMLString, encoding: NSUTF8StringEncoding) {

            var openGraph = OpenGraph(URL: URL)

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

                // 若缺失某些`og:`标签，再做补救

                if openGraph.siteName == nil {
                    openGraph.siteName = URL.host
                }

                if openGraph.title == nil {
                    if let title = doc.head?.css("title").first?.text where !title.isEmpty {
                        openGraph.title = title
                    }
                }

                if openGraph.description == nil {
                    for meta in metaSet {
                        if let name = meta["name"]?.lowercaseString {
                            if name == "description" {
                                if let description = meta["content"] where !description.isEmpty {
                                    openGraph.description = description
                                    break
                                }
                            }
                        }
                    }
                }

                if openGraph.previewImageURLString == nil {
                    openGraph.previewImageURLString = HTMLString.yep_firstImageURL?.absoluteString
                }

                // 特别再补救一次 description

                if openGraph.description == nil {
                    let firstParagraph = doc.body?.css("p").first?.text
                    openGraph.description = firstParagraph
                }

                // 再去除字符串中的换行

                openGraph.siteName = openGraph.siteName?.yep_removeAllNewLines
                openGraph.title = openGraph.title?.yep_removeAllNewLines
                openGraph.description = openGraph.description?.yep_removeAllNewLines
            }

            return openGraph
        }

        return nil
    }
}

// ref http://a4esl.org/c/charset.html
private enum WeirdCharset: String {
    // China
    case GB2312 = "GB2312"
    case GBK = "GBK"
    case GB18030 = "GB18030"

    // Taiwan, HongKong ...
    case BIG5 = "BIG5"
    case BIG5HKSCS = "BIG5-HKSCS"

    // Korean
    case EUCKR = "EUC-KR"
}

private func getUTF8HTMLStringFromHTMLString(HTMLString: String, withData data: NSData) -> String {

    let pattern = "charset=([A-Za-z0-9\\-]+)"

    guard let
        charsetRegex = try? NSRegularExpression(pattern: pattern, options: [.CaseInsensitive]),
        result = charsetRegex.firstMatchInString(HTMLString, options: [.ReportCompletion], range: NSMakeRange(0, (HTMLString as NSString).length))
    else {
        return HTMLString
    }

    let charsetStringRange = result.rangeAtIndex(1)
    let charsetString = (HTMLString as NSString).substringWithRange(charsetStringRange).uppercaseString

    guard let weirdCharset = WeirdCharset(rawValue: charsetString) else {
        return HTMLString
    }

    let encoding: NSStringEncoding

    switch weirdCharset {

    case .GB2312, .GBK, .GB18030:
        let china = CFStringEncodings.GB_18030_2000
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(china.rawValue))

    case .BIG5, .BIG5HKSCS:
        let taiwan = CFStringEncodings.Big5_HKSCS_1999
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(taiwan.rawValue))

    case .EUCKR:
        let korean = CFStringEncodings.EUC_KR
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(korean.rawValue))
    }

    guard let newHTMLString = String(data: data, encoding: encoding) else {
        return HTMLString
    }

    return newHTMLString
}

func openGraphWithURL(URL: NSURL, failureHandler: ((Reason, String?) -> Void)?, completion: OpenGraph -> Void) {

    Alamofire.request(.GET, URL.absoluteString, parameters: nil, encoding: .URL).responseString(encoding: NSUTF8StringEncoding, completionHandler: { response in

        let error = response.result.error

        guard error == nil else {

            if let failureHandler = failureHandler {
                failureHandler(.Other(error), nil)
            } else {
                defaultFailureHandler(reason: .Other(error), errorMessage: nil)
            }

            return
        }

        if let HTMLString = response.result.value, data = response.data {
            //println("\n openGraphWithURLString: \(URL)\n\(HTMLString)")

            // 尽量使用长链接
            var finalURL = URL
            if let _finalURL = response.response?.URL {
                finalURL = _finalURL
            }

            // 编码转换
            let newHTMLString = getUTF8HTMLStringFromHTMLString(HTMLString, withData: data)
            //println("newHTMLString: \(newHTMLString)")

            if let openGraph = OpenGraph.fromHTMLString(newHTMLString, forURL: finalURL) {

                completion(openGraph)
                /*
                var openGraph = openGraph

                guard let URL = response.response?.URL, host = URL.host, _ = NSURL.AppleOnlineStoreHost(rawValue: host) else {
                    completion(openGraph)

                    return
                }

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
                                appleMusic.trackViewURLString = artworkInfo["trackViewUrl"] as? String

                                openGraph.appleMusic = appleMusic

                            case "feature-movie":
                                openGraph.kind = .AppleMovie

                                openGraph.previewVideoURLString = artworkInfo["previewUrl"] as? String

                                var appleMovie = OpenGraph.AppleMovie()

                                appleMovie.artistName = artworkInfo["artistName"] as? String

                                appleMovie.artworkURLString30 = artworkInfo["artworkUrl30"] as? String
                                appleMovie.artworkURLString60 = artworkInfo["artworkUrl60"] as? String
                                appleMovie.artworkURLString100 = artworkInfo["artworkUrl100"] as? String

                                appleMovie.shortDescription = artworkInfo["shortDescription"] as? String
                                appleMovie.longDescription = artworkInfo["longDescription"] as? String
                                
                                appleMovie.trackTimeMillis = artworkInfo["trackTimeMillis"] as? Int
                                appleMovie.trackViewURLString = artworkInfo["trackViewUrl"] as? String

                                openGraph.appleMovie = appleMovie

                            case "ebook":
                                openGraph.kind = .AppleEBook

                                var appleEBook = OpenGraph.AppleEBook()

                                appleEBook.artistName = artworkInfo["artistName"] as? String

                                appleEBook.artworkURLString60 = artworkInfo["artworkUrl60"] as? String
                                appleEBook.artworkURLString100 = artworkInfo["artworkUrl100"] as? String

                                appleEBook.description = artworkInfo["description"] as? String

                                appleEBook.trackName = artworkInfo["trackName"] as? String
                                appleEBook.trackViewURLString = artworkInfo["trackViewUrl"] as? String

                                openGraph.appleEBook = appleEBook

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
                */

                return
            }
        }

        if let failureHandler = failureHandler {
            failureHandler(.CouldNotParseJSON, nil)
        } else {
            defaultFailureHandler(reason: .CouldNotParseJSON, errorMessage: nil)
        }
    })
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
                        defaultFailureHandler(reason: .NoData, errorMessage: nil)
                    }
                }
            })
        }
    })
}

