//
//  DetailViewController.swift
//  WordSearch
//
//  Created by 许浩渊 on 2022/4/11.
//  Copyright © 2022 Phuc Nguyen. All rights reserved.
//


import UIKit
import SnapKit
import Randient
import SwiftEntryKit
import RxSwift
import SwiftUI

class DetailViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(DetailSelectCell.self)
        tableView.registerCell(DetailSelectAddCell.self)
        tableView.separatorStyle = .none
        return tableView
    }()

    var data: SelectRow

    init(data: SelectRow) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = data.title
        view.addSubview(tableView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector(editAction))

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        ViewModel.shared.dataRelay.bind { [weak self] items in
            guard let self = self else { return }
            guard let item = items.first(where: {$0.uuid == self.data.uuid}) else { return }
            self.data = item
            self.tableView.reloadData()
        }.disposed(by: disposeBag)
    }

    @objc private func editAction() {
        guard data.items.count > 0 else { return }
        let vc = GameViewController(item: data)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        showDetailViewController(nav, sender: nil)
    }

    private func showEditAlert(en: String = "", cn: String = "", callBack: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: "请输入", message: "", preferredStyle: .alert)
        alert.addTextField { field in
            field.text = en
            field.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            field.tag = 1234
            field.placeholder = "请输入英文单词"
        }
        alert.addTextField { field in
            field.text = cn
            field.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            field.tag = 1235
            field.placeholder = "请输入注释"
        }
        let sure = UIAlertAction(title: "确认", style: .default) { _ in
            let enField = alert.textFields?.first(where: { $0.tag == 1234 })
            let cnField = alert.textFields?.first(where: { $0.tag == 1235 })
            guard let enText = enField?.text, enText.count > 0 else { return }
            guard self.isEnglishCharacter(source: enText) else {
                let alert = UIAlertController(title: "⚠️", message: "请填写英文字符", preferredStyle: .alert)
                let sure = UIAlertAction(title: "确认", style: .default)
                alert.addAction(sure)
                self.showDetailViewController(alert, sender: nil)
                return
            }
            callBack(enText, cnField?.text ?? enText)
        }
        alert.addAction(sure)
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

    private func showDeleteActionSheet(delete: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: "选项", message: "", preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "删除", style: .default, handler: delete)
        let confirm = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(delete)
        alert.addAction(confirm)
        self.showDetailViewController(alert, sender: nil)
    }

    private func showSigninForm(attributes: EKAttributes =  EKAttributes.getAttributes(), style: FormStyle = .light, en: String = "", cn: String = "", callBack: @escaping (String, String) -> Void) {
        let titleStyle = EKProperty.LabelStyle(
            font: MainFont.medium.with(size: 16),
            color: .standardContent,
            alignment: .center,
            displayMode: displayMode
        )

        let title = EKProperty.LabelContent(
            text: "单词",
            style: titleStyle
        )

        let placeholderStyle = style.placeholder
        let textStyle = EKProperty.LabelStyle(
            font: MainFont.light.with(size: 14),
            color: .standardContent,
            displayMode: displayMode
        )
        let separatorColor = style.separator

        let fullNamePlaceholder = EKProperty.LabelContent(
            text: "英文单词",
            style: placeholderStyle
        )

        var enLabel = EKProperty.TextFieldContent(keyboardType: .namePhonePad,
                                                  placeholder: fullNamePlaceholder,
                                                  tintColor: style.textColor,
                                                  displayMode: displayMode,
                                                  textStyle: textStyle,
                                                  bottomBorderColor: separatorColor)
        enLabel.textContent = en
        let descPlaceholder = EKProperty.LabelContent(
            text: "单词注释",
            style: placeholderStyle
        )

        var descLabel = EKProperty.TextFieldContent(keyboardType: .namePhonePad,
                                                    placeholder: descPlaceholder,
                                                    tintColor: style.textColor,
                                                    displayMode: displayMode,
                                                    textStyle: textStyle,
                                                    bottomBorderColor: separatorColor)
        descLabel.textContent = cn
        let button = EKProperty.ButtonContent(
            label: .init(text: "继续", style: style.buttonTitle),
            backgroundColor: style.buttonBackground,
            highlightedBackgroundColor: style.buttonBackground.with(alpha: 0.8),
            displayMode: displayMode) { [weak self] in
                guard let self = self else { return }
                guard self.isEnglishCharacter(source: enLabel.textContent) else {

                    let alert = UIAlertController(title: "⚠️", message: "请填写英文字符", preferredStyle: .alert)
                    let sure = UIAlertAction(title: "确认", style: .default)
                    alert.addAction(sure)
                    self.showDetailViewController(alert, sender: nil)
                    return
                }
                callBack(enLabel.textContent, descLabel.textContent)
                SwiftEntryKit.dismiss()
            }
        let contentView = EKFormMessageView(
            with: title,
            textFieldsContent: [enLabel, descLabel],
            buttonContent: button
        )
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func isEnglishCharacter(source: String) -> Bool {
        do {
            let numberRegular = try NSRegularExpression(pattern: "[A-Za-z]", options: .caseInsensitive)
            let number = numberRegular.numberOfMatches(in: source, options: .reportProgress, range: NSRange(location: 0, length: source.count))
            return number == source.count
        } catch {
            return false
        }
    }
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource {

    enum Section: Int, CaseIterable {
        case list
        case add
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .list:
            let data = data.items[indexPath.row]
            showActionSheet { [weak self] _ in
                guard let self = self else { return }
                self.showEditAlert(en: data.en, cn: data.cn) { [weak self] en, cn in
                    guard let self = self else { return }
                    self.data.items[indexPath.row] = SelectRow.Item(en: en, cn: cn)
                    ViewModel.shared.updateData(item: self.data)
                }
            } delete: { [weak self] _ in
                guard let self = self else { return }
                self.data.items.remove(at: indexPath.row)
                ViewModel.shared.updateData(item: self.data)
            }
        case .add:
            self.showEditAlert { [weak self] en, cn in
                guard let self = self else { return }
                self.data.items.append(SelectRow.Item(en: en, cn: cn))
                ViewModel.shared.updateData(item: self.data)
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .list:
            return data.items.count
        case .add:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { fatalError() }
        switch section {
        case .list:
            let cell: DetailSelectCell = tableView.dequeueReusableCell()
            cell.config(row: data.items[indexPath.row])
            return cell
        case .add:
            let cell: DetailSelectAddCell = tableView.dequeueReusableCell()
            return cell
        }

    }
}

class DetailSelectCell: UITableViewCell {

    private var bgView = RandientView()
    private var english = UILabel()
    private var desc = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        selectionStyle = .none

        bgView.clipsToBounds = true
        addSubview(bgView)
        bgView.addSubview(english)
        bgView.addSubview(desc)

        bgView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 8))
        }

        english.textColor = UIColor.white
        english.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        english.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(12)
        }

        desc.textColor = UIColor.white
        desc.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        desc.snp.makeConstraints { make in
            make.bottom.equalTo(-12)
            make.centerX.equalToSuperview()
            make.top.equalTo(english.snp.bottom).offset(12)
        }

        bgView.startPoint = CGPoint(x: 0, y: 0.5)
        bgView.endPoint = CGPoint(x: 1, y: 0.5)
        bgView.randomize(animated: true) { }
    }

    func config(row: SelectRow.Item) {
        english.text = row.en
        desc.text = row.cn
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.layer.cornerRadius = bgView.frame.height/2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DetailSelectAddCell: UITableViewCell {

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

private var displayMode: EKAttributes.DisplayMode {
    return PresetsDataSource.displayMode
}



extension EKAttributes {
    static func getAttributes() -> EKAttributes {
        var attributes = EKAttributes()
        attributes = .float
        attributes.displayMode = .inferred
        attributes.windowLevel = .custom(level: UIWindow.Level.alert - 1)
        attributes.position = .center
        attributes.displayDuration = .infinity
        attributes.entranceAnimation = .init(
            translate: .init(
                duration: 0.65,
                anchorPosition: .bottom,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.exitAnimation = .init(
            translate: .init(
                duration: 0.65,
                anchorPosition: .bottom,
                spring: .init(damping: 1, initialVelocity: 0)
            )
        )
        attributes.popBehavior = .animated(
            animation: .init(
                translate: .init(
                    duration: 0.65,
                    spring: .init(damping: 1, initialVelocity: 0)
                )
            )
        )
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.entryBackground = .color(color: .standardBackground)
        attributes.screenBackground = .color(color: .dimmedDarkBackground)
        attributes.border = .value(
            color: UIColor(white: 0.6, alpha: 1),
            width: 1
        )
        attributes.shadow = .active(
            with: .init(
                color: .black,
                opacity: 0.3,
                radius: 3
            )
        )
        attributes.scroll = .enabled(
            swipeable: false,
            pullbackAnimation: .jolt
        )
        attributes.statusBar = .light
        attributes.positionConstraints.keyboardRelation = .bind(
            offset: .init(
                bottom: 15,
                screenEdgeResistance: 0
            )
        )
        attributes.positionConstraints.maxSize = .init(
            width: .constant(value: UIScreen.main.minEdge),
            height: .intrinsic
        )
        return attributes
    }
}

