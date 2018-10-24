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

class XDetailsPagerViewController: ASViewController<ASPagerNode> {
    
    //MARK: - Properties
    
    var items: [MBRecord] = []
    var selectedItem = 0

    private var pagerNode: ASPagerNode {
        return node
    }

    //MARK: - Lifecycle
    
    init(items: [MBRecord], selectedItem: Int) {
        super.init(node: ASPagerNode())
        self.title = "Item Details"
        self.items = items
        self.selectedItem = selectedItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNodes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        pagerNode.scrollToPage(at: selectedItem, animated: false)
    }
    
    //MARK: - Setup
    
    func setupNodes() {
        self.automaticallyAdjustsScrollViewInsets = false
        debugPrint(self.navigationController?.navigationBar.isTranslucent)
        self.navigationController?.navigationBar.isTranslucent = false
        self.node.backgroundColor = UIColor.cyan

        pagerNode.setDataSource(self)
        pagerNode.setDelegate(self)
        pagerNode.backgroundColor = UIColor.white
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
        let node = XDetailsNode(record: items[index], index: index, of: items.count)

        // not sure about this
//        debugPrint(pagerNode.bounds)
//        node.style.preferredSize = pagerNode.bounds.size
        
        return node
    }
}

//MARK: - Delegate
extension XDetailsPagerViewController: ASPagerDelegate {
    // TODO
}
