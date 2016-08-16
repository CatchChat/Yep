//
//  RealmConfig.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

public func realmConfig() -> Realm.Configuration {

    // 默认将 Realm 放在 App Group 里

    let directory: NSURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(Config.appGroupID)!
    let realmFileURL = directory.URLByAppendingPathComponent("db.realm")

    var config = Realm.Configuration()
    config.fileURL = realmFileURL
    config.schemaVersion = 34
    config.migrationBlock = { migration, oldSchemaVersion in
    }

    return config
}

