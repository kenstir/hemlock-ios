import UIKit

import Foundation

// Non-scrolling TableView that you can put with other views inside a ScrollView
// https://stackoverflow.com/questions/24090104/make-uitableview-not-scrollable-and-adjust-height-to-accommodate-all-cells
// implicitly released under the CC by-SA license
class NonScrollingTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet{
            self.invalidateIntrinsicContentSize()
        }
    }

    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}
