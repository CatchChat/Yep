//
//  MoreMessageTypesView.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos

class MoreMessageTypesView: UIView {

    let totalHeight: CGFloat = 100 + 60 * 3

    let titleCellID = "TitleCell"
    let quickPickPhotosCellID = "QuickPickPhotosCell"

    lazy var tableView: UITableView = {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 60
        view.backgroundColor = UIColor.whiteColor()
        view.scrollEnabled = false
        view.registerNib(UINib(nibName: self.quickPickPhotosCellID, bundle: nil), forCellReuseIdentifier: self.quickPickPhotosCellID)
        view.registerNib(UINib(nibName: self.titleCellID, bundle: nil), forCellReuseIdentifier: self.titleCellID)
        return view
    }()

    var alertCanNotAccessCameraRollAction: (() -> Void)?
    var takePhotoAction: (() -> Void)?
    var choosePhotoAction: (() -> Void)?
    var pickLocationAction: (() -> Void)?
    var sendImageAction: (UIImage -> Void)?
    var hide: (() -> Void)?
    
    var quickPickedImageSet = Set<PHAsset>() {
        didSet {
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: Row.PickPhotos.rawValue, inSection: 0)], withRowAnimation: .None)
        }
    }

    var tableViewBottomConstraint: NSLayoutConstraint?

    func showInView(view: UIView) {

        frame = view.bounds

        view.addSubview(self)

        layoutIfNeeded()

        tableView.separatorColor = UIColor.yepCellSeparatorColor()
        alpha = 1
        layoutIfNeeded()
    }

    func delayAndDo(afterDelayAction: (() -> Void)?) {

        delay(0.1) {
            afterDelayAction?()
        }
    }

    var isFirstTimeBeenAddAsSubview = true

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false

            makeUI()
        }
    }
    func makeUI() {

        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: add constraint
        
        let tableViewLeading = NSLayoutConstraint(item: tableView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        let tableViewTop = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([tableViewLeading, tableViewTop])
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension MoreMessageTypesView: UITableViewDataSource, UITableViewDelegate {

    enum Row: Int {

        case PhotoGallery = 0
        case PickPhotos
        case Location
        case Cancel

        var normalTitle: String {
            switch self {
            case .PhotoGallery:
                return ""
            case .PickPhotos:
                return NSLocalizedString("Pick Photos", comment: "")
            case .Location:
                return NSLocalizedString("Location", comment: "")
            case .Cancel:
                return NSLocalizedString("Cancel", comment: "")
            }
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let row = Row(rawValue: indexPath.row) {
            if case .PhotoGallery = row {
                let cell = tableView.dequeueReusableCellWithIdentifier(quickPickPhotosCellID) as! QuickPickPhotosCell

                cell.alertCanNotAccessCameraRollAction = { [weak self] in
                    self?.alertCanNotAccessCameraRollAction?()
                }

                cell.takePhotoAction = { [weak self] in
                    self?.delayAndDo {
                        self?.takePhotoAction?()
                    }
                }

                cell.pickedPhotosAction = { [weak self] pickedImageSet in
                    self?.quickPickedImageSet = pickedImageSet
                }

                return cell

            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier(titleCellID) as! TitleCell
                cell.singleTitleLabel.text = row.normalTitle
                cell.boldEnabled = false
                cell.singleTitleLabel.textColor = UIColor.yepTintColor()

                if case .PickPhotos = row {
                    if !quickPickedImageSet.isEmpty {
                        cell.singleTitleLabel.text = String(format: NSLocalizedString("Send Photos (%d)", comment: ""), quickPickedImageSet.count)
                        cell.boldEnabled = true
                    }
                }

                return cell
            }
        }
        
        return UITableViewCell()
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let row = Row(rawValue: indexPath.row) {
            if case .PhotoGallery = row {
                return 100

            } else {
                return 60
            }
        }

        return 0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            hide?()
        }

        if let row = Row(rawValue: indexPath.row) {
            switch row {

            case .PickPhotos:
                if !quickPickedImageSet.isEmpty {

                    var images = [UIImage]()

                    let options = PHImageRequestOptions.yep_sharedOptions

                    let imageManager = PHCachingImageManager()
                    for imageAsset in quickPickedImageSet {

                        let maxSize: CGFloat = 1024

                        let pixelWidth = CGFloat(imageAsset.pixelWidth)
                        let pixelHeight = CGFloat(imageAsset.pixelHeight)

                        //println("pixelWidth: \(pixelWidth)")
                        //println("pixelHeight: \(pixelHeight)")

                        let targetSize: CGSize

                        if pixelWidth > pixelHeight {
                            let width = maxSize
                            let height = floor(maxSize * (pixelHeight / pixelWidth))
                            targetSize = CGSize(width: width, height: height)

                        } else {
                            let height = maxSize
                            let width = floor(maxSize * (pixelWidth / pixelHeight))
                            targetSize = CGSize(width: width, height: height)
                        }
                        
                        //println("targetSize: \(targetSize)")

                        imageManager.requestImageDataForAsset(imageAsset, options: options, resultHandler: { (data, String, imageOrientation, _) -> Void in
                            if let data = data, image = UIImage(data: data) {
                                if let image = image.resizeToSize(targetSize, withInterpolationQuality: .Medium) {
                                    images.append(image)
                                }
                            }
                        })
                    }
                    
                    for (index, image) in images.enumerate() {
                        delay(0.1*Double(index), work: { [weak self] in
                            self?.sendImageAction?(image)
                        })
                    }

                    // clean UI
                    
                    quickPickedImageSet.removeAll()

                    delayAndDo {
                        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: Row.PhotoGallery.rawValue, inSection: 0)) as? QuickPickPhotosCell {
                            cell.pickedImageSet.removeAll()
                            cell.photosCollectionView.reloadData()
                        }
                    }

                } else {
                    delayAndDo { [weak self] in
                        self?.choosePhotoAction?()
                    }
                }

            case .Location:
                delayAndDo { [weak self] in
                    self?.pickLocationAction?()
                }

            case .Cancel:
                hide?()

            default:
                break
            }
        }
    }
}

