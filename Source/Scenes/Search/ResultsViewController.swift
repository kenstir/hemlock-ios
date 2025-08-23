//  Copyright (C) 2023 Kenneth H. Cox
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

import PromiseKit
import PINRemoteImage
import PMKAlamofire
import UIKit
import os.log

class ResultsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    weak var activityIndicator: UIActivityIndicatorView!

    var searchParameters: SearchParameters?
    var items: [AsyncRecord] = []
    var selectedItem: AsyncRecord?
    var startOfSearch = Date()
    var didCompleteSearch = false

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // deselect row when navigating back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        Task { await self.fetchData() }
    }

    //MARK: - Functions

    func setupViews() {
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.delegate = self

        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()
    }

    @MainActor
    func fetchData() async {
        if didCompleteSearch {
            return
        }
        guard let query = getQueryString() else { return }

        //centerSubview(activityIndicator)
        activityIndicator.startAnimating()
        startOfSearch = Date()

        // search
        do {
            let options: [String: Int] = ["limit": App.config.searchLimit, "offset": 0]
            let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 1], shouldCache: true)
            let obj = try await req.gatewayResponseAsync().asObjectOrNil()

            let elapsed = -self.startOfSearch.timeIntervalSinceNow
            os_log("query.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
            let records: [AsyncRecord] = AsyncRecord.makeArray(fromQueryResponse: obj)
            Task { await self.fetchRecordDetails(records: records) }
            self.logSearchEvent(numResults: records.count)
            self.didCompleteSearch = true
        } catch {
            self.updateTableSectionHeader(onError: error)
            self.logSearchEvent(withError: error)
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()
    }

    @MainActor
    func fetchRecordDetails(records: [AsyncRecord]) async {
        // Select subset of records to preload in a batch, or else they will get loaded
        // individually on demand by cellForRowAt.
        let maxRecordsToPreload = 6 // best estimate is 5 on screen + 1 partial
        let preloadedRecords = records.prefix(maxRecordsToPreload)
        print("\(Utils.tt) fetchRecordDetails first \(preloadedRecords.count)")

        // Prefetch
        do {
            await withTaskGroup(of: Void.self) { group in
                for record in preloadedRecords {
                    group.addTask { await record.prefetch() }
                }
                await group.waitForAll()
            }
            self.updateItems(withRecords: records)
        }

        let elapsed = -self.startOfSearch.timeIntervalSinceNow
        os_log("preload details elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
    }

    // Force update of status string in table section header
    func updateTableSectionHeader(onError error: Error) {
        tableView.reloadData()
    }

    func updateItems(withRecords records: [AsyncRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
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

    func logSearchEvent(withError error: Error? = nil, numResults: Int = 0) {
        guard let sp = searchParameters else { return }
        let selectedOrg = Organization.find(byShortName: sp.organizationShortName)
        let defaultOrg = Organization.find(byId: App.account?.searchOrgID)
        let homeOrg = Organization.find(byId: App.account?.homeOrgID)
        var params: [String: Any] = [
            Analytics.Param.searchClass: sp.searchClass,
            Analytics.Param.searchFormat: sp.searchFormat ?? Analytics.Value.unset,
            Analytics.Param.searchOrgKey: Analytics.orgDimension(selectedOrg: selectedOrg, defaultOrg: defaultOrg, homeOrg: homeOrg)
        ]
        Analytics.searchTermParameters(searchTerm: sp.text).forEach {
            params[$0] = $1
        }
        if let err = error {
            params[Analytics.Param.result] = err.localizedDescription
        } else {
            params[Analytics.Param.result] = Analytics.Value.ok
            params[Analytics.Param.numResults] = numResults
        }
        Analytics.logEvent(event: Analytics.Event.search, parameters: params)
    }
}

//MARK: - UITableViewDataSource

extension ResultsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if activityIndicator?.isAnimating ?? false && !didCompleteSearch {
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("\(Utils.tt) row=\(String(format: "%2d", indexPath.row)) cellForRowAt")
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultsCell", for: indexPath) as! ResultsTableViewCell
        guard items.count > indexPath.row else { return cell }
        let record = items[indexPath.row]

        // load the data if not already loaded
        if record.isLoaded() {
            setCellMetadata(cell, forRecord: record)
        } else {
            // Clear reused cells immediately or else it appears the titles
            // change as you scroll fast
            setCellMetadata(cell, forRecord: nil)

            // async load the metadata
            Task {
                await record.prefetch()
                self.setCellMetadata(cell, forRecord: record)
            }
        }

        // async load the image
        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/small/r/" + String(record.id)) {
            cell.coverImage.pin_setImage(from: url)
        }

        return cell
    }

    func setCellMetadata(_ cell: ResultsTableViewCell, forRecord record: AsyncRecord?) {
        cell.title.text = record?.title
        cell.author.text = record?.author
        cell.format.text = record?.iconFormatLabel
        cell.pubinfo.text = record?.pubinfo
    }
}

//MARK: - UITableViewDataSourcePrefetching

extension ResultsViewController : UITableViewDataSourcePrefetching {
    // TODO: if prefetching is necessary to prevent hitching do it here; if not save the extra network requests
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("\(Utils.tt) prefetchRowsAt \(indexPaths.count) rows")
        for indexPath in indexPaths {
            guard items.count > indexPath.row else { return }
            let record = items[indexPath.row]
            Task { await record.prefetch() }
        }
    }
}

//MARK: - UITableViewDelegate

extension ResultsViewController : UITableViewDelegate {
    // Some iOS update shrunk the default height of grouped tables, so we need this
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: searchParameters?.organizationShortName)
        if let vc = XUtils.makeDetailsPager(items: items, selectedItem: indexPath.row, displayOptions: displayOptions) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
