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

class DetailsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var headerRow: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var pubinfoLabel: UILabel!
    @IBOutlet weak var copySummaryLabel: UILabel!

    @IBOutlet weak var coverImage: UIImageView!

    var record = MBRecord(id: -1)
    var row: Int = 0
    var count: Int = 0
    var displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)

    //MARK: - Lifecycle

    static func make(record: MBRecord, row: Int, count: Int, displayOptions: RecordDisplayOptions) -> DetailsViewController? {
        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController() as? DetailsViewController {
            vc.record = record
            vc.row = row
            vc.count = count
            vc.displayOptions = displayOptions
            return vc
        }
        return nil
    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions

    func setupViews() {
        setupPageHeader()
        setupDetails()
        setupCopySummary()
    }

    func setupAsyncViews() {
        setupDetails()
        setupCopySummary()
    }

    private func setupPageHeader() {
        let naturalNumber = row + 1
        let str = "Showing Item \(naturalNumber) of \(count)"
        headerLabel.text = str
        Style.styleLabel(asTableHeader: headerLabel)
        Style.styleView(asTableHeader: headerRow)
    }

    private func setupDetails() {
        titleLabel.text = record.title
        author.text = record.author
        formatLabel.text = record.iconFormatLabel
        pubinfoLabel.text = record.pubinfo

        // async load the image
        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/medium/r/" + String(record.id)) {
            coverImage.pin_setImage(from: url)
        }
    }

    private func setupCopySummary() {
        var str = ""
        if App.behavior.isOnlineResource(record: record) {
            if let onlineLocation = record.firstOnlineLocationInMVR,
                let host = URL(string: onlineLocation)?.host,
                App.config.showOnlineAccessHostname
            {
                str = host
            }
        } else {
            if let copyCounts = record.copyCounts,
                let copyCount = copyCounts.last,
                let orgName = Organization.find(byId: copyCount.orgID)?.name
            {
                str = "\(copyCount.available) of \(copyCount.count) copies available at \(orgName)"
            }
        }
        copySummaryLabel.attributedText = Style.makeString(str, ofSize: Style.calloutSize)
    }

    func fetchData() {
        // Fetch orgs and copy statuses
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTree())
        promises.append(PCRUDService.fetchCodedValueMaps())
        promises.append(SearchService.fetchCopyStatusAll())

        // Fetch copy counts if not online resource
        if !App.behavior.isOnlineResource(record: record) {
            let orgID = Organization.find(byShortName: displayOptions.orgShortName)?.id ?? Organization.consortiumOrgID
            let promise = SearchService.fetchCopyCount(orgID: orgID, recordID: record.id)
            let done_promise = promise.done { array in
                self.record.copyCounts = CopyCount.makeArray(fromArray: array)
            }
            promises.append(done_promise)
        }

        // Fetch MARCXML record if needed
        if App.config.needMARCRecord {
            promises.insert(PCRUDService.fetchMARC(forRecord: record), at: 0)
        }

        // Fetch MRA if needed
        if record.attrs == nil {
            promises.append(PCRUDService.fetchMRA(forRecord: record))
        }

        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupAsyncViews()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
}
