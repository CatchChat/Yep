//
//  SharedStore.swift
//  Yep
//
//  Created by NIX on 16/8/31.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import ReSwift

final private class SharedStore {

    static let shared = SharedStore()

    lazy var store: Store<AppState> = {
        return Store<AppState>(
            reducer: MobilePhoneReducer(),
            state: nil
        )
    }()

    private init() {}
}

func sharedStore() -> Store<AppState> {
    return SharedStore.shared.store
}

