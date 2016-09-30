//
//  Service.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepNetworking
import Alamofire
import Kanna

public func titleOfURL(_ url: URL, failureHandler: FailureHandler?, completion: @escaping (_ title: String) -> Void) {

    Alamofire.request(url).responseString(encoding: .utf8, completionHandler: { response in

        let error = response.result.error

        let failureHandler: FailureHandler = { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            failureHandler?(reason, errorMessage)
        }

        guard error == nil else {
            let errorMessage = String.trans_errorGetTitleOfURLFailed
            failureHandler(.other(error), errorMessage)

            return
        }

        guard let HTMLString = response.result.value, let data = response.data else {
            failureHandler(.couldNotParseJSON, "No HTMLString or data!")

            return
        }

        //println("\ntitleOfURL: \(URL)\n\(HTMLString)")

        // 编码转换
        let newHTMLString = getUTF8HTMLStringFromHTMLString(HTMLString, withData: data)

        guard
            let doc = Kanna.HTML(html: newHTMLString, encoding: .utf8),
            let title = doc.head?.css("title").first(where: { _ in true })?.text, !title.isEmpty else {

                let errorMessage = String.trans_promptNoTitleForURL
                failureHandler(.couldNotParseJSON, errorMessage)

                return
        }

        completion(title)
    })
}

public func openGraphWithURL(_ url: URL, failureHandler: FailureHandler?, completion: @escaping (OpenGraph) -> Void) {

    Alamofire.request(url).responseString(encoding: .utf8, completionHandler: { response in

        let error = response.result.error

        let failureHandler: FailureHandler = { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)
            failureHandler?(reason, errorMessage)
        }

        guard error == nil else {
            failureHandler(.other(error), nil)

            return
        }

        if let HTMLString = response.result.value, let data = response.data {
            //println("\n openGraphWithURLString: \(URL)\n\(HTMLString)")

            // 尽量使用长链接
            let finalURL = response.response?.url ?? url

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

        failureHandler(.couldNotParseJSON, nil)
    })
}

// ref http://a4esl.org/c/charset.html
private enum WeirdCharset: String {
    // China
    case gb2312 = "GB2312"
    case gbk = "GBK"
    case gb18030 = "GB18030"

    // Taiwan, HongKong ...
    case big5 = "BIG5"
    case big5hkscs = "BIG5-HKSCS"

    // Korean
    case euckr = "EUC-KR"
}

private func getUTF8HTMLStringFromHTMLString(_ HTMLString: String, withData data: Data) -> String {

    let pattern = "charset=([A-Za-z0-9\\-]+)"

    guard let
        charsetRegex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
        let result = charsetRegex.firstMatch(in: HTMLString, options: [.reportCompletion], range: NSMakeRange(0, (HTMLString as NSString).length))
    else {
        return HTMLString
    }

    let charsetStringRange = result.rangeAt(1)
    let charsetString = (HTMLString as NSString).substring(with: charsetStringRange).uppercased()

    guard let weirdCharset = WeirdCharset(rawValue: charsetString) else {
        return HTMLString
    }

    let encoding: String.Encoding

    switch weirdCharset {

    case .gb2312, .gbk, .gb18030:
        let china = CFStringEncodings.GB_18030_2000
        encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(china.rawValue)))

    case .big5, .big5hkscs:
        let taiwan = CFStringEncodings.big5_HKSCS_1999
        encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(taiwan.rawValue)))

    case .euckr:
        let korean = CFStringEncodings.EUC_KR
        encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(korean.rawValue)))
    }

    guard let newHTMLString = String(data: data, encoding: encoding) else {
        return HTMLString
    }

    return newHTMLString
}

private enum iTunesCountry: String {
    case china = "cn"
    case usa = "us"
}

private func iTunesLookupWithID(_ lookupID: String, inCountry country: iTunesCountry, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (JSONDictionary?) -> Void) {

    let lookUpURLString = "https://itunes.apple.com/lookup?id=\(lookupID)&country=\(country.rawValue)"

    Alamofire.request(lookUpURLString).responseJSON { response in

        print("iTunesLookupWithID \(lookupID): \(response)")

        guard
            let info = response.result.value as? JSONDictionary,
            let resultCount = info["resultCount"] as? Int, resultCount > 0,
            let result = (info["results"] as? [JSONDictionary])?.first
        else {
            completion(nil)
            return
        }

        completion(result)
    }
}

private func iTunesLookupWithID(_ lookupID: String, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (JSONDictionary) -> Void) {

    iTunesLookupWithID(lookupID, inCountry: .china, failureHandler: failureHandler, completion: { result in
        if let result = result {
            completion(result)

        } else {
            iTunesLookupWithID(lookupID, inCountry: .usa, failureHandler: failureHandler, completion: { result in
                if let result = result {
                    completion(result)

                } else {
                    if let failureHandler = failureHandler {
                        failureHandler(.noData, nil)
                    } else {
                        defaultFailureHandler(.noData, nil)
                    }
                }
            })
        }
    })
}

