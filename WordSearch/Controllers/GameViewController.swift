//
//  ViewController.swift
//  WordSearch
//
//  Created by TonyNguyen on 5/9/19.
//  Copyright © 2019 Phuc Nguyen. All rights reserved.
//

import UIKit
import Randient

class GameViewController: UIViewController {

    private lazy var blurView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
        return blur
    }()

    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        label.text = "00:00"
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
        return label
    }()
    private lazy var gridCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.registerCell(GridCollectionViewCell.self)
        view.delegate = self
        view.dataSource = self
        return view
    }()

    private lazy var overlayView: LinesOverlay = {
        let view = LinesOverlay()
        view.isUserInteractionEnabled = false
        return view
    }()

    private var wordListCollectionView = WordListCollectionView()

    private lazy var randientView = RandientView()
    private lazy var gridGenerator: WordGridGenerator = {
        return WordGridGenerator(words: item.items.map({$0.en}), row: nRow, column: nCol)
    }()
    fileprivate let nRow = 10
    fileprivate let nCol = 10
    fileprivate var grid: Grid = Grid()

    private lazy var backItem: UIBarButtonItem = {
        var item = UIBarButtonItem.SystemItem.cancel
        if #available(iOS 13.0, *) {
            item = .close
        }
        return UIBarButtonItem(barButtonSystemItem: item, target: self, action: #selector(quit))
    }()

    private lazy var restartItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.refresh, target: self, action: #selector(restart))
        return item
    }()

    private lazy var pauseItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.pause, target: self, action: #selector(pauseAction))
        return item
    }()

    private lazy var playItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector(playAction))
        return item
    }()

    private var contentSizeObser: NSKeyValueObservation?

    private let item: SelectRow
    init(item: SelectRow) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Used to display elapsed time of the game.
    /// The timer can be paused and resumed.
    private var elapsedSeconds: Int = 0 {
        didSet {
            timerLabel.text = elapsedSeconds.formattedTime()
        }
    }
    private var timer: Timer?

    private func makeUI() {
        view.backgroundColor = UIColor.white
        navigationItem.leftBarButtonItem = backItem
        navigationItem.titleView = timerLabel
        navigationItem.rightBarButtonItems = [pauseItem, restartItem]

        view.addSubview(gridCollectionView)
        view.addSubview(overlayView)
        view.addSubview(wordListCollectionView)
        view.addSubview(blurView)


        gridCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalTo(gridCollectionView)
        }
        wordListCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(gridCollectionView.snp.bottom)
            make.height.equalTo(0)
        }

        contentSizeObser = wordListCollectionView.observe(\.contentSize, options: [.new, .old]) { [weak self] _, result in
            guard let self = self else { return }
            self.wordListCollectionView.snp.updateConstraints { make in
                let height = result.newValue?.height ?? 0
                make.height.equalTo(height + self.view.safeAreaInsets.bottom)
            }
            self.gridCollectionView.reloadData()
        }
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        randientView.frame = gridCollectionView.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()

        wordListCollectionView.words = item.items
        setupGridCollectionView()
        setupOverlayView()
        loadGame()
    }

    @objc private func restart() {
        restartGame()
    }

    @objc private func quit() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func playAction() {
        startTimer()
        blurView.isHidden = true
        navigationItem.rightBarButtonItems = [pauseItem, restartItem]
    }

    @objc private func pauseAction() {
        timer?.invalidate()
        blurView.isHidden = false
        navigationItem.setRightBarButtonItems([playItem, restartItem], animated: true)
    }

    private func loadGame() {
        DispatchQueue.global().async {
            if let grid = self.gridGenerator.generate() {
                self.grid = grid
                DispatchQueue.main.async {
                    self.gridCollectionView.reloadData()
                    self.startTimer()
                }
            }
        }
    }

    private func setupGridCollectionView() {
        // Setup pan gesture
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(panHandling(gestureRecognizer:)))
        gridCollectionView.addGestureRecognizer(panGR)
        randientView.startPoint = CGPoint(x: 0.5, y: 0)
        randientView.endPoint = CGPoint(x: 0.5, y: 1)
        randientView.setGradient(.dirtyFog, animated: true) {

        }
        gridCollectionView.backgroundView = randientView
//        navigationController?.navigationBar.backgroundColor = randientView.colors?.first
//        wordListCollectionView.backgroundColor = randientView.colors?.last

        gridCollectionView.layer.cornerRadius = 16
    }

    private func setupOverlayView() {
        overlayView.row = nRow
        overlayView.col = nCol
    }


    /// Helper function to get row and col from an indexPath.
    ///
    /// - Parameter index: an index from an indexPath.
    /// - Returns: row and col of the cell in the grid.
    private func position(from index: Int) -> Position {
        return Position(row: index / nRow, col: index % nCol)
    }

    /// Start and display clock time.
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (_) in
            self.elapsedSeconds += 1
        })
    }

    fileprivate func restartGame() {
        overlayView.reset()
        wordListCollectionView.reset()
        elapsedSeconds = 0
        loadGame()
    }

    @objc func panHandling(gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: gridCollectionView)
        guard let indexPath = gridCollectionView.indexPathForItem(at: point) else {
            return
        }
        let pos = position(from: indexPath.row)

        switch gestureRecognizer.state {
        case .began:
            overlayView.addTempLine(at: pos)
            // Select item to animate the cell
            // Since we set the collection view `selection mode` to single
            // This means only one letter is animated at a time.
            // So in `.ended` event, we just need to deselect one cell.
            gridCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        case .changed:
            if overlayView.moveTempLine(to: pos) {
                gridCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        case .ended:
            // Stop animation
            gridCollectionView.deselectItem(at: indexPath, animated: true)
            guard let startPos = overlayView.tempLine?.startPos else {
                return
            }
            // Get the word from the pre-computed map
            let key = WordGridGenerator.wordKey(for: startPos, and: pos)
            if let word = gridGenerator.wordsMap[key] {
                overlayView.acceptLastLine()
                wordListCollectionView.select(word: word)
                if overlayView.permanentLines.count == gridGenerator.words.count {
                    // Pause the time because user has won the game.
                    timer?.invalidate()
                }
            }
            // Remove the temp line
            overlayView.removeTempLine()
        default: break
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (_) in
            // Force re-draw the collection views when orientation changes.
            self.gridCollectionView.collectionViewLayout.invalidateLayout()
            self.wordListCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

extension GameViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return grid.count * (grid.first?.count ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = collectionView.bounds.width / CGFloat(nCol)
        let h = collectionView.bounds.height / CGFloat(nRow)
        return CGSize(width: w, height: h)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GridCollectionViewCell = collectionView.dequeueReusableCell(indexPath)
        let pos = position(from: indexPath.row)
        cell.label.text = String(grid[pos.row][pos.col])
        return cell
    }
}

