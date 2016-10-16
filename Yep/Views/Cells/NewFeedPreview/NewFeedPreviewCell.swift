//
//  NewFeedPreviewCell.swift
//  Yep
//
//  Created by ChaiYixiao on 4/8/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

final class NewFeedPreviewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!

    let minScale: CGFloat = 1.0
    let maxScale: CGFloat = 3.0
    
    override func awakeFromNib() {
        super.awakeFromNib()

        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = true
        scrollView.contentSize = image.bounds.size
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        
        let doubleClickGesture = UITapGestureRecognizer(target: self, action: #selector(NewFeedPreviewCell.doubleClick(_:)))
        doubleClickGesture.numberOfTapsRequired = 2
        image.addGestureRecognizer(doubleClickGesture)
    }
    
    @objc func doubleClick(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale != scrollView.maximumZoomScale {
            scrollView.yep_zoomToPoint(sender.location(in: self.contentView), withScale: scrollView.maximumZoomScale, animated: true)
            
        } else {
            scrollView.yep_zoomToPoint(sender.location(in: self.contentView), withScale: scrollView.minimumZoomScale, animated: true)
        }
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        scrollView.zoomScale = 1.0
    }

}

extension NewFeedPreviewCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return image
    }
}

extension NewFeedPreviewCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
