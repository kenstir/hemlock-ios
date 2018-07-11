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
    var startOfSearch = Date()
    var didCompleteSearch = false

    private var tableNode: ASTableNode {
        return node
    }
    
    //MARK: - Lifecycle

    init() {
        super.init(node: ASTableNode(style: .plain))
        self.title = "Results"
        self.setupNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here; fetch it in viewDidAppear.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNodesOnLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableNode.indexPathForSelectedRow {
            tableNode.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.fetchData()
    }

    //MARK: - Setup

    func setupNodes() {
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = UIColor.white
        tableNode.view.separatorStyle = .singleLine
        
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
        if didCompleteSearch {
            return
        }
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
        startOfSearch = Date()

        // search
        let options: [String: Int] = ["limit": 200/*TODO*/, "offset": 0]
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 1])
        req.gatewayObjectResponse().done { obj in
            let records = ResultRecord.makeArray(fromQueryResponse: obj)
            self.fetchRecordMVRs(authtoken: authtoken, records: records)
            return
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchRecordMVRs(authtoken: String, records: [ResultRecord]) {
        var promises: [Promise<Void>] = []
        for record in records {
            let promise = fetchRecordMVR(authtoken: authtoken, forRecord: record)
            promises.append(promise)
        }
        print("xxx \(promises.count) promises made")

        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.activityIndicator.stopAnimating()
            self.didCompleteSearch = true
            let elapsed = -self.startOfSearch.timeIntervalSinceNow
            os_log("search.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
            self.updateItems(withRecords: records)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchRecordMVR(authtoken: String, forRecord record: ResultRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [record.id])
        let promise = req.gatewayObjectResponse().done { obj in
            print("xxx \(record.id) recordModsRetrieve done")
            record.mvrObj = obj
        }
        return promise
    }

    func updateItems(withRecords records: [ResultRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableNode.reloadData()
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
        if !didCompleteSearch {
            return ""
        } else if items.count == 0 {
            return "No results"
        } else {
            return "\(items.count) most relevant results"
        }
    }
}

//MARK: - ASTableDelegate
extension XResultsViewController: ASTableDelegate {

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let tn = (tableNode.nodeForRow(at: indexPath) as! XResultsTableNode)
        debugPrint(tn)
        let item = items[indexPath.row]
        selectedItem = item
        
//        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController(),
//            let detailsVC = vc as? DetailsViewController,
//            let mvrObj = selectedItem?.mvrObj
//        {
//            detailsVC.item = record
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
}
