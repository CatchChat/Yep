//
//  PhoneNumberRepresentation.swift
//  Yep
//
//  Created by NIX on 16/7/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

protocol PhoneNumberRepresentation: class {

    var areaCodeTextField: BorderTextField! { get }
    var mobileNumberTextField: BorderTextField! { get }
    
    func adjustAreaCodeTextFieldWidth()
}

