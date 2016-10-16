//
//  VoiceRecordSampleView.swift
//  Yep
//
//  Created by nixzhu on 15/11/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class VoiceRecordSampleCell: UICollectionViewCell {

    var value: CGFloat = 0 {
        didSet {
            if value != oldValue {
                setNeedsDisplay()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {

        let context = UIGraphicsGetCurrentContext()

        context!.setStrokeColor(UIColor(red: 171/255.0, green: 181/255.0, blue: 190/255.0, alpha: 1).cgColor)
        context!.setLineWidth(bounds.width)
        context!.setLineCap(.round)

        let x = bounds.width / 2
        let height = bounds.height
        let valueHeight = height * value
        let offset = (height - valueHeight) / 2

        context!.move(to: CGPoint(x: x, y: height - offset))
        context!.addLine(to: CGPoint(x: x, y: height - valueHeight - offset))

        context!.strokePath()
    }
}

class VoiceRecordSampleView: UIView {

    var sampleValues: [CGFloat] = []

    lazy var sampleCollectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 2
        layout.sectionInset = UIEdgeInsets.zero
        layout.itemSize = CGSize(width: 4, height: 60)
        layout.scrollDirection = .horizontal
        return layout
    }()

    lazy var sampleCollectionView: UICollectionView = {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.sampleCollectionViewLayout)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        view.dataSource = self
        view.registerClassOf(VoiceRecordSampleCell.self)
        return view
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
        println("deinit VoiceRecordSampleView")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        makeUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sampleCollectionViewLayout.itemSize = CGSize(width: 4, height: sampleCollectionView.bounds.height)
    }

    func makeUI() {

        addSubview(sampleCollectionView)
        sampleCollectionView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "sampleCollectionView": sampleCollectionView,
        ]

        let sampleCollectionViewConstraintH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[sampleCollectionView]|", options: [], metrics: nil, views: views)
        let sampleCollectionViewConstraintV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[sampleCollectionView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(sampleCollectionViewConstraintH)
        NSLayoutConstraint.activate(sampleCollectionViewConstraintV)

        NotificationCenter.default.addObserver(self, selector: #selector(VoiceRecordSampleView.reloadSampleCollectionView(_:)), name: YepConfig.NotificationName.applicationDidBecomeActive, object: nil)
    }

    @objc fileprivate func reloadSampleCollectionView(_ notification: Notification) {
        sampleCollectionView.reloadData()
    }

    func appendSampleValue(_ value: CGFloat) {
        sampleValues.append(value)

        let indexPath = IndexPath(item: sampleValues.count - 1, section: 0)
        sampleCollectionView.insertItems(at: [indexPath])
        sampleCollectionView.scrollToItem(at: indexPath, at: .right, animated: false)
    }

    func reset() {
        sampleValues = []
        sampleCollectionView.reloadData()
    }
}

extension VoiceRecordSampleView: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sampleValues.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: VoiceRecordSampleCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        let value = sampleValues[indexPath.item]
        cell.value = value

        return cell
    }
}

