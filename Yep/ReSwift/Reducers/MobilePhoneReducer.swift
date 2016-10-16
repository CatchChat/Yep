//
//  MobilePhoneReducer.swift
//  Yep
//
//  Created by NIX on 16/8/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import ReSwift

struct MobilePhoneReducer: Reducer {

    typealias ReducerStateType = AppState

    func handleAction(action: Action, state: ReducerStateType?) -> ReducerStateType {

        var state = state ?? AppState()

        switch action {

        case let x as MobilePhoneUpdateAction:
            state.mobilePhone = x.mobilePhone

        default:
            break
        }

        return state
    }
}

