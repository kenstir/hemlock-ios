//
//  MainViewController.swift
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
/*
import AsyncDisplayKit

class MainViewController: ASViewController<ASTableNode> {
    var buttons: [MainButtonCellNode.Type]
    
    init() {
        self.buttons = [
            ItemsCheckedOutButton.self
        ]

        super.init(node: ASTableNode(style: .plain))
        
        self.title = AppSettings.appTitle
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//        node.view.separatorStyle = .none
        node.delegate = self
        node.dataSource = self
//        node.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        if let indexPath = tableNode.indexPathForSelectedRow {
//            tableNode.deselectRow(at: indexPath, animated: true)
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupData()
    }
    
    func setupData() {
        var childNode: ASDisplayNode?

    }
}

extension MainViewController: ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let node = MainButtonCellNode(type: buttons[indexPath.row])
        return node
    }
}

extension MainViewController: ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let tn = (tableNode.nodeForRow(at: indexPath) as! MainButtonCellNode)
        debugPrint(tn)
//        let detail = LayoutExampleViewController(layoutExampleType: layoutExampleType)
//        self.navigationController?.pushViewController(detail, animated: true)
    }
}
*/
