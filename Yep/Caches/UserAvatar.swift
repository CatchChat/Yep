//
//  UserAvatar.swift
//  Yep
//
//  Created by nixzhu on 15/10/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import Navi

private let screenScale = UIScreen.mainScreen().scale

struct UserAvatar {

    let userID: String
    let avatarURLString: String
    let avatarStyle: AvatarStyle

    var user: User? {

        guard let realm = try? Realm() else {
            return nil
        }

        return userWithUserID(userID, inRealm: realm)
    }
}

extension UserAvatar: Navi.Avatar {

    var URL: NSURL? {
        return NSURL(string: avatarURLString)
    }

    var style: AvatarStyle {
        return avatarStyle
    }

    var placeholderImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            return UIImage(named: "default_avatar_60")

        case nanoAvatarStyle:
            return UIImage(named: "default_avatar_40")

        default:
            return nil
        }
    }

    var localOriginalImage: UIImage? {

        if let user = user, avatar = user.avatar where avatar.avatarURLString == user.avatarURLString {

            if let
                avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
                avatarFilePath = avatarFileURL.path,
                image = UIImage(contentsOfFile: avatarFilePath) {
                    return image
            }
        }

        return nil
    }

    var localStyledImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            if let user = user, avatar = user.avatar where avatar.avatarURLString == user.avatarURLString {
                return UIImage(data: avatar.roundMini, scale: screenScale)
            }

        case nanoAvatarStyle:
            if let user = user, avatar = user.avatar where avatar.avatarURLString == user.avatarURLString {
                return UIImage(data: avatar.roundNano, scale: screenScale)
            }

        default:
            break
        }

        return nil
    }

    func saveOriginalImage(originalImage: UIImage, styledImage: UIImage) {

        guard let user = user, realm = user.realm else {
            return
        }

        var needNewAvatar = false

        if user.avatar == nil {
            needNewAvatar = true
        }

        if let oldAvatar = user.avatar where oldAvatar.avatarURLString != user.avatarURLString {

            NSFileManager.deleteAvatarImageWithName(oldAvatar.avatarFileName)

            let _ = try? realm.write {
                realm.delete(oldAvatar)
            }

            needNewAvatar = true
        }

        if needNewAvatar {

            let _avatar = avatarWithAvatarURLString(user.avatarURLString, inRealm: realm)

            if _avatar == nil {

                let newAvatar = Avatar()
                newAvatar.avatarURLString = user.avatarURLString

                let _ = try? realm.write {
                    user.avatar = newAvatar
                }

            } else {
                let _ = try? realm.write {
                    user.avatar = _avatar
                }
            }
        }

        if let avatar = user.avatar {

            let avatarFileName = NSUUID().UUIDString

            if avatar.avatarFileName.isEmpty, let _ = NSFileManager.saveAvatarImage(originalImage, withName: avatarFileName) {

                let _ = try? realm.write {
                    avatar.avatarFileName = avatarFileName
                }
            }

            switch style {

            case .RoundedRectangle(let size, _, _):

                switch size.width {

                case 60:
                    if avatar.roundMini.length == 0, let data = UIImagePNGRepresentation(styledImage) {
                        let _ = try? realm.write {
                            avatar.roundMini = data
                        }
                    }

                case 40:
                    if avatar.roundNano.length == 0, let data = UIImagePNGRepresentation(styledImage) {
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
}

