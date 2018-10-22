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
    var items: [MBRecord] = []
    var selectedItem: MBRecord?
    var startOfSearch = Date()
    var didCompleteSearch = false

    private var tableNode: ASTableNode {
        return node
    }
    
    //MARK: - Lifecycle

    init() {
        super.init(node: ASTableNode(style: .plain))
        self.title = "Results"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        centerActivityIndicator(inFrame: self.node.frame)
        
        // deselect row when navigating back
        if let indexPath = tableNode.indexPathForSelectedRow {
            tableNode.deselectRow(at: indexPath, animated: true)
        }
        
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
        
        self.setupHomeButton()
        
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        Style.styleActivityIndicator(activityIndicator)
        self.node.view.addSubview(activityIndicator)
    }
    
    // NB: we position the activityIndicator y to 1/3 the height of the node's frame,
    // when you think it should be 1/2.  But setting it to 1/2 made it appear 2/3
    // of the way down.  I don't like it but it's good enough for now.
    func centerActivityIndicator(inFrame bounds: CGRect) {
        var frame = activityIndicator.frame
        print("yyy frame was  \(frame)")
        frame.origin = CGPoint(x: (bounds.width - frame.width) / 2.0, y: (bounds.height - frame.height) / 3.0)
        print("yyy set origin to \(frame.origin)")
        activityIndicator.frame = frame
    }
    
    //MARK: - Functions
    
    func fetchData() {
        if didCompleteSearch {
            return
        }
        guard let authtoken = App.account?.authtoken else {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
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
            let records = MBRecord.makeArray(fromQueryResponse: obj)
            self.fetchRecordMVRs(authtoken: authtoken, records: records)
            return
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchRecordMVRs(authtoken: String, records: [MBRecord]) {
        var promises: [Promise<Void>] = []
        for record in records {
            promises.append(fetchRecordMVR(authtoken: authtoken, forRecord: record))
            promises.append(PCRUDService.fetchSearchFormat(authtoken: authtoken, forRecord: record))
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
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchRecordMVR(authtoken: String, forRecord record: MBRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [record.id])
        let promise = req.gatewayObjectResponse().done { obj in
            print("xxx \(record.id) recordModsRetrieve done")
            record.mvrObj = obj
        }
        return promise
    }

    func updateItems(withRecords records: [MBRecord]) {
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
    
    //    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    //        return titleForHeaderInSection()
    //    }

    func titleForHeaderInSection() -> String {
        if !didCompleteSearch {
            return ""
        } else if items.count == 0 {
            return "No results"
        } else {
            return "\(items.count) most relevant results"
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = App.theme.tableHeaderBackground
 
        let rect = CGRect(x: 8, y: 29, width: 320, height: 21)
        let label = UILabel(frame: rect)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = App.theme.tableHeaderForeground
        label.text = titleForHeaderInSection()
        label.font = UIFont.systemFont(ofSize: 16, weight: .light).withSmallCaps

        view.addSubview(label)
        return view
    }
}

//MARK: - ASTableDelegate
extension XResultsViewController: ASTableDelegate {

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let vc = XDetailsPagerViewController(items: items, selectedItem: indexPath.row)
        self.navigationController?.pushViewController(vc, animated: true)

        /*
        let item = items[indexPath.row]
        selectedItem = item
        
        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController(),
            let detailsVC = vc as? DetailsViewController
        {
            detailsVC.item = selectedItem
            detailsVC.searchParameters = searchParameters
            self.navigationController?.pushViewController(vc, animated: true)
        }
        */
    }
}
