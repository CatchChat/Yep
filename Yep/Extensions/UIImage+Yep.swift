//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/10.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

// MARK: - Badges

extension UIImage {

    static func yep_badgeWithName(name: String) -> UIImage {
        return UIImage(named: "badge_" + name)!
    }
}

// MARK: - Images

// nix love awk, in Images.xcassets
// $ ls -l | awk '{print $9}' | awk -F"." '{print $1}' | awk -F"_" '{out=$0" ";for(i=1;i<=NF;i++){if(i==1){out=out""tolower($i)}else{out=out""toupper(substr($i,1,1))substr($i,2)}};print out}' | awk '{print "static var yep_"$2": UIImage {\n\treturn UIImage(named: \""$1"\")!\n}\n"}' > ~/Downloads/images.swift
// ref https://github.com/nixzhu/dev-blog/blob/master/2016-08-11-awk.md

extension UIImage {

    static var yep_bubbleBody: UIImage {
        return UIImage(named: "bubble_body")!
    }

    static var yep_bubbleLeftTail: UIImage {
        return UIImage(named: "bubble_left_tail")!
    }

    static var yep_bubbleRightTail: UIImage {
        return UIImage(named: "bubble_right_tail")!
    }

    static var yep_buttonCameraRoll: UIImage {
        return UIImage(named: "button_camera_roll")!
    }

    static var yep_buttonCapture: UIImage {
        return UIImage(named: "button_capture")!
    }

    static var yep_buttonCaptureOk: UIImage {
        return UIImage(named: "button_capture_ok")!
    }

    static var yep_buttonSkillCategory: UIImage {
        return UIImage(named: "button_skill_category")!
    }

    static var yep_buttonVoicePause: UIImage {
        return UIImage(named: "button_voice_pause")!
    }

    static var yep_buttonVoicePlay: UIImage {
        return UIImage(named: "button_voice_play")!
    }

    static var yep_buttonVoiceReset: UIImage {
        return UIImage(named: "button_voice_reset")!
    }

    static var yep_chatSharetopicbubble: UIImage {
        return UIImage(named: "chat_sharetopicbubble")!
    }

    static var yep_defaultAvatar: UIImage {
        return UIImage(named: "default_avatar")!
    }

    static var yep_defaultAvatar30: UIImage {
        return UIImage(named: "default_avatar_30")!
    }

    static var yep_defaultAvatar40: UIImage {
        return UIImage(named: "default_avatar_40")!
    }

    static var yep_defaultAvatar60: UIImage {
        return UIImage(named: "default_avatar_60")!
    }

    static var yep_feedAudioBubble: UIImage {
        return UIImage(named: "feed_audio_bubble")!
    }

    static var yep_feedContainerBackground: UIImage {
        return UIImage(named: "feed_container_background")!
    }

    static var yep_feedMediaAdd: UIImage {
        return UIImage(named: "feed_media_add")!
    }

    static var yep_feedSkillChannelArrow: UIImage {
        return UIImage(named: "feed_skill_channel_arrow")!
    }

    static var yep_flatArrowDown: UIImage {
        return UIImage(named: "flat_arrow_down")!
    }

    static var yep_flatArrowLeft: UIImage {
        return UIImage(named: "flat_arrow_left")!
    }

    static var yep_gradientArt: UIImage {
        return UIImage(named: "gradient_art")!
    }

    static var yep_gradientLife: UIImage {
        return UIImage(named: "gradient_life")!
    }

    static var yep_gradientSport: UIImage {
        return UIImage(named: "gradient_sport")!
    }

    static var yep_gradientTech: UIImage {
        return UIImage(named: "gradient_tech")!
    }

    static var yep_iconAccessory: UIImage {
        return UIImage(named: "icon_accessory")!
    }

    static var yep_iconAccessoryMini: UIImage {
        return UIImage(named: "icon_accessory_mini")!
    }

    static var yep_iconArrowDown: UIImage {
        return UIImage(named: "icon_arrow_down")!
    }

    static var yep_iconArrowUp: UIImage {
        return UIImage(named: "icon_arrow_up")!
    }

    static var yep_iconBack: UIImage {
        return UIImage(named: "icon_back")!
    }

    static var yep_iconBlog: UIImage {
        return UIImage(named: "icon_blog")!
    }

    static var yep_iconChat: UIImage {
        return UIImage(named: "icon_chat")!
    }

    static var yep_iconChatActive: UIImage {
        return UIImage(named: "icon_chat_active")!
    }

    static var yep_iconChatActiveUnread: UIImage {
        return UIImage(named: "icon_chat_active_unread")!
    }

    static var yep_iconChatUnread: UIImage {
        return UIImage(named: "icon_chat_unread")!
    }

    static var yep_iconContact: UIImage {
        return UIImage(named: "icon_contact")!
    }

    static var yep_iconContactActive: UIImage {
        return UIImage(named: "icon_contact_active")!
    }

    static var yep_iconCurrentLocation: UIImage {
        return UIImage(named: "icon_current_location")!
    }

    static var yep_iconDiscussion: UIImage {
        return UIImage(named: "icon_discussion")!
    }

    static var yep_iconDotFailed: UIImage {
        return UIImage(named: "icon_dot_failed")!
    }

    static var yep_iconDotSending: UIImage {
        return UIImage(named: "icon_dot_sending")!
    }

    static var yep_iconDotUnread: UIImage {
        return UIImage(named: "icon_dot_unread")!
    }

    static var yep_iconDribbble: UIImage {
        return UIImage(named: "icon_dribbble")!
    }

    static var yep_iconExplore: UIImage {
        return UIImage(named: "icon_explore")!
    }

    static var yep_iconExploreActive: UIImage {
        return UIImage(named: "icon_explore_active")!
    }

    static var yep_iconFeedText: UIImage {
        return UIImage(named: "icon_feed_text")!
    }

    static var yep_iconFeeds: UIImage {
        return UIImage(named: "icon_feeds")!
    }

    static var yep_iconFeedsActive: UIImage {
        return UIImage(named: "icon_feeds_active")!
    }

    static var yep_iconGhost: UIImage {
        return UIImage(named: "icon_ghost")!
    }

    static var yep_iconGithub: UIImage {
        return UIImage(named: "icon_github")!
    }

    static var yep_iconImagepickerCheck: UIImage {
        return UIImage(named: "icon_imagepicker_check")!
    }

    static var yep_iconInstagram: UIImage {
        return UIImage(named: "icon_instagram")!
    }

    static var yep_iconKeyboard: UIImage {
        return UIImage(named: "icon_keyboard")!
    }

    static var yep_iconLink: UIImage {
        return UIImage(named: "icon_link")!
    }

    static var yep_iconList: UIImage {
        return UIImage(named: "icon_list")!
    }

    static var yep_iconLocation: UIImage {
        return UIImage(named: "icon_location")!
    }

    static var yep_iconLocationCheckmark: UIImage {
        return UIImage(named: "icon_location_checkmark")!
    }

    static var yep_iconMe: UIImage {
        return UIImage(named: "icon_me")!
    }

    static var yep_iconMeActive: UIImage {
        return UIImage(named: "icon_me_active")!
    }

    static var yep_iconMediaDelete: UIImage {
        return UIImage(named: "icon_media_delete")!
    }

    static var yep_iconMinicard: UIImage {
        return UIImage(named: "icon_minicard")!
    }

    static var yep_iconMore: UIImage {
        return UIImage(named: "icon_more")!
    }

    static var yep_iconMoreImage: UIImage {
        return UIImage(named: "icon_more_image")!
    }

    static var yep_iconPause: UIImage {
        return UIImage(named: "icon_pause")!
    }

    static var yep_iconPin: UIImage {
        return UIImage(named: "icon_pin")!
    }

    static var yep_iconPinMiniGray: UIImage {
        return UIImage(named: "icon_pin_mini_gray")!
    }

    static var yep_iconPinShadow: UIImage {
        return UIImage(named: "icon_pin_shadow")!
    }

    static var yep_iconPlay: UIImage {
        return UIImage(named: "icon_play")!
    }

    static var yep_iconPlayvideo: UIImage {
        return UIImage(named: "icon_playvideo")!
    }

    static var yep_iconProfilePhone: UIImage {
        return UIImage(named: "icon_profile_phone")!
    }

    static var yep_iconQuickCamera: UIImage {
        return UIImage(named: "icon_quick_camera")!
    }

    static var yep_iconRemove: UIImage {
        return UIImage(named: "icon_remove")!
    }

    static var yep_iconRepo: UIImage {
        return UIImage(named: "icon_repo")!
    }

    static var yep_iconSettings: UIImage {
        return UIImage(named: "icon_settings")!
    }

    static var yep_iconShare: UIImage {
        return UIImage(named: "icon_share")!
    }

    static var yep_iconSkillArt: UIImage {
        return UIImage(named: "icon_skill_art")!
    }

    static var yep_iconSkillBall: UIImage {
        return UIImage(named: "icon_skill_ball")!
    }

    static var yep_iconSkillCategoryArrow: UIImage {
        return UIImage(named: "icon_skill_category_arrow")!
    }

    static var yep_iconSkillLife: UIImage {
        return UIImage(named: "icon_skill_life")!
    }

    static var yep_iconSkillMusic: UIImage {
        return UIImage(named: "icon_skill_music")!
    }

    static var yep_iconSkillTech: UIImage {
        return UIImage(named: "icon_skill_tech")!
    }

    static var yep_iconStars: UIImage {
        return UIImage(named: "icon_stars")!
    }

    static var yep_iconSubscribeClose: UIImage {
        return UIImage(named: "icon_subscribe_close")!
    }

    static var yep_iconSubscribeNotify: UIImage {
        return UIImage(named: "icon_subscribe_notify")!
    }

    static var yep_iconTopic: UIImage {
        return UIImage(named: "icon_topic")!
    }

    static var yep_iconTopicReddot: UIImage {
        return UIImage(named: "icon_topic_reddot")!
    }

    static var yep_iconTopicText: UIImage {
        return UIImage(named: "icon_topic_text")!
    }

    static var yep_iconVoiceLeft: UIImage {
        return UIImage(named: "icon_voice_left")!
    }

    static var yep_iconVoiceRight: UIImage {
        return UIImage(named: "icon_voice_right")!
    }

    static var yep_imageRectangleBorder: UIImage {
        return UIImage(named: "image_rectangle_border")!
    }

    static var yep_itemMic: UIImage {
        return UIImage(named: "item_mic")!
    }

    static var yep_itemMore: UIImage {
        return UIImage(named: "item_more")!
    }

    static var yep_leftTailBubble: UIImage {
        return UIImage(named: "left_tail_bubble")!
    }

    static var yep_leftTailImageBubble: UIImage {
        return UIImage(named: "left_tail_image_bubble")!
    }

    static var yep_leftTailImageBubbleBorder: UIImage {
        return UIImage(named: "left_tail_image_bubble_border")!
    }

    static var yep_locationBottomShadow: UIImage {
        return UIImage(named: "location_bottom_shadow")!
    }

    static var yep_minicardBubble: UIImage {
        return UIImage(named: "minicard_bubble")!
    }

    static var yep_minicardBubbleMore: UIImage {
        return UIImage(named: "minicard_bubble_more")!
    }

    static var yep_pickSkillsDismissBackground: UIImage {
        return UIImage(named: "pick_skills_dismiss_background")!
    }

    static var yep_profileAvatarFrame: UIImage {
        return UIImage(named: "profile_avatar_frame")!
    }

    static var yep_rightTailBubble: UIImage {
        return UIImage(named: "right_tail_bubble")!
    }

    static var yep_rightTailImageBubble: UIImage {
        return UIImage(named: "right_tail_image_bubble")!
    }

    static var yep_rightTailImageBubbleBorder: UIImage {
        return UIImage(named: "right_tail_image_bubble_border")!
    }
    
    static var yep_searchbarTextfieldBackground: UIImage {
        return UIImage(named: "searchbar_textfield_background")!
    }
    
    static var yep_shareFeedBubbleLeft: UIImage {
        return UIImage(named: "share_feed_bubble_left")!
    }
    
    static var yep_skillAdd: UIImage {
        return UIImage(named: "skill_add")!
    }
    
    static var yep_skillBubble: UIImage {
        return UIImage(named: "skill_bubble")!
    }
    
    static var yep_skillBubbleEmpty: UIImage {
        return UIImage(named: "skill_bubble_empty")!
    }
    
    static var yep_skillBubbleEmptyGray: UIImage {
        return UIImage(named: "skill_bubble_empty_gray")!
    }
    
    static var yep_skillBubbleLarge: UIImage {
        return UIImage(named: "skill_bubble_large")!
    }
    
    static var yep_skillBubbleLargeEmpty: UIImage {
        return UIImage(named: "skill_bubble_large_empty")!
    }
    
    static var yep_socialMediaImageMask: UIImage {
        return UIImage(named: "social_media_image_mask")!
    }
    
    static var yep_socialMediaImageMaskFull: UIImage {
        return UIImage(named: "social_media_image_mask_full")!
    }
    
    static var yep_socialWorkBorder: UIImage {
        return UIImage(named: "social_work_border")!
    }
    
    static var yep_socialWorkBorderLine: UIImage {
        return UIImage(named: "social_work_border_line")!
    }
    
    static var yep_swipeUp: UIImage {
        return UIImage(named: "swipe_up")!
    }
    
    static var yep_topShadow: UIImage {
        return UIImage(named: "top_shadow")!
    }
    
    static var yep_unreadRedDot: UIImage {
        return UIImage(named: "unread_red_dot")!
    }
    
    static var yep_urlContainerLeftBackground: UIImage {
        return UIImage(named: "url_container_left_background")!
    }
    
    static var yep_urlContainerRightBackground: UIImage {
        return UIImage(named: "url_container_right_background")!
    }
    
    static var yep_voiceIndicator: UIImage {
        return UIImage(named: "voice_indicator")!
    }
    
    static var yep_white: UIImage {
        return UIImage(named: "white")!
    }
    
    static var yep_yepIconSolo: UIImage {
        return UIImage(named: "yep_icon_solo")!
    }
}

// MARK: - Activities

extension UIImage {

    static var yep_wechatSession: UIImage {
        return UIImage(named: "wechat_session")!
    }

    static var yep_wechatTimeline: UIImage {
        return UIImage(named: "wechat_timeline")!
    }
}

// MARK: - Badges

extension UIImage {

    static var yep_badgeAndroid: UIImage {
        return UIImage(named: "badge_android")!
    }

    static var yep_badgeApple: UIImage {
        return UIImage(named: "badge_apple")!
    }

    static var yep_badgeBall: UIImage {
        return UIImage(named: "badge_ball")!
    }

    static var yep_badgeBubble: UIImage {
        return UIImage(named: "badge_bubble")!
    }

    static var yep_badgeCamera: UIImage {
        return UIImage(named: "badge_camera")!
    }

    static var yep_badgeGame: UIImage {
        return UIImage(named: "badge_game")!
    }

    static var yep_badgeHeart: UIImage {
        return UIImage(named: "badge_heart")!
    }

    static var yep_badgeMusic: UIImage {
        return UIImage(named: "badge_music")!
    }

    static var yep_badgePalette: UIImage {
        return UIImage(named: "badge_palette")!
    }

    static var yep_badgePet: UIImage {
        return UIImage(named: "badge_pet")!
    }

    static var yep_badgePlane: UIImage {
        return UIImage(named: "badge_plane")!
    }

    static var yep_badgeStar: UIImage {
        return UIImage(named: "badge_star")!
    }

    static var yep_badgeSteve: UIImage {
        return UIImage(named: "badge_steve")!
    }

    static var yep_badgeTech: UIImage {
        return UIImage(named: "badge_tech")!
    }
    
    static var yep_badgeWine: UIImage {
        return UIImage(named: "badge_wine")!
    }
    
    static var yep_enabledBadgeBackground: UIImage {
        return UIImage(named: "enabled_badge_background")!
    }
}

