//
//  XDetailsPagerViewController.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import AsyncDisplayKit
import PromiseKit
import PMKAlamofire

/// Display options related to an MBRecord
struct RecordDisplayOptions {
    let enablePlaceHold: Bool
    let orgShortName: String?
}

class XDetailsPagerViewController: ASViewController<ASPagerNode> {
    
    //MARK: - Properties
    
    var items: [MBRecord]
    var selectedItem: Int
    var displayOptions: RecordDisplayOptions
    var firstAppearance = true

    private var pagerNode: ASPagerNode {
        return node
    }

    //MARK: - Lifecycle
    
    init(items: [MBRecord], selectedItem: Int, displayOptions: RecordDisplayOptions) {
        self.items = items
        self.selectedItem = selectedItem
        self.displayOptions = displayOptions
        super.init(node: ASPagerNode())
        self.title = "Item Details"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNodes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstAppearance {
            // scrollToPage has no effect if done in viewWillAppear(),
            // but doing it here means the scrolling is visible to the user,
            // so this is the least bad option.
            // See also https://github.com/TextureGroup/Texture/issues/133
            pagerNode.scrollToPage(at: selectedItem, animated: false)
        }
        firstAppearance = false
    }
    
    //MARK: - Setup
    
    func setupNodes() {
        if #available(iOS 11.0, *) {
            pagerNode.view.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        // If you don't set isTranslucent=false, either here or in the AppDelegate,
        // ASDK positions the content *under* the navigationBar.
//        self.navigationController?.navigationBar.isTranslucent = false

        pagerNode.setDataSource(self)
        pagerNode.setDelegate(self)
        pagerNode.backgroundColor = Style.systemBackground
        pagerNode.showsHorizontalScrollIndicator = true

        self.setupHomeButton()
    }
}

//MARK: - DataSource
extension XDetailsPagerViewController: ASPagerDataSource {
    func numberOfPages(in pagerNode: ASPagerNode) -> Int {
        return items.count
    }

    func pagerNode(_ pagerNode: ASPagerNode, nodeAt index: Int) -> ASCellNode {
        return XDetailsNode(record: items[index], index: index, of: items.count, displayOptions: displayOptions)
    }
}

//MARK: - Delegate
extension XDetailsPagerViewController: ASPagerDelegate {
/*
    func collectionNode(_ collectionNode: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        guard let row = node.indexPath?.row else { return }
        if !firstAppearance {
            selectedItem = row
        }
    }
*/
}
