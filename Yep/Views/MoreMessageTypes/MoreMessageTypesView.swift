//
//  MoreMessageTypesView.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import YepKit

final class MoreMessageTypesView: UIView {

    let totalHeight: CGFloat = 100 + 60 * 3

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    lazy var tableView: UITableView = {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 60
        view.isScrollEnabled = false

        view.registerNibOf(TitleCell)
        view.registerNibOf(QuickPickPhotosCell)

        return view
    }()

    var alertCanNotAccessCameraRollAction: (() -> Void)?
    var takePhotoAction: (() -> Void)?
    var choosePhotoAction: (() -> Void)?
    var pickLocationAction: (() -> Void)?
    var sendImageAction: ((UIImage) -> Void)?

    var quickPickedImageSet = Set<PHAsset>() {
        didSet {
            tableView.reloadRows(at: [IndexPath(row: Row.pickPhotos.rawValue, section: 0)], with: .none)
        }
    }

    var tableViewBottomConstraint: NSLayoutConstraint?

    func showInView(_ view: UIView) {

        frame = view.bounds

        view.addSubview(self)

        layoutIfNeeded()

        containerView.alpha = 1

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
            self?.containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }, completion: nil)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: { [weak self] in
            self?.tableViewBottomConstraint?.constant = 0
            self?.layoutIfNeeded()
        }, completion: nil)
    }

    func hide() {

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.tableViewBottomConstraint?.constant = strongSelf.totalHeight
            strongSelf.layoutIfNeeded()
        }, completion: nil)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: { [weak self] in
            self?.containerView.backgroundColor = UIColor.clear

        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }

    func hideAndDo(_ afterHideAction: (() -> Void)?) {

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.containerView.alpha = 0
            strongSelf.tableViewBottomConstraint?.constant = strongSelf.totalHeight
            strongSelf.layoutIfNeeded()

        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })

        delay(0.1) {
            afterHideAction?()
        }
    }

    var isFirstTimeBeenAddAsSubview = true

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false

            makeUI()

            let tap = UITapGestureRecognizer(target: self, action: #selector(MoreMessageTypesView.hide))
            containerView.addGestureRecognizer(tap)

            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }

    func makeUI() {

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary: [String: AnyObject] = [
            "containerView": containerView,
            "tableView": tableView,
        ]

        // layout for containerView

        let containerViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: [], metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activate(containerViewConstraintsH)
        NSLayoutConstraint.activate(containerViewConstraintsV)

        // layout for tableView

        let tableViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: viewsDictionary)

        let tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: self.totalHeight)

        self.tableViewBottomConstraint = tableViewBottomConstraint
        
        let tableViewHeightConstraint = NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.totalHeight)
        
        NSLayoutConstraint.activate(tableViewConstraintsH)
        NSLayoutConstraint.activate([tableViewBottomConstraint, tableViewHeightConstraint])
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MoreMessageTypesView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        if touch.view != containerView {
            return false
        }

        return true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension MoreMessageTypesView: UITableViewDataSource, UITableViewDelegate {

    enum Row: Int {

        case photoGallery = 0
        case pickPhotos
        case location
        case cancel

        var normalTitle: String {
            switch self {
            case .photoGallery:
                return ""
            case .pickPhotos:
                return String.trans_titlePickPhotos
            case .location:
                return String.trans_titleLocation
            case .cancel:
                return String.trans_cancel
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let row = Row(rawValue: (indexPath as NSIndexPath).row) {

            if case .photoGallery = row {

                let cell: QuickPickPhotosCell = tableView.dequeueReusableCell()

                cell.alertCanNotAccessCameraRollAction = { [weak self] in
                    self?.alertCanNotAccessCameraRollAction?()
                }

                cell.takePhotoAction = { [weak self] in
                    self?.hideAndDo {
                        self?.takePhotoAction?()
                    }
                }

                cell.pickedPhotosAction = { [weak self] pickedImageSet in
                    self?.quickPickedImageSet = pickedImageSet
                }

                return cell

            } else {
                let cell: TitleCell = tableView.dequeueReusableCell()

                cell.singleTitleLabel.text = row.normalTitle
                cell.boldEnabled = false
                cell.singleTitleLabel.textColor = UIColor.yepTintColor()

                if case .pickPhotos = row {
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let row = Row(rawValue: (indexPath as NSIndexPath).row) {
            if case .photoGallery = row {
                return 100

            } else {
                return 60
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        if let row = Row(rawValue: (indexPath as NSIndexPath).row) {
            switch row {

            case .pickPhotos:
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

                        imageManager.requestImageData(for: imageAsset, options: options, resultHandler: { (data, String, imageOrientation, _) -> Void in
                            if let data = data, let image = UIImage(data: data) {
                                if let image = image.resizeToSize(targetSize, withInterpolationQuality: .Medium) {
                                    images.append(image)
                                }
                            }
                        })
                    }
                    
                    for (index, image) in images.enumerated() {
                        delay(0.1*Double(index), work: { [weak self] in
                            self?.sendImageAction?(image)
                        })
                    }

                    // clean UI
                    
                    quickPickedImageSet.removeAll()

                    hideAndDo {
                        if let cell = tableView.cellForRow(at: IndexPath(row: Row.photoGallery.rawValue, section: 0)) as? QuickPickPhotosCell {
                            cell.pickedImageSet.removeAll()
                            cell.photosCollectionView.reloadData()
                        }
                    }

                } else {
                    hideAndDo { [weak self] in
                        self?.choosePhotoAction?()
                    }
                }

            case .location:
                hideAndDo { [weak self] in
                    self?.pickLocationAction?()
                }

            case .cancel:
                hide()

            default:
                break
            }
        }
    }
}

