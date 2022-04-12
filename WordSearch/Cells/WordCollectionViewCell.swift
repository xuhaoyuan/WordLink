//
//  WordCollectionViewCell.swift
//  WordSearch
//
//  Created by TonyNguyen on 5/10/19.
//  Copyright © 2019 Phuc Nguyen. All rights reserved.
//

import UIKit

class WordCollectionViewCell: UICollectionViewCell {

    private var label: UILabel = UILabel()


    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.isHidden = true
        addSubview(label)
        label.textAlignment = .center
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with text: String, selected: Bool) {
        if selected {
            // Strike through the word if it's selected.
            let attrString = NSMutableAttributedString(string: text)
            let attrsDict = [
                NSAttributedString.Key.strikethroughStyle: 2,
                NSAttributedString.Key.foregroundColor: UIColor.gray,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .bold)
                ] as [NSAttributedString.Key : Any]
            attrString.addAttributes(attrsDict, range: NSRange(location: 0, length: text.count))
            label.attributedText = attrString
        } else {
            label.text = text
            label.textColor = UIColor.black
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        }
        label.backgroundColor = isSelected ? UIColor.gray.withAlphaComponent(0.5) : UIColor.clear
    }
}
