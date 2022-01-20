//
//  AppKit.Segue.swift
//  Utils
//
//  Created by Ivan Kh on 24.01.2022.
//


#if os(iOS)
import UIKit
#else
import AppKit
#endif


public extension UIStoryboardSegue {
#if os(iOS)
    var sourceViewController: UIViewController? {
        return source
    }
    
    var destinationViewController: UIViewController? {
        return destination
    }
#else
    var sourceViewController: NSViewController? {
        return sourceController as? NSViewController
    }
    
    var destinationViewController: NSViewController? {
        return destinationController as? NSViewController
    }
#endif
}


open class BaseSegue : UIStoryboardSegue {
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
