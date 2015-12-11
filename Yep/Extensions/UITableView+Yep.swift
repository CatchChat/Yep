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
        case Insert([NSIndexPath])

        var needsLabor: Bool {

            switch self {
            case .None:
                return false
            case .ReloadData:
                return true
            case .Insert:
                return true
            }
        }

        func performWithTableView(tableView: UITableView) {

            switch self {
            case .None:
                println("WayToUpdate None")
                break
            case .ReloadData:
                println("WayToUpdate ReloadData")
                tableView.reloadData()
            case .Insert(let indexPaths):
                println("WayToUpdate Insert")
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
            }
        }
    }
}

