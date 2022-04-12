import UIKit
extension UICollectionView {

    public func registerCell<T: UICollectionViewCell>(_: T.Type) {
        let identifier = String(describing: T.self)
        let filePath: String = (Bundle.main.resourcePath ?? "") + "/" + identifier + ".nib"
        if FileManager.default.fileExists(atPath: filePath) {
            register(UINib(nibName: identifier, bundle: .main), forCellWithReuseIdentifier: identifier)
        } else {
            register(T.self, forCellWithReuseIdentifier: identifier)
        }
    }

    public func dequeueReusableCell<T: UICollectionViewCell>(_ indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(String(describing: T.self))")
        }
        return cell
    }

    public enum SupplementaryViewOfKind {
        case header
        case footer
        var rawValue: String {
            switch self {
            case .header:
                return UICollectionView.elementKindSectionHeader
            case .footer:
                return UICollectionView.elementKindSectionFooter
            }
        }
    }

    public func registerCell<T: UICollectionReusableView>(_: T.Type, forSupplementaryViewOfKind: SupplementaryViewOfKind) {
        register(T.self, forSupplementaryViewOfKind: forSupplementaryViewOfKind.rawValue, withReuseIdentifier: String(describing: T.self))
    }

    public func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind: SupplementaryViewOfKind, indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableSupplementaryView(ofKind: ofKind.rawValue, withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(String(describing: T.self))")
        }
        return cell
    }
}

private var selectItemWorkItemKey: Void?
extension UICollectionView {

    private var selectItemWorkItem: DispatchWorkItem? {
        get { objc_getAssociatedObject(self, &selectItemWorkItemKey) as? DispatchWorkItem }
        set {
            objc_setAssociatedObject(self, &selectItemWorkItemKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func delaySelectItem(time: TimeInterval = 0.1, work: @escaping () -> Void) {
        selectItemWorkItem?.cancel()
        let workItem = DispatchWorkItem(block: work)
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: workItem)
        selectItemWorkItem = workItem
    }
}

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
