//
//  AppKit.Application.swift
//  Utils
//
//  Created by Ivan Kh on 09.12.2022.
//

#if os(iOS)
import UIKit
#endif

#if os(iOS)
public extension UIApplication {
    static var safeShared: UIApplication? {
        guard UIApplication.responds(to: Selector(("sharedApplication"))) else {
            return nil
        }
        
        guard let unmanagedSharedApplication = UIApplication.perform(Selector(("sharedApplication"))) else {
            return nil
        }
        
        return unmanagedSharedApplication.takeRetainedValue() as? UIApplication
    }
    
    var interfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 13.0, *) {
            return self.windows.first?.windowScene?.interfaceOrientation
        } else {
            return self.statusBarOrientation
        }
    }
    
    var interfaceOrientationOnMain: UIInterfaceOrientation? {
        return dispatchMainSync {
            return interfaceOrientation
        }
    }
}
#endif
