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
            let show = UIStoryboard.yep_show
            let main = UIStoryboard.yep_main

            print([show, main])
        }

        do {
            let a = UIStoryboard.Scene.pickPhotos
            let b = UIStoryboard.Scene.conversation
            let c = UIStoryboard.Scene.profile
            let d = UIStoryboard.Scene.mediaPreview
            let e = UIStoryboard.Scene.meetGenius
            let f = UIStoryboard.Scene.discover
            let g = UIStoryboard.Scene.geniusInterview
            let h = UIStoryboard.Scene.registerSelectSkills
            let i = UIStoryboard.Scene.registerPickSkills
            let j = UIStoryboard.Scene.registerPickName
            let k = UIStoryboard.Scene.loginByMobile

            print([a, b, c, d, e, f, g, h, i, j, k])
        }
    }
}

