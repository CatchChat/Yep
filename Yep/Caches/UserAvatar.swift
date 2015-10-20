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

let miniAvatarStyle: AvatarStyle = .RoundedRectangle(size: CGSize(width: 60, height: 60), cornerRadius: 30, borderWidth: 0)
let nanoAvatarStyle: AvatarStyle = .RoundedRectangle(size: CGSize(width: 40, height: 40), cornerRadius: 20, borderWidth: 0)

struct UserAvatar {

    let userID: String
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

        if let avatarURLString = user?.avatarURLString {
            return NSURL(string: avatarURLString)
        }

        return nil
    }

    var style: AvatarStyle {
        return avatarStyle
    }

    var placeholderImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            return UIImage(named: "default_avatar")

        case nanoAvatarStyle:
            return UIImage(named: "default_avatar")

        default:
            return nil
        }
    }

    var localOriginalImage: UIImage? {

        if let
            avatar = user?.avatar,
            avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
            avatarFilePath = avatarFileURL.path,
            image = UIImage(contentsOfFile: avatarFilePath) {
                return image
        }

        return nil
    }

    var localStyledImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            if let data = user?.avatar?.roundMini {
                return UIImage(data: data, scale: screenScale)
            }

        case nanoAvatarStyle:
            if let data = user?.avatar?.roundNano {
                return UIImage(data: data, scale: screenScale)
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

        if user.avatar == nil {

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

            let avatarURLString = user.avatarURLString
            if avatar.avatarFileName.isEmpty, let _ = NSFileManager.saveAvatarImage(originalImage, withName: avatarFileName) {

                let _ = try? realm.write {
                    avatar.avatarURLString = avatarURLString
                    avatar.avatarFileName = avatarFileName
                }
            }

            switch style {

            case .RoundedRectangle(let size, _, _):

                switch size.width {

                case 60:
                    if avatar.roundMini.length == 0, let data = UIImageJPEGRepresentation(styledImage, 1) {
                        let _ = try? realm.write {
                            avatar.roundMini = data
                        }
                    }

                case 40:
                    if avatar.roundNano.length == 0, let data = UIImageJPEGRepresentation(styledImage, 1) {
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

