//
//  SkillAddCell.swift
//  
//
//  Created by NIX on 15/6/23.
//
//

import UIKit
import YepKit

final class SkillAddCell: UICollectionViewCell {

    var skillSet: SkillSet = .master

    var addSkillsAction: ((SkillSet) -> ())?
}
