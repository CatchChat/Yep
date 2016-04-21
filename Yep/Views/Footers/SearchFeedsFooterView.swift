//
//  SearchFeedsFooterView.swift
//  Yep
//
//  Created by NIX on 16/4/21.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchFeedsFooterView: UIView {

    lazy var promptLabel: UILabel = {

        let label = UILabel()
        return label
    }()

    lazy var keywordLabelA: UILabel = {

        let label = UILabel()
        return label
    }()

    lazy var keywordLabelB: UILabel = {

        let label = UILabel()
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()
   }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeUI() {
        addSubview(promptLabel)
        addSubview(keywordLabelA)
        addSubview(keywordLabelB)

        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        keywordLabelA.translatesAutoresizingMaskIntoConstraints = false
        keywordLabelB.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "promptLabel": promptLabel,
            "keywordLabelA": keywordLabelA,
            "keywordLabelB": keywordLabelB,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[promptLabel]|", options: [], metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[promptLabel]-10-[keywordLabelA]-10-[keywordLabelB]|", options: [.AlignAllCenterX], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }
}

