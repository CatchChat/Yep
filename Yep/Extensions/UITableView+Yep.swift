//
//  UITableView+Yep.swift
//  Yep
//
//  Created by nixzhu on 15/12/11.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UITableView {

    enum WayToUpdate {

        case None
        case ReloadData
        case ReloadIndexPaths([NSIndexPath])
        case Insert([NSIndexPath])

        var needsLabor: Bool {

            switch self {
            case .None:
                return false
            case .ReloadData:
                return true
            case .ReloadIndexPaths:
                return true
            case .Insert:
                return true
            }
        }

        func performWithTableView(tableView: UITableView) {

            switch self {

            case .None:
                println("tableView WayToUpdate: None")
                break

            case .ReloadData:
                println("tableView WayToUpdate: ReloadData")
                tableView.reloadData()

            case .ReloadIndexPaths(let indexPaths):
                println("tableView WayToUpdate: ReloadIndexPaths")
                tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)

            case .Insert(let indexPaths):
                println("tableView WayToUpdate: Insert")
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
            }
        }
    }
}

extension UITableView {

    func registerClassOf<T: UITableViewCell where T: Reusable>(_: T.Type) {

        registerClass(T.self, forCellReuseIdentifier: T.yep_reuseIdentifier)
    }

    func registerNibOf<T: UITableViewCell where T: Reusable, T: NibLoadable>(_: T.Type) {

        let bundle = NSBundle(forClass: T.self)
        let nib = UINib(nibName: T.yep_nibName, bundle: bundle)

        registerNib(nib, forCellReuseIdentifier: T.yep_reuseIdentifier)
    }

    func registerHeaderFooterClassOf<T: UITableViewHeaderFooterView where T: Reusable>(_: T.Type) {

        registerClass(T.self, forHeaderFooterViewReuseIdentifier: T.yep_reuseIdentifier)
    }

    func dequeueReusableCell<T: UITableViewCell where T: Reusable>() -> T {

        guard let cell = dequeueReusableCellWithIdentifier(T.yep_reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.yep_reuseIdentifier)")
        }
        
        return cell
    }

    func dequeueReusableHeaderFooter<T: UITableViewHeaderFooterView where T: Reusable>() -> T {

        guard let view = dequeueReusableHeaderFooterViewWithIdentifier(T.yep_reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.yep_reuseIdentifier)")
        }

        return view
    }
}

