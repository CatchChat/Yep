//
//  String+Trans.swift
//  Yep
//
//  Created by NIX on 16/8/12.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension String {

    static func trans_promptSuccessfullyAddedSkill(skill: String, to set: String) -> String {
        return String(format: NSLocalizedString("prompt.added_skill%@_to_set%@_successfully", comment: ""), skill, set)
    }
}

extension String {

    static var trans_titleAbout: String {
        return NSLocalizedString("title.about", comment: "")
    }

    static var trans_promptAcceptFriendRequestFailed: String {
        return NSLocalizedString("prompt.accept_friend_request_failed", comment: "")
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

    static var trans_cancel: String {
        return NSLocalizedString("cancel", comment: "")
    }

    static var trans_titleCancelRecommended: String {
        return NSLocalizedString("title.cancel_recommended", comment: "")
    }

    static var trans_titleChangeMobile: String {
        return NSLocalizedString("title.change_mobile", comment: "")
    }

    static var trans_titleChangeSkills: String {
        return NSLocalizedString("title.change_skills", comment: "")
    }

    static var trans_titleChangeItNow: String {
        return NSLocalizedString("title.change_it_now", comment: "")
    }

    static var trans_promptChannel: String {
        return NSLocalizedString("prompt.channel", comment: "")
    }

    static var trans_titleChatRecords: String {
        return NSLocalizedString("title.chat_records", comment: "")
    }

    static var trans_titleChat: String {
        return NSLocalizedString("title.chat", comment: "")
    }

    static var trans_titleChats: String {
        return NSLocalizedString("title.chats", comment: "")
    }

    static var trans_titleChoosePhoto: String {
        return NSLocalizedString("title.choose_photo", comment: "")
    }

    static var trans_titleChooseSkillSet: String {
        return NSLocalizedString("title.choose_skill_set", comment: "")
    }

    static var trans_titleChooseSource: String {
        return NSLocalizedString("title.choose_source", comment: "")
    }

    static var trans_buttonChooseFromLibrary: String {
        return NSLocalizedString("button.choose_from_library", comment: "")
    }
    
    static var trans_promptChoose: String {
        return NSLocalizedString("prompt.choose", comment: "")
    }

    static var trans_titleClearHistory: String {
        return NSLocalizedString("title.clear_history", comment: "")
    }

    static var trans_confirm: String {
        return NSLocalizedString("confirm", comment: "")
    }

    static var trans_titleContacts: String {
        return NSLocalizedString("title.contacts", comment: "")
    }

    static var trans_titleCreateUsername: String {
        return NSLocalizedString("title.create_username", comment: "")
    }

    static var trans_promptCreateFeedFailed: String {
        return NSLocalizedString("prompt.create_feed_failed", comment: "")
    }

    static var trans_promptCreateUsernameFailed: String {
        return NSLocalizedString("prompt.create_username_failed", comment: "")
    }

    static var trans_titleCreate: String {
        return NSLocalizedString("title.create", comment: "")
    }

    static var trans_promptCreatorsOfBlockedFeeds: String {
        return NSLocalizedString("prompt.creators_of_blocked_feeds", comment: "")
    }

    static var trans_promptCurrentNumber: String {
        return NSLocalizedString("prompt.current_number", comment: "")
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

