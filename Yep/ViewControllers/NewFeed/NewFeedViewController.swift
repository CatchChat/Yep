//
//  NewFeedViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Proposer
import CoreLocation

class NewFeedViewController: UIViewController {

    var afterCreatedFeedAction: (() -> Void)?

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mediaCollectionView: UICollectionView!

    let feedMediaAddCellID = "FeedMediaAddCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Feed", comment: "")

        let postButton = UIBarButtonItem(title: NSLocalizedString("Post", comment: ""), style: .Plain, target: self, action: "post:")

        navigationItem.rightBarButtonItem = postButton

        messageTextView.text = "What's up?"

        messageTextView.backgroundColor = UIColor.lightGrayColor()
        //mediaCollectionView.backgroundColor = UIColor.blueColor()

        mediaCollectionView.registerNib(UINib(nibName: feedMediaAddCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaAddCellID)
        mediaCollectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        mediaCollectionView.contentInset.left = 20
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        // try turn on location

        let locationResource = PrivateResource.Location(.WhenInUse)

        if locationResource.isNotDeterminedAuthorization {

            proposeToAccess(.Location(.WhenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
                self.alertCanNotAccessLocation()
            })

        } else {
            proposeToAccess(.Location(.WhenInUse), agreed: {

                YepLocationService.turnOn()

            }, rejected: {
            })
        }
    }

    // MARK: Actions

    func post(sender: UIBarButtonItem) {

        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate

        createFeedWithMessage(messageTextView.text, attachments: nil, coordinate: coordinate, skill: nil, allowComment: true, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason, errorMessage: errorMessage)

            YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Create feed failed!", comment: ""), inViewController: self)

        }, completion: { data in
            println(data)

            dispatch_async(dispatch_get_main_queue()) { [weak self] in

                self?.afterCreatedFeedAction?()

                self?.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
}

extension NewFeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {
        case 0:
            return 1
        case 1:
            return 3
        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case 0:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaAddCellID, forIndexPath: indexPath) as! FeedMediaAddCell
            cell.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            cell.backgroundColor = UIColor.greenColor()
            return cell

        default:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            return cell
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
}
