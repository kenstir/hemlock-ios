//
//  XCheckoutsViewController.swift
//  X is for teXture
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

class XCheckoutsViewController: ASViewController<ASTableNode> {
    
    //MARK: - Properties
    
    private let headerNode: ASTextNode = ASTextNode()
    var items: [CircRecord] = []
    var selectedItem: CircRecord?

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
    
    //MARK: - ViewController
    
    override func viewWillAppear(_ animated: Bool) {
        print("XXX viewWillAppear")
        super.viewWillAppear(animated)
        
        if let indexPath = tableNode.indexPathForSelectedRow {
            tableNode.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidLoad() {
        print("XXX viewDidLoad")
        super.viewDidLoad()
        self.fetchData()
    }

    //MARK: - Setup

    func setupNodes() {
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = UIColor.white
        tableNode.view.separatorStyle = .singleLine
        
        // tableHeaderView is not accessible; see Texture #143
        /*
        tableNode.view.tableHeaderView = headerNode.view
        tableNode.view.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: 320, height: 48) // todo ???
        headerNode.maximumNumberOfLines = 1
        headerNode.truncationMode = .byTruncatingTail
        */
        self.updateHeaderText()

        // setting an empty UIView as the footer prevents the display of ghost rows at the end of the table
        // TODO: factor out as UITableView extension
        tableNode.view.tableFooterView = UIView()
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(error: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        //activityIndicator.startAnimating()

        // fetch the list of items
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userid])
        req.gatewayObjectResponse().done { obj in
            self.fetchCircRecords(authtoken: authtoken, fromObject: obj)
        }.catch { error in
            //self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchCircRecords(authtoken: String, fromObject obj: OSRFObject) {
        /*
        let ids = obj.getIDList("overdue") + obj.getIDList("out")
        var records: [CircRecord] = []
        var promises: [Promise<Void>] = []
        for id in ids {
            let record = CircRecord(id: id)
            records.append(record)
            let promise = fetchCircDetails(authtoken: authtoken, forRecord: record)
            promises.append(promise)
        }
        print("xxx \(promises.count) promises made")

        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            //self.activityIndicator.stopAnimating()
            self.updateItems(withRecords: records)
        }.catch { error in
            //self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
        */
    }
    
    /*
    func fetchCircDetails(authtoken: String, forRecord record: CircRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, record.id])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            print("xxx \(record.id) circRetrieve done")
            record.circObj = obj
            guard let target = obj.getInt("target_copy") else {
                // TODO: add anayltics or, just let it throw?
                throw PMKError.cancelled
            }
            let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [target])
            return req.gatewayObjectResponse()
        }.done { obj in
            print("xxx \(record.id) modsFromCopy done")
            record.mvrObj = obj
        }
        return promise
    }
    */

    func updateItems(withRecords records: [CircRecord]) {
        // TODO: sort by due date
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        updateHeaderText()
        tableNode.reloadData()
    }
    
    func updateHeaderText() {
        headerNode.attributedText = NSAttributedString(string: "Items checked out: \(items.count)", attributes: self.headerTextAttributes())
    }
    
    private var headerTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Items checked out: \(items.count)"
    }
}

//MARK: - ASTableDelegate
extension XCheckoutsViewController: ASTableDelegate {

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let tn = (tableNode.nodeForRow(at: indexPath) as! XCheckoutsTableNode)
        debugPrint(tn)
        let item = items[indexPath.row]
        selectedItem = item
        
        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController(),
            let detailsVC = vc as? DetailsViewController,
            let metabibRecord = selectedItem?.metabibRecord
        {
            detailsVC.item = metabibRecord
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
