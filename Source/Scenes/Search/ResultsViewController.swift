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

        print("--- fetchData query:\(query)")
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
        }.catch { error in
            self.updateTableSectionHeader(onError: error)
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }

    func fetchRecordDetails(records: [AsyncRecord]) {
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        var promises: [Promise<Void>] = []
        promises.append(PCRUDService.fetchCodedValueMaps())
        for record in records {
            promises.append(contentsOf: record.startPrefetch())
        }
        print("xxx \(promises.count) promises made")

        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.didCompleteSearch = true
            for record in records {
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultsCell", for: indexPath) as? ResultsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        os_log("[%s] row=%02d cellForRowAt", log: AsyncRecord.log, type: .info, Thread.current.tag(), indexPath.row)
        guard items.count > indexPath.row else { return cell }
        let record = items[indexPath.row]

        cell.title.text = record.title
        cell.author.text = record.author
        cell.format.text = record.iconFormatLabel
        cell.pubinfo.text = record.pubinfo

        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/small/r/" + String(record.id)) {
            cell.coverImage.pin_setImage(from: url)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

//MARK: - UITableViewDataSourcePrefetching

extension ResultsViewController : UITableViewDataSourcePrefetching {
    // TODO: if prefetching is necessary to prevent hitching do it here; if not save the extra network requests
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if let first = indexPaths.first,
           let last = indexPaths.last {
            let firstRow = items[first.row].row
            let lastRow = items[last.row].row
            os_log("[%s] rows=%d..%d prefetchRowsAt", log: AsyncRecord.log, type: .info, Thread.current.tag(), firstRow, lastRow)
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
        let vc = XDetailsPagerViewController(items: items, selectedItem: indexPath.row, displayOptions: displayOptions)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
