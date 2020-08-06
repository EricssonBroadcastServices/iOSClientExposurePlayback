//
//  AssetListTableViewCell.swift
//  RefApp
//
//  Created by Udaya Sri Senarathne on 2020-05-18.
//  Copyright © 2020 emp. All rights reserved.
//

import UIKit

class AssetListTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = label.font.withSize(16)
        label.numberOfLines = 1
        return label
        
    }()
    
    var downloadStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = label.font.withSize(12)
        label.numberOfLines = 1
        return label
    }()

    let downloadProgressView: UIProgressView = {
        let progeressView = UIProgressView()
        progeressView.progressViewStyle = .bar
        return progeressView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleLabel)
        addSubview(downloadStateLabel)
        addSubview(downloadProgressView)
        
        titleLabel.anchor(top: self.topAnchor, bottom: nil, leading: self.leadingAnchor, trailing: self.trailingAnchor, padding: .init(top: 0, left: 10, bottom: 0, right: -10))
        downloadStateLabel.anchor(top: self.titleLabel.bottomAnchor, bottom: nil, leading: self.leadingAnchor, trailing: self.trailingAnchor, padding: .init(top: 0, left: 10, bottom: 0, right: -10))
        downloadProgressView.anchor(top: self.downloadStateLabel.bottomAnchor, bottom: self.bottomAnchor, leading: self.leadingAnchor, trailing: self.trailingAnchor , padding: .init(top: 5, left: 10, bottom: -10, right: -10))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
