//
//  MobilePhone.swift
//  Yep
//
//  Created by NIX on 16/8/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

struct MobilePhone {

    let areaCode: String
    let number: String

    var fullNumber: String {
        return "+" + areaCode + " " + number
    }
}

