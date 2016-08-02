//
//  AlbumListCell.swift
//  Yep
//
//  Created by ChaiYixiao on 4/12/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

final class AlbumListCell: UITableViewCell {

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func prepareForReuse() {
         super.prepareForReuse()
        countLabel.text = nil
        titleLabel.text = nil
        posterImageView.image = nil
    }
}
 
