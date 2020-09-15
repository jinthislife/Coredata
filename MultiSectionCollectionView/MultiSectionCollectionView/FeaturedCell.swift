//
//  FeaturedCell.swift
//  MultiSectionCollectionView
//
//  Created by Jin Lee on 12/9/20.
//  Copyright © 2020 Jin Lee. All rights reserved.
//

import UIKit

class FeaturedCell: UICollectionViewCell {
    
    static let identifier = "FeaturedCell"

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Hi"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray
        contentView.addSubview(nameLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: Bookmark) {
        nameLabel.text = item.name
    }
}
