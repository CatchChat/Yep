//
//  StoryboardTests.swift
//  Yep
//
//  Created by NIX on 16/8/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

final class StoryboardTests: XCTestCase {

    func testStoryboard() {

        do {
            let storyboards: [UIStoryboard] = [
                UIStoryboard.yep_show,
                UIStoryboard.yep_main,
            ]

            print("storyboards: \(storyboards.count)")
        }

        do {
            let scenes: [UIViewController] = [
                UIStoryboard.Scene.pickPhotos,
                UIStoryboard.Scene.conversation,
                UIStoryboard.Scene.profile,
                UIStoryboard.Scene.mediaPreview,
                UIStoryboard.Scene.meetGenius,
                UIStoryboard.Scene.discover,
                UIStoryboard.Scene.geniusInterview,
                UIStoryboard.Scene.registerSelectSkills,
                UIStoryboard.Scene.registerPickSkills,
                UIStoryboard.Scene.registerPickName,
                UIStoryboard.Scene.loginByMobile,
            ]

            print("scenes: \(scenes.count)")
        }
    }
}

