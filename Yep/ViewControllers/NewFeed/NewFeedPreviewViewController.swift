//
//  NewFeedPreviewViewController.swift
//  Yep
//
//  Created by ChaiYixiao on 4/8/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
private let screenHeight: CGFloat = UIScreen.mainScreen().bounds.height

class NewFeedPreviewViewController: UIViewController {

    @IBOutlet weak var previewCollectionView: UICollectionView!
    
    var previewImages = [UIImage]()
    var startIndex: Int = 0
    var imagesLimit: Int = 0
    private let previewCellID = "NewFeedPreviewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewCollectionView.registerNib(UINib(nibName: previewCellID, bundle: nil), forCellWithReuseIdentifier: previewCellID)
        previewCollectionView.pagingEnabled = true
        previewCollectionView.showsHorizontalScrollIndicator = false
        self.automaticallyAdjustsScrollViewInsets = false
        
        title = "\(startIndex + 1)/\(imagesLimit)"
        
    }

    override func viewDidLayoutSubviews() {
        previewCollectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: startIndex, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension NewFeedPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
         return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(previewCellID, forIndexPath: indexPath) as! NewFeedPreviewCell
        cell.image.image = previewImages[indexPath.item]
        title = "\(indexPath.item + 1)/\(imagesLimit)"
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        return CGSize(width: screenWidth, height: screenHeight - topBarsHeight)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

}
