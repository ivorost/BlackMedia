//
//  Table.swift
//  Camera
//
//  Created by Ivan Kh on 24.01.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


extension BlackRx {
    class TableCell<T> : UITableViewCell {
        @IBOutlet @objc var titleLabel: UILabel!
        let disposeBag = DisposeBag()
        
        func bind(to item: T) {
            titleLabel.text = String(describing: item)
        }
    }
}


extension BlackRx {
    class TableController<TItem, TCell> : UITableViewController where TCell : TableCell<TItem> {
        var items: Observable<[TItem]>?
        private let disposeBag = DisposeBag()
        @IBInspectable var cellIdentifier: String = "default"

        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.separatorStyle = .none
            tableView.rx.setDelegate(self).disposed(by: disposeBag)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            items?.bind(to: tableView.rx.items(cellIdentifier: cellIdentifier,
                                               cellType: TCell.self)) { row, item, cell in
                cell.bind(to: item)
            }.disposed(by: disposeBag)
        }
    }
}
