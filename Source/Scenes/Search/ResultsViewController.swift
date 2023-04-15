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
//import PMKFoundation
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

        self.fetchData()
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

    func fetchData() {
        if didCompleteSearch {
            return
        }
        guard let query = getQueryString() else { return }

        //centerSubview(activityIndicator)
        activityIndicator.startAnimating()
        startOfSearch = Date()

        // search
        let options: [String: Int] = ["limit": App.config.searchLimit, "offset": 0]
        let req = Gateway.makeRequest(service: API.search, method: API.multiclassQuery, args: [options, query, 1], shouldCache: true)
        req.gatewayOptionalObjectResponse().done { obj in
            let elapsed = -self.startOfSearch.timeIntervalSinceNow
            os_log("search.query: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
            let records: [AsyncRecord] = AsyncRecord.makeArray(fromQueryResponse: obj)
            self.fetchRecordDetails(records: records)
            self.didCompleteSearch = true
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.updateTableSectionHeader(onError: error)
            self.presentGatewayAlert(forError: error)
        }
    }

    func fetchRecordDetails(records: [AsyncRecord]) {
        activityIndicator.startAnimating()

        // Select subset of records to preload in a batch, or else they will get loaded
        // individually on demand by cellForRowAt.
        let maxRecordsToPreload = 6 // best estimate is 5 on screen + 1 partial
        let preloadedRecords = records.prefix(maxRecordsToPreload)
        os_log("[%s] fetchRecordDetails first %d records", log: AsyncRecord.log, type: .info, Thread.current.tag(), preloadedRecords.count)

        // Collect promises
        var promises: [Promise<Void>] = []
        promises.append(PCRUDService.fetchCodedValueMaps())
        for record in preloadedRecords {
            promises.append(contentsOf: record.startPrefetch())
        }

        firstly {
            when(fulfilled: promises)
        }.done {
            for record in preloadedRecords {
                record.markPrefetchDone()
            }
            self.updateItems(withRecords: records)
        }.ensure {
            self.activityIndicator.stopAnimating()
            let elapsed = -self.startOfSearch.timeIntervalSinceNow
            os_log("search.details: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
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
        os_log("[%s] row=%02d cellForRowAt", log: AsyncRecord.log, type: .info, Thread.current.tag(), indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultsCell", for: indexPath) as! ResultsTableViewCell
        guard items.count > indexPath.row else { return cell }
        let record = items[indexPath.row]

        // load the data if not already loaded
        if record.getState() == .loaded {
            setCellMetadata(cell, forRecord: record)
        } else {
            // Clear reused cells immediately or else it appears the titles
            // change as you scroll fast
            setCellMetadata(cell, forRecord: nil)

            // async load the metadata
            let promises = record.startPrefetch()
            firstly {
                when(fulfilled: promises)
            }.done {
                record.markPrefetchDone()
                self.setCellMetadata(cell, forRecord: record)
            }.ensure {
                self.activityIndicator.stopAnimating()
            }.catch { error in
                self.presentGatewayAlert(forError: error)
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
//        guard let first = indexPaths.first,
//              let last = indexPaths.last else { return }
//        let firstRow = items[first.row].row
//        let lastRow = items[last.row].row
//        os_log("[%s] rows=%d..%d prefetchRowsAt", log: AsyncRecord.log, type: .info, Thread.current.tag(), firstRow, lastRow)
        os_log("[%s] prefetchRowsAt %d rows", log: AsyncRecord.log, type: .info, Thread.current.tag(), indexPaths.count)
        for indexPath in indexPaths {
            guard items.count > indexPath.row else { return }
            let record = items[indexPath.row]

            if record.getState() == .initial {
                _ = record.startPrefetch()
            }
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
        if let vc = XDetailsPagerViewController.make(items: items, selectedItem: indexPath.row, displayOptions: displayOptions) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
