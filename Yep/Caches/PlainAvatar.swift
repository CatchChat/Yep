//
//  PlainAvatar.swift
//  Yep
//
//  Created by nixzhu on 15/10/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import Navi

private let screenScale = UIScreen.main.scale

struct PlainAvatar {

    let avatarURLString: String
    let avatarStyle: AvatarStyle
}

extension PlainAvatar: Navi.Avatar {

    var url: URL? {
        return URL(string: avatarURLString)
    }

    var style: AvatarStyle {
        return avatarStyle
    }

    var placeholderImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            return UIImage.yep_defaultAvatar60

        case nanoAvatarStyle:
            return UIImage.yep_defaultAvatar40

        case picoAvatarStyle:
            return UIImage.yep_defaultAvatar30

        default:
            return nil
        }
    }

    var localOriginalImage: UIImage? {

        if
            let realm = try? Realm(),
            let avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm),
            let avatarFileURL = FileManager.yepAvatarURLWithName(avatar.avatarFileName),
            let image = UIImage(contentsOfFile: avatarFileURL.path) {
                return image
        }

        return nil
    }

    var localStyledImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            if let
                realm = try? Realm(),
                let avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm) {
                    return UIImage(data: avatar.roundMini, scale: screenScale)
            }

        case nanoAvatarStyle:
            if let
                realm = try? Realm(),
                let avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm) {
                    return UIImage(data: avatar.roundNano, scale: screenScale)
            }

        default:
            break
        }

        return nil
    }

    func save(originalImage: UIImage, styledImage: UIImage) {

        guard let realm = try? Realm() else {
            return
        }

        var _avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm)

        if _avatar == nil {

            let newAvatar = Avatar()
            newAvatar.avatarURLString = avatarURLString

            let _ = try? realm.write {
                realm.add(newAvatar)
            }

            _avatar = newAvatar
        }

        guard let avatar = _avatar else {
            return
        }

        let avatarFileName = UUID().uuidString

        if avatar.avatarFileName.isEmpty, let _ = FileManager.saveAvatarImage(originalImage, withName: avatarFileName) {

            let _ = try? realm.write {
                avatar.avatarFileName = avatarFileName
            }
        }

        switch style {

        case .roundedRectangle(let size, _, _):

            switch size.width {

            case 60:
                if avatar.roundMini.count == 0, let data = UIImagePNGRepresentation(styledImage) {
                    let _ = try? realm.write {
                        avatar.roundMini = data
                    }
                }

            case 40:
                if avatar.roundNano.count == 0, let data = UIImagePNGRepresentation(styledImage) {
                    let _ = try? realm.write {
                        avatar.roundNano = data
                    }
                }

            default:
                break
            }

        default:
            break
        }
    }
}

