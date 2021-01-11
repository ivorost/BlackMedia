//
//  Button.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 04.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

#if os(OSX)
import AppKit

class RadioButton : NSButton {
    
    @IBInspectable var radioButtonContainer: NSView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAction()
    }
                
    private var stateInternal: NSControl.StateValue {
        get {
            return super.state
        }
        set {
            super.state = newValue
        }
    }
    
    private func setupAction() {
        self.target = self
        self.action = #selector(uesrAction(_:))
    }

    private func disableRadioButtonGroup() {
        let container = radioButtonContainer ?? superview
        guard let buttons = container?.descendants(withClass: RadioButton.self) else { return }
        
        for button in buttons {
            guard button != self else { continue
                
            }
            button.stateInternal = .off
        }
    }
    
    @objc private func uesrAction(_ sender: Any) {
        disableRadioButtonGroup()
    }
}
#endif
