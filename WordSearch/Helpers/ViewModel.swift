//
//  ViewModel.swift
//  WordSearch
//
//  Created by 许浩渊 on 2022/4/12.
//  Copyright © 2022 Phuc Nguyen. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Disk

class ViewModel: NSObject {

    static let shared = ViewModel()

    var dataRelay: BehaviorRelay<[SelectRow]> = BehaviorRelay(value: [])

    override init() {
        super.init()
        do {
            var retrieveData = try Disk.retrieve("/detailList", from: .documents, as: [SelectRow].self)
            if retrieveData.count == 0 {
                retrieveData = getDefaultModel()
                dataRelay.accept(retrieveData)
                save()
            } else {
                dataRelay.accept(retrieveData)
            }
        } catch {
            print(error.localizedDescription)
            dataRelay.accept(getDefaultModel())
            save()
        }
    }

    func removeData(uuid: String) {
        var data = dataRelay.value
        data.removeAll {
            $0.uuid == uuid
        }
        dataRelay.accept(data)
        save()
    }

    func updateData(item: SelectRow) {
        var data = dataRelay.value
        for (index, oldItem) in data.enumerated() {
            guard item.uuid == oldItem.uuid else { continue }
            data[index] = item
        }
        dataRelay.accept(data)
        save()
    }

    func addData(item: SelectRow) {
        var data = dataRelay.value
        data.append(item)
        dataRelay.accept(data)
        save()
    }

    private func save() {
        let data = dataRelay.value
        do {
            try Disk.save(data, to: .documents, as: "/detailList")
        } catch {
            print(error.localizedDescription)
        }
    }

    private func getDefaultModel() -> [SelectRow] {
        return [
            SelectRow(title: "Animal", items: [
                SelectRow.Item(en: "Bear", cn: "熊"),
                SelectRow.Item(en: "Tiger", cn: "老虎"),
                SelectRow.Item(en: "Giraffe", cn: "长颈鹿"),
                SelectRow.Item(en: "Deer", cn: "鹿"),
                SelectRow.Item(en: "Lion", cn: "狮子"),
                SelectRow.Item(en: "Monkey", cn: "猴子"),
                SelectRow.Item(en: "Elephant", cn: "大象"),
                SelectRow.Item(en: "Horse", cn: "马"),
            ]),
            SelectRow(title: "Vehicle", items: [
                SelectRow.Item(en: "truck", cn: "卡车"),
                SelectRow.Item(en: "subway", cn: "地铁"),
                SelectRow.Item(en: "motorcycle", cn: "摩托车"),
                SelectRow.Item(en: "helicopter", cn: "直升机"),
                SelectRow.Item(en: "yacht", cn: "游艇"),
                SelectRow.Item(en: "bicycle", cn: "自行车"),
                SelectRow.Item(en: "taxi", cn: "出租车"),
                SelectRow.Item(en: "bus", cn: "公交车"),
            ]),
            SelectRow(title: "Fruits", items: [
                SelectRow.Item(en: "apple", cn: "苹果"),
                SelectRow.Item(en: "pear", cn: "梨子"),
                SelectRow.Item(en: "peach", cn: "桃子"),
                SelectRow.Item(en: "grape", cn: "葡萄"),
                SelectRow.Item(en: "banana", cn: "香蕉"),
                SelectRow.Item(en: "watermelon", cn: "西瓜"),
                SelectRow.Item(en: "lemon", cn: "柠檬"),
                SelectRow.Item(en: "mango", cn: "芒果"),
            ])
        ]
    }
}

struct SelectRow: Codable, Hashable {
    let title: String
    var items: [Item]
    let uuid: String

    init(title: String, items: [Item], uuid: String = UUID().uuidString) {
        self.title = title
        self.items = items
        self.uuid = uuid
    }

    struct Item: Codable, Hashable {
        init(en: String, cn: String) {
            self.en = en
            self.cn = cn
        }
        let en: String
        let cn: String
    }
}

