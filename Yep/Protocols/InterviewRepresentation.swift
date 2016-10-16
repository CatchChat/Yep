//
//  InterviewRepresentation.swift
//  Yep
//
//  Created by NIX on 16/7/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import YepKit

protocol InterviewRepresentation {

    var user: DiscoveredUser { get }
    var linkURL: URL { get }
}

extension GeniusInterview: InterviewRepresentation {

    var linkURL: URL {
        return url
    }
}

extension GeniusInterviewBanner: InterviewRepresentation {
}

