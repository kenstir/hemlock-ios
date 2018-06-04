//
//  ListsViewController.swift
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

class XCheckoutsViewController: ASViewController<ASTableNode> {
    
    //MARK: - Properties
    
    private let headerNode: ASTextNode = ASTextNode()
    var items: [CircRecord] = []
    private var tableNode: ASTableNode {
        return node
    }
    
    //MARK: - Lifecycle

    init() {
        super.init(node: ASTableNode(style: .plain))
        self.title = "Items Checked Out"
        self.setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableNode.indexPathForSelectedRow {
            tableNode.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData()
    }

    //MARK: - Setup

    func setupNodes() {
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = UIColor.white
        tableNode.view.separatorStyle = .singleLine
        
        // tableHeaderView is not accessible; see Texture #143
        tableNode.view.tableHeaderView = headerNode.view
        tableNode.view.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: 320, height: 48) // todo ???
        headerNode.maximumNumberOfLines = 1
        headerNode.truncationMode = .byTruncatingTail
        self.updateHeaderText()

        // setting an empty UIView as the footer prevents the display of ghost rows at the end of the table
        tableNode.view.tableFooterView = UIView()
    }
    
    func setupData() {
        for i in 0...4 {
            let circRecord = CircRecord(id: i)
            circRecord.mvrObj = OSRFObject(["title": "Project Management for Dummies \(i)", "author": "Various"])
            items.append(circRecord)
        }
    }
    
    func updateHeaderText() {
        headerNode.attributedText = NSAttributedString(string: "Items checked out: \(items.count)", attributes: self.headerTextAttributes())
    }
    
    private var headerTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.black, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]

    }
}

//MARK: - ASTableDataSource

extension XCheckoutsViewController: ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let circRecord = items[indexPath.row]
        let node = XCheckoutsTableNode(circRecord: circRecord)
        return node
    }
}

//MARK: - ASTableDelegate

extension XCheckoutsViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let tn = (tableNode.nodeForRow(at: indexPath) as! XCheckoutsTableNode)
        debugPrint(tn)
        //let vc = XViewController(layoutExampleType: layoutExampleType)
        //self.navigationController?.pushViewController(vc, animated: true)
    }
}
