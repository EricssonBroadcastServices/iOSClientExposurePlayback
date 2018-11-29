//
//  TableViewDataSource.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2018-11-21.
//  Copyright © 2018 emp. All rights reserved.
//

import UIKit
import Exposure


/// Generic TableViewDataSource Class
class TableViewDataSource<Model>: NSObject, UITableViewDataSource {
    
    typealias CellConfigurator = (Model, UITableViewCell) -> Void
    var models: [Model] = []
    
    private let reuseIdentifier: String
    private let cellConfigurator: CellConfigurator
    
    init(models: [Model],
         reuseIdentifier: String,
         cellConfigurator: @escaping CellConfigurator) {
        self.models = models
        self.reuseIdentifier = reuseIdentifier
        self.cellConfigurator = cellConfigurator
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if models.count == 0 {
            tableView.showEmptyMessage(message: NSLocalizedString("Sorry no data to show", comment: ""))
        } else {
            tableView.hideEmptyMessage()
        }
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cellConfigurator(model, cell)
        return cell
    }
}



// MARK: - DataSource:Assets
extension TableViewDataSource where Model == Asset {
    
    static func make(for assets: [Asset], reuseIdentifier:String = "assetListTableViewCell") -> TableViewDataSource {
        
        return TableViewDataSource(models: assets, reuseIdentifier: reuseIdentifier) { (asset, cell) in
            cell.selectionStyle = .none
            cell.backgroundColor = ColorState.active.background
            cell.textLabel?.textColor = ColorState.active.text
            cell.textLabel?.text = asset.localized?.first?.title
        }
    }
}
