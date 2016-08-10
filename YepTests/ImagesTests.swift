//
//  ImagesTests.swift
//  Yep
//
//  Created by NIX on 16/8/10.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

final class ImagesTests: XCTestCase {

    // ls -l | awk '{print $9}' | awk -F"." '{print $1}' | awk -F"_" '{out=$0" ";for(i=1;i<=NF;i++){if(i==1){out=out""tolower($i)}else{out=out""toupper(substr($i,1,1))substr($i,2)}};print out}' | awk '{print "UIImage.yep_"$2","}'

    func testImages() {

        // MARK: Images
        do {
            let images: [UIImage] = [
                UIImage.yep_bubbleBody,
                UIImage.yep_bubbleLeftTail,
                UIImage.yep_bubbleRightTail,
                UIImage.yep_buttonCameraRoll,
                UIImage.yep_buttonCapture,
                UIImage.yep_buttonCaptureOk,
                UIImage.yep_buttonSkillCategory,
                UIImage.yep_buttonVoicePause,
                UIImage.yep_buttonVoicePlay,
                UIImage.yep_buttonVoiceReset,
                UIImage.yep_chatSharetopicbubble,
                UIImage.yep_defaultAvatar,
                UIImage.yep_defaultAvatar30,
                UIImage.yep_defaultAvatar40,
                UIImage.yep_defaultAvatar60,
                UIImage.yep_feedAudioBubble,
                UIImage.yep_feedContainerBackground,
                UIImage.yep_feedMediaAdd,
                UIImage.yep_feedSkillChannelArrow,
                UIImage.yep_flatArrowDown,
                UIImage.yep_flatArrowLeft,
                UIImage.yep_gradientArt,
                UIImage.yep_gradientLife,
                UIImage.yep_gradientSport,
                UIImage.yep_gradientTech,
                UIImage.yep_iconAccessory,
                UIImage.yep_iconAccessoryMini,
                UIImage.yep_iconArrowDown,
                UIImage.yep_iconArrowUp,
                UIImage.yep_iconBack,
                UIImage.yep_iconBlog,
                UIImage.yep_iconChat,
                UIImage.yep_iconChatActive,
                UIImage.yep_iconChatActiveUnread,
                UIImage.yep_iconChatUnread,
                UIImage.yep_iconContact,
                UIImage.yep_iconContactActive,
                UIImage.yep_iconCurrentLocation,
                UIImage.yep_iconDiscussion,
                UIImage.yep_iconDotFailed,
                UIImage.yep_iconDotSending,
                UIImage.yep_iconDotUnread,
                UIImage.yep_iconDribbble,
                UIImage.yep_iconExplore,
                UIImage.yep_iconExploreActive,
                UIImage.yep_iconFeedText,
                UIImage.yep_iconFeeds,
                UIImage.yep_iconFeedsActive,
                UIImage.yep_iconGhost,
                UIImage.yep_iconGithub,
                UIImage.yep_iconImagepickerCheck,
                UIImage.yep_iconInstagram,
                UIImage.yep_iconKeyboard,
                UIImage.yep_iconLink,
                UIImage.yep_iconList,
                UIImage.yep_iconLocation,
                UIImage.yep_iconLocationCheckmark,
                UIImage.yep_iconMe,
                UIImage.yep_iconMeActive,
                UIImage.yep_iconMediaDelete,
                UIImage.yep_iconMinicard,
                UIImage.yep_iconMore,
                UIImage.yep_iconMoreImage,
                UIImage.yep_iconPause,
                UIImage.yep_iconPin,
                UIImage.yep_iconPinMiniGray,
                UIImage.yep_iconPinShadow,
                UIImage.yep_iconPlay,
                UIImage.yep_iconPlayvideo,
                UIImage.yep_iconProfilePhone,
                UIImage.yep_iconQuickCamera,
                UIImage.yep_iconRemove,
                UIImage.yep_iconRepo,
                UIImage.yep_iconSettings,
                UIImage.yep_iconShare,
                UIImage.yep_iconSkillArt,
                UIImage.yep_iconSkillBall,
                UIImage.yep_iconSkillCategoryArrow,
                UIImage.yep_iconSkillLife,
                UIImage.yep_iconSkillMusic,
                UIImage.yep_iconSkillTech,
                UIImage.yep_iconStars,
                UIImage.yep_iconSubscribeClose,
                UIImage.yep_iconSubscribeNotify,
                UIImage.yep_iconTopic,
                UIImage.yep_iconTopicReddot,
                UIImage.yep_iconTopicText,
                UIImage.yep_iconVoiceLeft,
                UIImage.yep_iconVoiceRight,
                UIImage.yep_imageRectangleBorder,
                UIImage.yep_itemMic,
                UIImage.yep_itemMore,
                UIImage.yep_leftTailBubble,
                UIImage.yep_leftTailImageBubble,
                UIImage.yep_leftTailImageBubbleBorder,
                UIImage.yep_locationBottomShadow,
                UIImage.yep_minicardBubble,
                UIImage.yep_minicardBubbleMore,
                UIImage.yep_pickSkillsDismissBackground,
                UIImage.yep_profileAvatarFrame,
                UIImage.yep_rightTailBubble,
                UIImage.yep_rightTailImageBubble,
                UIImage.yep_rightTailImageBubbleBorder,
                UIImage.yep_searchbarTextfieldBackground,
                UIImage.yep_shareFeedBubbleLeft,
                UIImage.yep_skillAdd,
                UIImage.yep_skillBubble,
                UIImage.yep_skillBubbleEmpty,
                UIImage.yep_skillBubbleEmptyGray,
                UIImage.yep_skillBubbleLarge,
                UIImage.yep_skillBubbleLargeEmpty,
                UIImage.yep_socialMediaImageMask,
                UIImage.yep_socialMediaImageMaskFull,
                UIImage.yep_socialWorkBorder,
                UIImage.yep_socialWorkBorderLine,
                UIImage.yep_swipeUp,
                UIImage.yep_topShadow,
                UIImage.yep_unreadRedDot,
                UIImage.yep_urlContainerLeftBackground,
                UIImage.yep_urlContainerRightBackground,
                UIImage.yep_voiceIndicator,
                UIImage.yep_white,
                UIImage.yep_yepIconSolo,
            ]

            print("Images: \(images.count)")
        }

        // MARK: Activities
        do {
            let images: [UIImage] = [
                UIImage.yep_wechatSession,
                UIImage.yep_wechatTimeline,
            ]

            print("Activities: \(images.count)")
        }

        // MARK: Badges
        do {
            let images: [UIImage] = [
                UIImage.yep_badgeAndroid,
                UIImage.yep_badgeApple,
                UIImage.yep_badgeBall,
                UIImage.yep_badgeBubble,
                UIImage.yep_badgeCamera,
                UIImage.yep_badgeGame,
                UIImage.yep_badgeHeart,
                UIImage.yep_badgeMusic,
                UIImage.yep_badgePalette,
                UIImage.yep_badgePet,
                UIImage.yep_badgePlane,
                UIImage.yep_badgeStar,
                UIImage.yep_badgeSteve,
                UIImage.yep_badgeTech,
                UIImage.yep_badgeWine,
                UIImage.yep_enabledBadgeBackground,
            ]

            print("Badges: \(images.count)")
        }
    }
}

