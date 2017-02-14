//
//  Extensions.swift
//  Extensions
//
//  Created by Matthew McArthur on 2/13/17.
//  Copyright © 2017 McArthur. All rights reserved.
//

import Foundation

// MARK: Keyboard Management
public extension UIViewController {
    public func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
    }
    
    public func dismissKeyboard() {
        view.endEditing(true)
    }
}


// MARK: Simplified nib loading and tableviewcell registration
public protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView {
    public static var defaultReuseIdentifier: String {
        return NSStringFromClass(self).components(separatedBy: CharacterSet(charactersIn: ".")).last!
    }
}

public protocol NibLoadableView: class {
    static var nibName: String { get }
}

public extension NibLoadableView where Self: UIView {
    public static var nibName: String {
        return NSStringFromClass(self).components(separatedBy: CharacterSet(charactersIn: ".")).last!
    }
    
    public static func fromNib<T : UIView>(nibName: String) -> T? {
        return fromNib(nibName: nibName, type: T.self)
    }
    
    public static func fromNib<T : UIView>() -> T? {
        let v: T? = fromNib(nibName: nibName, type: T.self)
        return v
    }
    
    public static func fromNib<T : UIView>(nibName: String, type: T.Type) -> T? {
        return UINib(nibName: nibName, bundle: Bundle.main).instantiate(withOwner: nil, options: nil)[0] as? T
    }
}
extension UICollectionViewCell: ReusableView {
}
extension UITableViewCell: ReusableView {
}

public extension UICollectionView {
    
    public func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    public func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellWithReuseIdentifier: T.nibName)
    }
    
    public func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = dequeueReusableCell(withReuseIdentifier:T.defaultReuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
}

public extension UITableView {
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView {
        register(T.self, forCellReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellReuseIdentifier: T.nibName)
    }
    
    public func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = dequeueReusableCell(withIdentifier:T.defaultReuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.defaultReuseIdentifier)")
        }
        return cell
    }
}

// MARK: Number formatting

public extension Double {
    /// Rounds the double to decimal places value
    public func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

public extension Float {
    /// Rounds the double to decimal places value
    public func roundTo(places:Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: Attributed String

public extension String {
    public func attributedString(globalAttributes: [String : Any], selectiveAttributes: [String : Any]?, characterSet: CharacterSet?) -> NSAttributedString{
        let attributedString = NSMutableAttributedString(string: self, attributes: globalAttributes)
        
        if let selectiveAttributes = selectiveAttributes, let characterSet = characterSet {
            for (index, unicodeScalar) in self.unicodeScalars.enumerated() {
                if characterSet.contains(unicodeScalar) {
                    attributedString.addAttributes(selectiveAttributes, range: NSRange(location: index, length: 1))
                }
            }
        }
        return attributedString
    }
}

// MARK: UIImage


public extension UIImage {
    public func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            break
        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            break
        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            break
        case UIImageOrientation.up, UIImageOrientation.upMirrored:
            break
        }
        switch imageOrientation {
        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
        default:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
    
    public func resizedImage(maxLength: Int, scale: CGFloat, hasAlpha: Bool) -> UIImage {
        let size = self.size
        
        let widthRatio  = CGFloat(maxLength)  / self.size.width
        let heightRatio = CGFloat(maxLength) / self.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, !hasAlpha, scale)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    public func tintWithColor(color:UIColor)->UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // flip the image
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -self.size.height)
        
        // multiply blend mode
        context.setBlendMode(.multiply)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        
        // create uiimage
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
}

// MARK: String

public extension String {
    public func hashTagFormat() -> String {
        let unsafeChars = CharacterSet.alphanumerics.inverted
        return self.components(separatedBy: unsafeChars).joined(separator: "")
    }
    public func lastPathComponent() -> String {
        for component in self.components(separatedBy: "/").reversed() {
            if component.characters.count > 0 {
                return component
            }
        }
        return self
    }
}

// MARK: UIView Constraints
public extension UIView {
    public func matchSuperview(){
        _ = matchSuperviewWithMargin(margin: 0)
    }
    
    public func matchSuperviewWithMargin(margin: CGFloat){
        _ = matchSuperviewWithMargin(top: margin, trailing: margin, bottom: margin, leading: margin)
    }
    
    public func matchSuperviewWithMargin(top: CGFloat, trailing: CGFloat, bottom: CGFloat, leading: CGFloat) -> (topSpace: NSLayoutConstraint, trailingSpace: NSLayoutConstraint, bottomSpace: NSLayoutConstraint, leadingSpace: NSLayoutConstraint){
        let topSpace = NSLayoutConstraint(item: self,
                                          attribute: .top,
                                          relatedBy: .equal,
                                          toItem: self.superview,
                                          attribute: .top,
                                          multiplier: 1,
                                          constant: top)
        let trailingSpace = NSLayoutConstraint(item: self,
                                               attribute: .right,
                                               relatedBy: .equal,
                                               toItem: self.superview,
                                               attribute: .right,
                                               multiplier: 1,
                                               constant: -trailing)
        let bottomSpace = NSLayoutConstraint(item: self,
                                             attribute: .bottom,
                                             relatedBy: .equal,
                                             toItem: self.superview,
                                             attribute: .bottom,
                                             multiplier: 1,
                                             constant: -bottom)
        let leadingSpace = NSLayoutConstraint(item: self,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: self.superview,
                                              attribute: .left,
                                              multiplier: 1,
                                              constant: leading)
        if let superview = self.superview {
            superview.addConstraints([topSpace,trailingSpace,bottomSpace,leadingSpace])
        }
        return (topSpace, trailingSpace, bottomSpace, leadingSpace)
    }
    
}


public protocol PresentedViewDelegate: class {
    func presentedViewWillDismiss()
    func presentedViewDidDismiss()
}
public protocol PresentedViewProtocol {
    weak var delegate: PresentedViewDelegate? { get set }
    func dismissMyself()
}

public extension PresentedViewProtocol where Self: UIViewController {
    public func dismissMyself() {
        self.delegate?.presentedViewWillDismiss()
        self.dismiss(animated: true, completion: { _ in
            self.delegate?.presentedViewDidDismiss()
        })
    }
}

