//
//  UserAvatar.swift
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

    var URL: Foundation.URL? {
        return Foundation.URL(string: avatarURLString)
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

        default:
            return nil
        }
    }

    var localOriginalImage: UIImage? {

        if let user = user, let avatar = user.avatar , avatar.avatarURLString == user.avatarURLString {

            if
                let avatarFileURL = FileManager.yepAvatarURLWithName(avatar.avatarFileName),
                let image = UIImage(contentsOfFile: avatarFileURL.path) {
                    return image
            }
        }

        return nil
    }

    var localStyledImage: UIImage? {

        switch style {

        case miniAvatarStyle:
            if let user = user, let avatar = user.avatar , avatar.avatarURLString == user.avatarURLString {
                return UIImage(data: avatar.roundMini, scale: screenScale)
            }

        case nanoAvatarStyle:
            if let user = user, let avatar = user.avatar , avatar.avatarURLString == user.avatarURLString {
                return UIImage(data: avatar.roundNano, scale: screenScale)
            }

        default:
            break
        }

        return nil
    }

    func saveOriginalImage(_ originalImage: UIImage, styledImage: UIImage) {

        guard let user = user, let realm = user.realm else {
            return
        }

        var needNewAvatar = false

        if user.avatar == nil {
            needNewAvatar = true
        }

        if let oldAvatar = user.avatar , oldAvatar.avatarURLString != user.avatarURLString {

            FileManager.deleteAvatarImageWithName(oldAvatar.avatarFileName)

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
}

