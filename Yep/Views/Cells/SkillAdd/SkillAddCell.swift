//
//  SkillAddCell.swift
//  
//
//  Created by NIX on 15/6/23.
//
//

import UIKit

class SkillAddCell: UICollectionViewCell {

    enum SkillSetType: Int {
        case Master
        case Learning
    }

    var skillSetType: SkillSetType = .Master

    var addSkillsAction: ((SkillSetType) -> ())?
}
