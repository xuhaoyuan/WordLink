//
//  SelectViewController.swift
//  WordSearch
//
//  Created by 许浩渊 on 2022/4/11.
//  Copyright © 2022 Phuc Nguyen. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit
import Randient
import CloudKit

class SelectViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(SelectCell.self)
        tableView.registerCell(SelectAddCell.self)
        tableView.separatorStyle = .none
        return tableView
    }()

    var list: [SelectRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        title = "主题"
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        ViewModel.shared.dataRelay.bind { [weak self] data in
            self?.list = data
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
    }

    private func showDeleteActionSheet(delete: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: "选项", message: "", preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "删除", style: .default, handler: delete)
        let confirm = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(delete)
        alert.addAction(confirm)
        self.showDetailViewController(alert, sender: nil)
    }

}

extension SelectViewController: UITableViewDelegate, UITableViewDataSource {

    enum Section: Int, CaseIterable {
        case list
        case add
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .list:
            let vc = DetailViewController(data: list[indexPath.row])
            show(vc, sender: nil)
        case .add:
            showEditAlert()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .list:
            return list.count
        case .add:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
        switch section {
        case .list:
            let cell: SelectCell = tableView.dequeueReusableCell()
            cell.config(row: list[indexPath.row])
            cell.longGes = { [weak self] uuid in
                guard let self = self else { return }
                self.showDeleteActionSheet { [weak self] _ in
                    ViewModel.shared.removeData(uuid: uuid)
                }
            }
            return cell
        case .add:
            let cell: SelectAddCell = tableView.dequeueReusableCell()
            return cell
        }

    }

    private func showEditAlert() {
        let alert = UIAlertController(title: "请输入新主题", message: "", preferredStyle: .alert)
        alert.addTextField { field in
            field.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            field.placeholder = "主题"
        }
        let sure = UIAlertAction(title: "确认", style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let text = alert.textFields?.first?.text, text.count > 0 else { return }
            let item = SelectRow(title: text, items: [])
            ViewModel.shared.addData(item: item)
            let vc = DetailViewController(data: item)
            self.show(vc, sender: nil)
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { _ in }
        alert.addAction(sure)
        alert.addAction(cancel)
        self.showDetailViewController(alert, sender: nil)
    }


    private func showActionSheet(edit: @escaping (UIAlertAction) -> Void, delete: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: "选项", message: "", preferredStyle: .actionSheet)
        let edit = UIAlertAction(title: "编辑", style: .default, handler: edit)
        let delete = UIAlertAction(title: "删除", style: .default, handler: delete)
        let confirm = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(edit)
        alert.addAction(delete)
        alert.addAction(confirm)
        self.showDetailViewController(alert, sender: nil)

    }
}

class SelectCell: UITableViewCell {

    private var bgView = RandientView()
    private var title = UILabel()
    private var row: SelectRow?
    var longGes: ((String) -> Void)?

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let ges = UILongPressGestureRecognizer(target: self, action: #selector(longGesture(_:)))
        return ges
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        selectionStyle = .none

        addSubview(bgView)
        bgView.addSubview(title)
        bgView.clipsToBounds = true
        bgView.addSubview(title)

        bgView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 8))
            make.height.equalTo(80)
        }

        bgView.addGestureRecognizer(longPressGesture)

        title.textColor = UIColor.white
        title.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        title.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        bgView.startPoint = CGPoint(x: 0, y: 0.5)
        bgView.endPoint = CGPoint(x: 1, y: 0.5)
        bgView.randomize(animated: true) { }
    }

    @objc private func longGesture(_ ges: UILongPressGestureRecognizer) {
        guard ges.state == .began else { return }
        guard let row = row else { return }
        longGes?(row.uuid)
    }

    func config(row: SelectRow) {
        self.row = row
        title.text = row.title
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.layer.cornerRadius = bgView.frame.height/2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SelectAddCell: UITableViewCell {

    private var bgView = RandientView()
    private var addImage = UIImageView(image: UIImage(named: "iconDiamondAdd"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        selectionStyle = .none

        addSubview(bgView)
        bgView.addSubview(addImage)
        bgView.clipsToBounds = true
        bgView.addSubview(addImage)

        bgView.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.bottom.equalTo(8)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(60)
        }

        addImage.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        bgView.startPoint = CGPoint(x: 0, y: 0.5)
        bgView.endPoint = CGPoint(x: 1, y: 0.5)
        bgView.randomize(animated: true) { }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.layer.cornerRadius = bgView.frame.height/2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

