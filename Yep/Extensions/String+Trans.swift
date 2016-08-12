//
//  String+Trans.swift
//  Yep
//
//  Created by NIX on 16/8/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension String {

    static var trans_titleAbout: String {
        return NSLocalizedString("title.about", comment: "")
    }

    static var trans_promptAcceptFriendRequestFailed: String {
        return NSLocalizedString("prompt.accept_friend_request_failed", comment: "")
    }

    static func trans_promptSuccessfullyAddedSkill(skill: String, to set: String) -> String {
        return String(format: NSLocalizedString("prompt.added_skill%@_to_set%@_successfully", comment: ""), skill, set)
    }

    static var trans_promptAlsoDeleteThisFeed: String {
        return NSLocalizedString("prompt.also_delete_this_feed", comment: "")
    }

    static var trans_titleAvailableFriends: String {
        return NSLocalizedString("title.available_friends", comment: "")
    }

    static var trans_buttonBack: String {
        return NSLocalizedString("button.back", comment: "")
    }

    static var trans_infoBeginChatJustNow: String {
        return NSLocalizedString("info.begin_chat_just_now", comment: "")
    }

    static var trans_titleBlock: String {
        return NSLocalizedString("title.block", comment: "")
    }

    static var trans_titleBlockedCreators: String {
        return NSLocalizedString("title.blocked_creators", comment: "")
    }

    static var trans_titleBlockedUsers: String {
        return NSLocalizedString("title.blocked_users", comment: "")
    }

    static var trans_subtitleBuildWorldTogether: String {
        return NSLocalizedString("subtitle.build_world_together", comment: "")
    }

    static var trans_promptTapNextAgreeTerms: String {
        return NSLocalizedString("prompt.tap_next_agree_terms", comment: "")
    }

    static var trans_buttonCallMe: String {
        return NSLocalizedString("button.call_me", comment: "")
    }

    static var trans_buttonCalling: String {
        return NSLocalizedString("button.calling", comment: "")
    }

    static var trans_titleCamera: String {
        return NSLocalizedString("title.camera", comment: "")
    }
    
    static var trans_promptCancelRecommendedFeedFailed: String {
        return NSLocalizedString("prompt.cancel_recommended_feed_failed", comment: "")
    }


}

extension String {

    static var trans_reportAdvertising: String {
        return NSLocalizedString("report.advertising", comment: "")
    }

    static var trans_reportPorno: String {
        return NSLocalizedString("report.porno", comment: "")
    }

    static var trans_reportScams: String {
        return NSLocalizedString("report.scams", comment: "")
    }

    static var trans_reportOther: String {
        return NSLocalizedString("report.other", comment: "")
    }
}

