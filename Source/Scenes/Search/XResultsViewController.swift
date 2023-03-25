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

class XResultsViewController: ASDKViewController<ASTableNode> {
    
    //MARK: - Properties
    
    var activityIndicator: UIActivityIndicatorView!

    let headerNode = ASTextNode()
    var searchParameters: SearchParameters?
    var items: [AsyncRecord] = []
    var selectedItem: AsyncRecord?
    var startOfSearch = Date()
    var didCompleteSearch = false

    private var tableNode: ASTableNode {
        return node
    }
    
    //MARK: - Lifecycle

    override init() {
        super.init(node: ASTableNode(style: .plain))
        self.title = "Results"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    // NB: viewDidLoad on an ASDKViewController gets called during construction,
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
        tableNode.backgroundColor = Style.secondarySystemGroupedBackground
        tableNode.view.separatorStyle = .singleLine
        if #available(iOS 15.0, *) {
            // remove extra padding added in iOS 15
            tableNode.view.sectionHeaderTopPadding = 0
        }
        
        // setting an empty UIView as the footer prevents the display of ghost rows at the end of the table
        tableNode.view.tableFooterView = UIView()
        
        self.setupHomeButton()
        
        self.activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        Style.styleActivityIndicator(activityIndicator)
        self.node.view.addSubview(activityIndicator)
    }
    
    // NB: we position the activityIndicator y to 1/3 the height of the node's frame,
    // when you think it should be 1/2.  But setting it to 1/2 made it appear 2/3
    // of the way down.  I don't like it but it's good enough for now.
    func centerActivityIndicator(inFrame bounds: CGRect) {
        var frame = activityIndicator.frame
        //print("yyy frame was  \(frame)")
        frame.origin = CGPoint(x: (bounds.width - frame.width) / 2.0, y: (bounds.height - frame.height) / 3.0)
        //print("yyy set origin to \(frame.origin)")
        activityIndicator.frame = frame
    }
    
    //MARK: - Functions
    
    func fetchData() {
        if didCompleteSearch {
            return
        }
        guard let query = getQueryString() else {
            return
        }
        
        print("--- fetchData query:\(query)")
        activityIndicator.startAnimating()
        startOfSearch = Date()

        // search
        let options: [String: Int] = ["limit": App.config.searchLimit, "offset": 0]
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 1], shouldCache: true)
        req.gatewayOptionalObjectResponse().done { obj in
            let records: [AsyncRecord] = AsyncRecord.makeArray(fromQueryResponse: obj)
            self.updateItems(withRecords: records)
            let elapsed = -self.startOfSearch.timeIntervalSinceNow
            os_log("search.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
            return
        }.catch { error in
            self.updateTableSectionHeader(onError: error)
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }
    
//    func fetchRecordDetails(records: [MBRecord]) {
//        var promises: [Promise<Void>] = []
//        for record in records {
//            promises.append(SearchService.fetchRecordMODS(forRecord: record))
//            promises.append(PCRUDService.fetchMRA(forRecord: record))
//        }
//        print("xxx \(promises.count) promises made")
//
//        firstly {
//            when(fulfilled: promises)
//        }.done {
//            print("xxx \(promises.count) promises fulfilled")
//            self.activityIndicator.stopAnimating()
//            self.didCompleteSearch = true
//            let elapsed = -self.startOfSearch.timeIntervalSinceNow
//            os_log("search.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
//            self.updateItems(withRecords: records)
//        }.catch { error in
//            self.activityIndicator.stopAnimating()
//            self.updateTableSectionHeader(onError: error)
//            self.presentGatewayAlert(forError: error)
//        }
//    }
    
    // Force update of status string in table section header
    func updateTableSectionHeader(onError error: Error) {
        tableNode.reloadData()
    }

    func updateItems(withRecords records: [AsyncRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableNode.reloadData()
    }
    
    // Build query string, taken with a grain of salt from
    // https://wiki.evergreen-ils.org/doku.php?id=documentation:technical:search_grammar
    // e.g. "title:Harry Potter chamber of secrets search_format(book) site(MARLBORO)"
    func getQueryString() -> String? {
        guard let sp = searchParameters else {
            showAlert(title: "Internal Error", error: HemlockError.shouldNotHappen("Missing search parameters"))
            return nil
        }
        var query = "\(sp.searchClass):\(sp.text)"
        if let sf = sp.searchFormat, !sf.isEmpty {
            query += " search_format(\(sf))"
        }
        if let org = sp.organizationShortName, !org.isEmpty {
            query += " site(\(org))"
        }
        if let sort = sp.sort {
            query += " sort(\(sort))"
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
        guard items.count > indexPath.row else { return ASCellNode() }
        let record = items[indexPath.row]

//        os_log("[%s] row=%2d id=%d nodeForRowAt", log: Gateway.log, type: .info, Thread.current.tag(), indexPath.row, record.id)
        let node = XResultsTableNode(record: record, row: indexPath.row)
        return node
    }

    // TODO: evaluate whether this is faster
//    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
//        guard items.count > indexPath.row else { return { ASCellNode() } }
//        let record = items[indexPath.row]
//
//        // this may be executed on a background thread - it is important to make sure it is thread safe
//        let cellNodeBlock = { () -> ASCellNode in
//            os_log("[%s] row=%2d id=%d nodeForRowAt", log: Gateway.log, type: .info, Thread.current.tag(), indexPath.row, record.id)
//            return XResultsTableNode(record: record, row: indexPath.row)
//        }
//
//        return cellNodeBlock
//    }

    func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        guard let recordNode = node as? XResultsTableNode else { return }
        os_log("[%s] row=%2d id=%d willDisplayRowWith", log: AsyncRecord.log, type: .info, Thread.current.tag(), recordNode.row, recordNode.record.id)
        _ = recordNode.record.startPrefetchRecordDetails()
    }

//    func tableNode(_ tableNode: ASTableNode, didEndDisplayingRowWith node: ASCellNode) {
//        guard let recordNode = node as? XResultsTableNode else { return }
//        os_log("[%s] row=%2d id=%d didEndDisplayingRowWith", log: AsyncRecord.log, type: .info, Thread.current.tag(), recordNode.row, recordNode.record.id)
//    }

    // NB: if you use this you have to perform batch completion; see ASTableNode.h
//    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
////        guard let recordNode = node as? XResultsTableNode else { return }
//        os_log("[%s] willBeginBatchFetchWith %@", log: AsyncRecord.log, type: .info, Thread.current.tag(), context)
//    }

    func titleForHeaderInSection() -> String {
        if activityIndicator?.isAnimating ?? false {
            return "Searching..."
        } else if items.count == 0 {
            if let searchClass = searchParameters?.searchClass,
               searchClass != SearchViewController.searchKeywordKeyword,
               let searchText = searchParameters?.text
            {
                return "No results for \(searchClass): \(searchText)"
            } else {
                return "No results"
            }
        } else {
            return "\(items.count) most relevant results"
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = Style.systemGroupedBackground
 
        let rect = CGRect(x: 8, y: 29, width: 320, height: 21)
        let label = UILabel(frame: rect)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Style.secondaryLabelColor
        label.text = titleForHeaderInSection()
        label.font = UIFont.systemFont(ofSize: Style.calloutSize, weight: .light).withSmallCaps

        view.addSubview(label)
        return view
    }
}

//MARK: - ASTableDelegate
extension XResultsViewController: ASTableDelegate {

    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: searchParameters?.organizationShortName)
        let vc = XDetailsPagerViewController(items: items, selectedItem: indexPath.row, displayOptions: displayOptions)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
