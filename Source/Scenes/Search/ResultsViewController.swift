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
import UIKit
import os.log

class ResultsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet var tableView: UITableView!
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

        // spike some fake data
        let ids = [
            1338419,
            2532415,
            1323791,
            4925739,
            6184453,
            2531937,
            2531538,
            2769194,
            2288759,
            2315122,
            5759294,
            2286966,
            2411394,
            4454010,
            4453951,
            2411409,
            4454005,
            1981694,
            2391387,
            1934220,
        ]
        var records: [AsyncRecord] = []
        for (row, id) in ids.enumerated() {
            records.append(AsyncRecord(id: id, row: row))
        }
        fetchRecordDetails(records: records)
    }

    func fetchRecordDetails(records: [AsyncRecord]) {
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        startOfSearch = Date()
        var promises: [Promise<Void>] = []
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
            os_log("search.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func updateItems(withRecords records: [AsyncRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "xxxCell", for: indexPath) as? ResultsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        os_log("[%s] row=%02d cellForRowAt", log: AsyncRecord.log, type: .info, Thread.current.tag(), indexPath.row)
        guard items.count > indexPath.row else { return cell }
        let record = items[indexPath.row]

        cell.textLabel?.text = record.title
        cell.detailTextLabel?.text = record.author

        return cell
    }

}

//MARK: - UITableViewDataSourcePrefetching

extension ResultsViewController : UITableViewDataSourcePrefetching {
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
}
