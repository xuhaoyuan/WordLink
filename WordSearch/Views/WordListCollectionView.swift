//
//  WordListCollectionView.swift
//  WordSearch
//
//  Created by TonyNguyen on 5/10/19.
//  Copyright © 2019 Phuc Nguyen. All rights reserved.
//

import Foundation
import UIKit

/// This view shows the list of words to be searched
class WordListCollectionView: UICollectionView {

    /// The left and right inset of the collection view
    private let inset: CGFloat = 10

    private var wordSelectedMap: [SelectRow.Item: Bool] = [:]

    var words: [SelectRow.Item] = [] {
        didSet {
            wordSelectedMap = Dictionary(uniqueKeysWithValues: words.lazy.map { ($0, false) })
            reloadData()
        }
    }

    init() {
        let layout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: layout)
        delegate = self
        dataSource = self
        registerCell(WordCollectionViewCell.self)
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }

    /// A corrected word has been selected
    func select(word: String) {
        guard let index = words.enumerated().first(where: { $0.element.en == word && wordSelectedMap[$0.element] == false }) else {
            return
        }
        wordSelectedMap[index.element] = true
        let indexPath = IndexPath(item: index.offset, section: 0)
        reloadItems(at: [indexPath])
    }

    /// Reset states of words and collection view
    func reset() {
        for key in wordSelectedMap.keys { wordSelectedMap[key] = false }
        reloadData()
    }
}

extension WordListCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: WordCollectionViewCell = collectionView.dequeueReusableCell(indexPath)
        let word = words[indexPath.row]
        let isSelected = wordSelectedMap[word, default: false]
        cell.configure(with: word.cn, selected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = ((bounds.width - 2 * inset) - 20) / 3
        let height: CGFloat = 30
        return CGSize(width: width, height: height)
    }
}
