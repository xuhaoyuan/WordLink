///可以设置切不同位置的圆角

import UIKit

open class CustomCornerView: UIView {
    open var cornerR: CGFloat
    open var roundingCorners: UIRectCorner

    public override init(frame: CGRect) {
        self.cornerR = 0
        self.roundingCorners = .allCorners
        super.init(frame: frame)
    }

    func config(corners: UIRectCorner, corner: CGFloat) {
        self.cornerR = corner
        self.roundingCorners = corners
        setNeedsLayout()
    }

    public init(corners: UIRectCorner, corner: CGFloat) {
        self.cornerR = corner
        self.roundingCorners = corners
        super.init(frame: CGRect.zero)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: cornerR, height: cornerR))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.frame = bounds
        layer.mask = maskLayer
    }
}
