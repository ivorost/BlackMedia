//
//  AppKit.Segue.swift
//  Utils
//
//  Created by Ivan Kh on 24.01.2022.
//


#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif


#if canImport(UIKit)
public extension UIStoryboardSegue {
    var sourceViewController: UIViewController? {
        return source
    }
    
    var destinationViewController: UIViewController? {
        return destination
    }
}
#endif

#if canImport(AppKit)
public extension NSStoryboardSegue {
    var sourceViewController: NSViewController? {
        return sourceController as? NSViewController
    }
    
    var destinationViewController: NSViewController? {
        return destinationController as? NSViewController
    }
}
#endif


open class BaseSegue : AppleStoryboardSegue {
    open var preloadView = true
    
    
    open override func perform() {
        super.perform()
        
        if preloadView {
            _ = destinationViewController?.view
        }
    }
}


open class ConcreteSegue<TSrc, TDst> : BaseSegue {
    open override func perform() {
        super.perform()
        
        if let src = sourceViewController as? TSrc, let dst = destinationViewController as? TDst {
            perform(source: src, destination: dst)
        }
        else {
            assertionFailure()
        }
    }
    
    open func perform(source: TSrc, destination: TDst) {

    }
}
