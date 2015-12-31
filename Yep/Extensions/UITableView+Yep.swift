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

