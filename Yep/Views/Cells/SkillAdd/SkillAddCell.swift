//
//  SkillAddCell.swift
//  
//
//  Created by NIX on 15/6/23.
//
//

import UIKit

final class SkillAddCell: UICollectionViewCell {

    var skillSet: SkillSet = .Master

    var addSkillsAction: (SkillSet -> ())?
}
