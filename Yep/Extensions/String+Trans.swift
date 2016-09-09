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

    static func trans_shareFeedWithDescription(description: String) -> String {
        return String(format: NSLocalizedString("title.share_feed_with_description_%@", comment: ""), description)
    }

    static func trans_shareUserFromYepWithSkills(name: String) -> String {
        return String(format: NSLocalizedString("share.user_%@_from_yep_with_skills", comment: ""), name)
    }

    static func trans_promptLastSeenAt(timeString: String) -> String {
        return String(format: NSLocalizedString("prompt.last_seen_at_%@", comment: ""), timeString)
    }

    static func trans_promptLastSeenAt(unixTime: NSTimeInterval) -> String {
        let timeString = NSDate(timeIntervalSince1970: unixTime).timeAgo.lowercaseString
        return trans_promptLastSeenAt(timeString)
    }
}

extension String {

    static var trans_aboutRecommendYep: String {
        return NSLocalizedString("about.recommend_yep", comment: "")
    }

    static var trans_aboutYepDescription: String {
        return NSLocalizedString("about.yep_description", comment: "")
    }

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

    static var trans_titleMaybeNextTime: String {
        return NSLocalizedString("title.maybe_next_time", comment: "")
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

    static var trans_titleShareFeed: String {
        return NSLocalizedString("title.share_feed", comment: "")
    }

    static var trans_titleJoinedFeeds: String {
        return NSLocalizedString("title.joined_feeds", comment: "")
    }

    static var trans_titleLately: String {
        return NSLocalizedString("title.lately", comment: "")
    }

    static var trans_titleLocation: String {
        return NSLocalizedString("title.location", comment: "")
    }

    static var trans_titleLogOut: String {
        return NSLocalizedString("title.log_out", comment: "")
    }

    static var trans_titleLogin: String {
        return NSLocalizedString("title.login", comment: "")
    }

    static var trans_promptUploading: String {
        return NSLocalizedString("prompt.uploading", comment: "")
    }

    static var trans_promptHoldForVoice: String {
        return NSLocalizedString("prompt.hold_for_voice", comment: "")
    }

    static var trans_promptHaveANiceDay: String {
        return NSLocalizedString("prompt.have_a_nice_day", comment: "")
    }

    static var trans_titleHideFeedsFromThisUser: String {
        return NSLocalizedString("title.hide_feeds_from_this_user", comment: "")
    }

    static var trans_titleHide: String {
        return NSLocalizedString("title.hide", comment: "")
    }

    static var trans_promptCreateUsername: String {
        return NSLocalizedString("prompt.create_username", comment: "")
    }

    static var trans_promptInputVerificationCode: String {
        return NSLocalizedString("prompt.input_verification_code", comment: "")
    }

    static var trans_promptInputBlogURL: String {
        return NSLocalizedString("prompt.input_blog_url", comment: "")
    }

    static var trans_promptNewFeedPlaceholder: String {
        return NSLocalizedString("prompt.new_feed_placeholder", comment: "")
    }

    static var trans_promptUserIntroPlaceholder: String {
        return NSLocalizedString("prompt.user_intro_placeholder", comment: "")
    }
    
    static var trans_titleSelfIntroduction: String {
        return NSLocalizedString("title.self_introduction", comment: "")
    }

    static var trans_promptInvalidURL: String {
        return NSLocalizedString("prompt.invalid_url", comment: "")
    }

    static var trans_showMatchFriendsWithSkills: String {
        return NSLocalizedString("show.match_friends_with_skills", comment: "")
    }

    static var trans_titleMatch: String {
        return NSLocalizedString("title.match", comment: "")
    }

    static var trans_titleMeetGeniuses: String {
        return NSLocalizedString("title.meet_geniuses", comment: "")
    }

    static var trans_showMeet: String {
        return NSLocalizedString("show.meet", comment: "")
    }

    static var trans_titleModify: String {
        return NSLocalizedString("title.modify", comment: "")
    }

    static var trans_titleMute: String {
        return NSLocalizedString("title.mute", comment: "")
    }

    static var trans_titleMyCurrentLocation: String {
        return NSLocalizedString("title.my_current_location", comment: "")
    }

    static var trans_titleNearby: String {
        return NSLocalizedString("title.nearby", comment: "")
    }

    static var trans_promptNetworkConnectionIsNotGood: String {
        return NSLocalizedString("prompt.network_connection_is_not_good", comment: "")
    }

    static var trans_titleNewFeed: String {
        return NSLocalizedString("title.new_feed", comment: "")
    }

    static var trans_titleNewVoice: String {
        return NSLocalizedString("title.new_voice", comment: "")
    }

    static var trans_buttonNextStep: String {
        return NSLocalizedString("button.next_step", comment: "")
    }

    static var trans_titleNickname: String {
        return NSLocalizedString("title.nickname", comment: "")
    }

    static var trans_promptNoBlockedFeedCreators: String {
        return NSLocalizedString("prompt.no_blocked_feed_creators", comment: "")
    }

    static var trans_promptNoFeeds: String {
        return NSLocalizedString("prompt.no_feeds", comment: "")
    }

    static var trans_promptNoInterviews: String {
        return NSLocalizedString("prompt.no_interviews", comment: "")
    }

    static var trans_buttonPost: String {
        return NSLocalizedString("button.post", comment: "")
    }

    static var trans_promptNoSelfIntroduction: String {
        return NSLocalizedString("prompt.no_self_introduction", comment: "")
    }

    static var trans_promptNoBlockedUsers: String {
        return NSLocalizedString("prompt.no_blocked_users", comment: "")
    }

    static var trans_promptNoFriends: String {
        return NSLocalizedString("prompt.no_friends", comment: "")
    }

    static var trans_promptNoMessages: String {
        return NSLocalizedString("prompt.no_messages", comment: "")
    }

    static var trans_promptNoNewFriends: String {
        return NSLocalizedString("prompt.no_new_friends", comment: "")
    }

    static var trans_promptNoMoreResults: String {
        return NSLocalizedString("prompt.no_more_results", comment: "")
    }

    static var trans_promptNoSearchResults: String {
        return NSLocalizedString("prompt.no_search_results", comment: "")
    }

    static var trans_promptNoUsername: String {
        return NSLocalizedString("prompt.no_username", comment: "")
    }

    static var trans_promptNone: String {
        return NSLocalizedString("prompt.none", comment: "")
    }

    static var trans_titleNotNow: String {
        return NSLocalizedString("title.not_now", comment: "")
    }

    static var trans_titleNotice: String {
        return NSLocalizedString("title.notice", comment: "")
    }

    static var trans_titleNotificationsAndPrivacy: String {
        return NSLocalizedString("title.notifications_and_privacy", comment: "")
    }

    static var trans_titleFeedDiscussion: String {
        return NSLocalizedString("title.feed_discussion", comment: "")
    }

    static var trans_promptOAuthError: String {
        return NSLocalizedString("prompt.oauth_error", comment: "")
    }

    static var trans_titleOK: String {
        return NSLocalizedString("title.ok", comment: "")
    }

    static var trans_aboutOpenSourceOfYep: String {
        return NSLocalizedString("about.open_source_of_yep", comment: "")
    }

    static var trans_titleOpenSource: String {
        return NSLocalizedString("title.open_source", comment: "")
    }

    static var trans_titleOtherReason: String {
        return NSLocalizedString("title.other_reason", comment: "")
    }

    static var trans_promptPeopleWithThisSkill: String {
        return NSLocalizedString("prompt.people_with_this_skill", comment: "")
    }

    static var trans_titlePickLocation: String {
        return NSLocalizedString("title.pick_location", comment: "")
    }

    static var trans_titlePickPhotos: String {
        return NSLocalizedString("title.pick_photos", comment: "")
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

