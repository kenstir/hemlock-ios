//
//  XResultsViewController.swift
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

class XResultsViewController: ASViewController<ASTableNode> {
    
    //MARK: - Properties
    
    var activityIndicator: UIActivityIndicatorView!
    let headerNode: ASTextNode = ASTextNode()
    var searchParameters: SearchParameters?
    var items: [ResultRecord] = []
    var selectedItem: ResultRecord?

    private var tableNode: ASTableNode {
        return node
    }
    
    //MARK: - Lifecycle

    init() {
        super.init(node: ASTableNode(style: .plain))
        self.title = "XSearch Results"
        self.setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    override func viewWillAppear(_ animated: Bool) {
        print("--- viewWillAppear")
        print("--- searchParams \(String(describing: searchParameters))")
        super.viewWillAppear(animated)
        
        if let indexPath = tableNode.indexPathForSelectedRow {
            tableNode.deselectRow(at: indexPath, animated: true)
        }
        self.fetchData()
    }
    
    override func viewDidLoad() {
        print("--- viewDidLoad")
        print("--- searchParams \(String(describing: searchParameters))")
        super.viewDidLoad()
        self.setupNodesOnLoad()
    }

    //MARK: - Setup

    func setupNodes() {
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = UIColor.white
        tableNode.view.separatorStyle = .singleLine
        
        self.updateHeaderText()

        // setting an empty UIView as the footer prevents the display of ghost rows at the end of the table
        tableNode.view.tableFooterView = UIView()
    }
    
    func setupNodesOnLoad() {
        setupActivityIndicator()
    }
    
    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        let bounds = self.node.frame
        var refreshRect = activityIndicator.frame
        refreshRect.origin = CGPoint(x: (bounds.size.width - activityIndicator.frame.width) / 2.0, y: (bounds.size.height - activityIndicator.frame.height) / 2.0)
        activityIndicator.frame = refreshRect
        self.node.view.addSubview(activityIndicator)
        Style.styleActivityIndicator(activityIndicator)
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken else {
            showAlert(error: HemlockError.sessionExpired())
            return
        }
        guard let query = getQueryString() else {
            showAlert(title: "Internal Error", message: "No search parameters")
            return
        }
        
        print("--- fetchData query:\(query)")
        activityIndicator.startAnimating()

        // search
        let options: [String: Int] = ["limit": 200/*TODO*/, "offset": 0]
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 1])
        req.gatewayObjectResponse().done { obj in
            var records = ResultRecord.makeArray(fromQueryResponse: obj)
            if records.count == 0 {
                self.updateItems(withRecords: records)
                return
            }
            self.activityIndicator.stopAnimating()
            self.updateItems(withRecords: records)
//            self.fetchResultRecords(authtoken: authtoken, fromObject: obj)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    /*
    func fetchResultRecords(authtoken: String, fromObject obj: OSRFObject) {
        let ids = obj.getIDList("overdue") + obj.getIDList("out")
        var records: [ResultRecord] = []
        var promises: [Promise<Void>] = []
        for id in ids {
            let record = ResultRecord(id: id)
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
    }
 */
    
    /*
    func fetchCircDetails(authtoken: String, forRecord record: ResultRecord) -> Promise<Void> {
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

    func updateItems(withRecords records: [ResultRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        updateHeaderText()
        tableNode.reloadData()
    }
    
    func updateHeaderText() {
        var str: String
        if items.count == 0 {
            str = "No results"
        } else {
            str = "\(items.count) most relevant results"
        }
        headerNode.attributedText = NSAttributedString(string: str, attributes: self.headerTextAttributes())
    }
    
    private var headerTextAttributes = {
        return [NSAttributedStringKey.foregroundColor: UIColor.darkGray, NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    // Build query string, taken with a grain of salt from
    // https://wiki.evergreen-ils.org/doku.php?id=documentation:technical:search_grammar
    // e.g. "title:Harry Potter chamber of secrets search_format(book) site(MARLBORO)"
    func getQueryString() -> String? {
        guard let sp = searchParameters else {
            self.showAlert(title: "Internal Error", message: "No search parameters")
            return nil
        }
        var query = "\(sp.searchClass):\(sp.text)"
        if let sf = sp.searchFormat, !sf.isEmpty {
            query += " search_format(\(sf))"
        }
        if let org = sp.organizationShortName, !org.isEmpty {
            query += " site(\(org))"
        }
        return query
    }
}

//MARK: - ASTableDataSource
extension XResultsViewController: ASTableDataSource {
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let record = items[indexPath.row]
        let node = XResultsTableNode(record: record)
        return node
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Items checked out: \(items.count)"
    }
}

//MARK: - ASTableDelegate
extension XResultsViewController: ASTableDelegate {

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let tn = (tableNode.nodeForRow(at: indexPath) as! XResultsTableNode)
        debugPrint(tn)
        let item = items[indexPath.row]
        selectedItem = item
        
        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController(),
            let detailsVC = vc as? DetailsViewController,
            let mvrObj = selectedItem?.mvrObj
        {
            let record = MBRecord(mvrObj: mvrObj)
            detailsVC.item = record
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
