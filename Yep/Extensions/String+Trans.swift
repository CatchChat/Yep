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

    static func trans_promptTryUnfriendWith(name: String) -> String {
        return String(format: NSLocalizedString("prompt.try_unfriend_with_%@", comment: ""), name)
    }

    static func trans_promptFeedInfoTooLong(count: Int) -> String {
        return String(format: NSLocalizedString("prompt.feed_info_too_long_%d", comment: ""), count)
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

    static var trans_titleDefault: String {
        return NSLocalizedString("title.default", comment: "")
    }

    static var trans_titleDelete: String {
        return NSLocalizedString("title.delete", comment: "")
    }

    static var trans_promptDidNotGetIt: String {
        return NSLocalizedString("prompt.did_not_get_it", comment: "")
    }

    static var trans_promptDisableDoNotDisturbFailed: String {
        return NSLocalizedString("prompt.disable_do_not_disturb_failed", comment: "")
    }

    static var trans_showDiscoverThem: String {
        return NSLocalizedString("show.discover_them", comment: "")
    }

    static var trans_titleDiscover: String {
        return NSLocalizedString("title.discover", comment: "")
    }

    static var trans_titleDismiss: String {
        return NSLocalizedString("title.dismiss", comment: "")
    }

    static var trans_titleDoNotDisturb: String {
        return NSLocalizedString("title.do_not_disturb", comment: "")
    }

    static var trans_titleDoNotRemindMeInThisVersion: String {
        return NSLocalizedString("title.do_not_remind_me_in_this_version", comment: "")
    }

    static var trans_promptAskForReview: String {
        return NSLocalizedString("prompt.ask_for_review", comment: "")
    }

    static var trans_promptTryLogout: String {
        return NSLocalizedString("prompt.try_logout", comment: "")
    }

    static var trans_promptTryRejectFriendRequest: String {
        return NSLocalizedString("prompt.try_reject_friend_request", comment: "")
    }

    static var trans_titleDone: String {
        return NSLocalizedString("title.done", comment: "")
    }

    static var trans_titleEditProfile: String {
        return NSLocalizedString("title.edit_profile", comment: "")
    }

    static var trans_promptEnableDoNotDisturbFailed: String {
        return NSLocalizedString("prompt.enable_do_not_disturb_failed", comment: "")
    }

    static var trans_promptResendAudioFailed: String {
        return NSLocalizedString("prompt.resend_audio_failed", comment: "")
    }

    static var trans_promptResendImageFailed: String {
        return NSLocalizedString("prompt.resend_image_failed", comment: "")
    }

    static var trans_promptResendLocationFailed: String {
        return NSLocalizedString("prompt.resend_location_failed", comment: "")
    }

    static var trans_promptResendTextFailed: String {
        return NSLocalizedString("prompt.resend_text_failed", comment: "")
    }

    static var trans_promptResendVideoFailed: String {
        return NSLocalizedString("prompt.resend_video_failed", comment: "")
    }

    static var trans_promptSendAudioFailed: String {
        return NSLocalizedString("prompt.send_audio_failed", comment: "")
    }

    static var trans_promptSendImageFailed: String {
        return NSLocalizedString("prompt.send_image_failed", comment: "")
    }

    static var trans_promptSendLocationFailed: String {
        return NSLocalizedString("prompt.send_location_failed", comment: "")
    }

    static var trans_promptSendTextFailed: String {
        return NSLocalizedString("prompt.send_text_failed", comment: "")
    }

    static var trans_promptSendVideoFailed: String {
        return NSLocalizedString("prompt.send_video_failed", comment: "")
    }

    static var trans_promptRequestSendVerificationCodeFailed: String {
        return NSLocalizedString("prompt.request_send_verification_code_failed", comment: "")
    }

    static var trans_promptFeedCanOnlyHasXPhotos: String {
        return NSLocalizedString("prompt.feed_can_only_has_x_photos", comment: "")
    }

    static var trans_promptFeedDeletedByCreator: String {
        return NSLocalizedString("prpmpt.feed_deleted_by_creator", comment: "")
    }

    static var trans_promptFeedNotFound: String {
        return NSLocalizedString("prompt.feed_not_found", comment: "")
    }

    static var trans_titleClearUnread: String {
        return NSLocalizedString("title.clear_unread", comment: "")
    }

    static var trans_titleFeedback: String {
        return NSLocalizedString("title.feedback", comment: "")
    }

    static var trans_promptFeedsByThisCreatorWillNotAppear: String {
        return NSLocalizedString("prompt.feeds_by_this_creator_will_not_appear", comment: "")
    }
    static var trans_titleFeeds: String {
        return NSLocalizedString("title.feeds", comment: "")
    }

    static var trans_errorFetchFailed: String {
        return NSLocalizedString("error.fetch_failed", comment: "")
    }

    static var trans_promptFetching: String {
        return NSLocalizedString("prompt.fetching", comment: "")
    }

    static var trans_titleFindAll: String {
        return NSLocalizedString("title.find_all", comment: "")
    }

    static var trans_titleFriendsInContacts: String {
        return NSLocalizedString("title.friends_in_contacts", comment: "")
    }
    static var trans_titleFriends: String {
        return NSLocalizedString("title.friends", comment: "")
    }

    static var trans_shareFromYep: String {
        return NSLocalizedString("share.from_yep", comment: "")
    }

    static var trans_shareFromYepWithSkills: String {
        return NSLocalizedString("share.from_yep_with_skills", comment: "")
    }

    static var trans_timeFrom: String {
        return NSLocalizedString("time.from", comment: "")
    }
    static var trans_showGenius: String {
        return NSLocalizedString("show.genius", comment: "")
    }
    static var trans_promptGetNotifiedWithSubscribe: String {
        return NSLocalizedString("prompt.get_notified_with_subscribe", comment: "")
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

