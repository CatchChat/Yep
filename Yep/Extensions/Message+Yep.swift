//
//  Message+Yep.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

private let sectionDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

private let sectionDateInCurrentWeekFormatter: DateFormatter =  {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE HH:mm"
    return dateFormatter
}()

extension Message {

    var sectionDateString: String {
        let createdAt = Date(timeIntervalSince1970: createdUnixTime)
        if createdAt.yep_isInWeekend {
            return sectionDateInCurrentWeekFormatter.string(from: createdAt)
        } else {
            return sectionDateFormatter.string(from: createdAt)
        }
    }
}

extension Message {

    var fixedImageSize: CGSize {

        let imagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
        let imagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
        let imagePreferredAspectRatio: CGFloat = 4.0 / 3.0

        if let (imageWidth, imageHeight) = imageMetaOfMessage(self) {

            let aspectRatio = imageWidth / imageHeight

            let realImagePreferredWidth = max(imagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let realImagePreferredHeight = max(imagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {
                var size = CGSize(width: realImagePreferredWidth, height: ceil(realImagePreferredWidth / aspectRatio))
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinWidth)

                return size

            } else {
                var size = CGSize(width: realImagePreferredHeight * aspectRatio, height: realImagePreferredHeight)
                size = size.yep_ensureMinWidthOrHeight(YepConfig.ChatCell.mediaMinHeight)

                return size
            }

        } else {
            let size = CGSize(width: imagePreferredWidth, height: ceil(imagePreferredWidth / imagePreferredAspectRatio))
            
            return size
        }
    }
}

extension Message {

    var fixedVideoSize: CGSize {

        let imagePreferredWidth = YepConfig.ChatCell.mediaPreferredWidth
        let imagePreferredHeight = YepConfig.ChatCell.mediaPreferredHeight
        let imagePreferredAspectRatio: CGFloat = 4.0 / 3.0

        if let (videoWidth, videoHeight) = videoMetaOfMessage(self) {

            let aspectRatio = videoWidth / videoHeight

            let realImagePreferredWidth = max(imagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
            let realImagePreferredHeight = max(imagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))

            if aspectRatio >= 1 {
                let size = CGSize(width: realImagePreferredWidth, height: ceil(realImagePreferredWidth / aspectRatio))
                return size

            } else {
                let size = CGSize(width: realImagePreferredHeight * aspectRatio, height: realImagePreferredHeight)
                return size
            }

        } else {
            let size = CGSize(width: imagePreferredWidth, height: ceil(imagePreferredWidth / imagePreferredAspectRatio))
            
            return size
        }
    }
}
