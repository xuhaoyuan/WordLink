//
//  GridCollectionViewCell.swift
//  WordSearch
//
//  Created by TonyNguyen on 5/9/19.
//  Copyright © 2019 Phuc Nguyen. All rights reserved.
//

import UIKit

class GridCollectionViewCell: UICollectionViewCell {

    private let animationScaleFactor: CGFloat = 1.5

    private(set) var label: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.isHidden = true
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            // Scale up the letter if it's selected.
            let transform = isSelected ? CGAffineTransform(scaleX: animationScaleFactor, y: animationScaleFactor) : .identity
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5, options: [], animations: {
                self.label.transform = transform
            }) { (_) in }
        }
    }
}
