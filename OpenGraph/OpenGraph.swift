//
//  OpenGraph.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import Kanna

public struct OpenGraph {

    enum Kind {
        case `default`
        case appleMusic
        case appleMovie
        case appleEBook
    }

    var kind: Kind = .default

    public var url: URL

    public var siteName: String?

    public var title: String?
    public var description: String?

    public var previewImageURLString: String?
    public var previewVideoURLString: String?
    public var previewAudioURLString: String?

    public var isValid: Bool {

        guard
            let siteName = siteName, !siteName.isEmpty,
            let title = title, !title.isEmpty,
            let description = description, !description.isEmpty,
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

    init(url: URL) {
        self.url = url.opengraph_appleAllianceURL
    }

    static func fromHTMLString(_ HTMLString: String, for url: URL) -> OpenGraph? {

        if let doc = Kanna.HTML(html: HTMLString, encoding: .utf8) {

            var openGraph = OpenGraph(url: url)

            if let metaSet = doc.head?.css("meta") {

                var openGraphInfo = [String: String]()

                for meta in metaSet {
                    if let property = meta["property"]?.lowercased() {
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
                    openGraph.siteName = url.host
                }

                if openGraph.title == nil {
                    if let title = doc.head?.css("title").first(where: { _ in true })?.text, !title.isEmpty {
                        openGraph.title = title
                    }
                }

                if openGraph.description == nil {
                    for meta in metaSet {
                        if let name = meta["name"]?.lowercased() {
                            if name == "description" {
                                if let description = meta["content"], !description.isEmpty {
                                    openGraph.description = description
                                    break
                                }
                            }
                        }
                    }
                }

                if openGraph.previewImageURLString == nil {
                    openGraph.previewImageURLString = HTMLString.opengraph_firstImageURL?.absoluteString
                }

                // 特别再补救一次 description

                if openGraph.description == nil {
                    let firstParagraph = doc.body?.css("p").first(where: { _ in true })?.text
                    openGraph.description = firstParagraph
                }

                // 再去除字符串中的换行

                openGraph.siteName = openGraph.siteName?.opengraph_removeAllNewLines
                openGraph.title = openGraph.title?.opengraph_removeAllNewLines
                openGraph.description = openGraph.description?.opengraph_removeAllNewLines

                // 以及行首行尾的空白

                openGraph.siteName = openGraph.siteName?.opengraph_trimming(.whitespaceAndNewline)
                openGraph.title = openGraph.title?.opengraph_trimming(.whitespaceAndNewline)
                openGraph.description = openGraph.description?.opengraph_trimming(.whitespaceAndNewline)
            }

            return openGraph
        }

        return nil
    }
}

