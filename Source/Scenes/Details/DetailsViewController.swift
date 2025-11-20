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

import UIKit

class DetailsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var headerRow: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorButton: UIButton!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var pubinfoLabel: UILabel!
    @IBOutlet weak var physicalDescriptionLabel: UILabel!
    @IBOutlet weak var copySummaryLabel: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var placeHoldButton: UIButton!
    @IBOutlet weak var copyInfoButton: UIButton!
    @IBOutlet weak var addToListButton: UIButton!
    @IBOutlet weak var onlineAccessButton: UIButton!
    @IBOutlet weak var synopsisLabel: UILabel!
    @IBOutlet weak var extrasRow: UIView!
    @IBOutlet weak var extrasButton: UIButton!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var isbnLabel: UILabel!

    var record: BibRecord!
    var row: Int = 0
    var count: Int = 0
    var displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)

    private var showExtrasButton: Bool { return App.config.detailsExtraLinkText != nil }

    //MARK: - Lifecycle

    static func make(record: BibRecord, row: Int, count: Int, displayOptions: RecordDisplayOptions) -> DetailsViewController? {
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
        Task { await self.fetchData() }
    }

    //MARK: - Functions

    func setupViews() {
        setupPageHeader()
        setupImage()
        setupButtons()
        setupAsyncViews()
        setupExtrasButton()
        setupOtherRecordLabels()
    }

    // these views get setup twice: once during viewDidLoad,
    // and again after the record metadata is fully loaded
    func setupAsyncViews() {
        setupInfoVStack()
        setupCopySummary()
        updateButtonViews()
    }

    private func setupPageHeader() {
        let naturalNumber = row + 1
        let str = "Showing Item \(naturalNumber) of \(count)"
        headerLabel.text = str
        Style.styleLabel(asTableHeader: headerLabel)
        Style.styleView(asTableHeader: headerRow)
    }

    private func setupInfoVStack() {
        titleLabel.text = record.title
        formatLabel.text = record.iconFormatLabel
        pubinfoLabel.text = record.pubinfo
        physicalDescriptionLabel.text = record.physicalDescription

        Style.styleButton(asPlain: authorButton, trimLeadingInset: true)
        authorButton.setTitle(record.author, for: .normal)
        authorButton.addTarget(self, action: #selector(authorPressed(sender:)), for: .touchUpInside)
    }

    private func setupOtherRecordLabels() {
        synopsisLabel.text = record.synopsis
        subjectLabel.text = record.subject
        isbnLabel.text = record.isbn
    }

    private func setupImage() {
        // async load the image
        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/medium/r/" + String(record.id)) {
            coverImage.pin_setImage(from: url)
        }
    }

    private func setupCopySummary() {
        var str = ""
        if record.isDeleted {
            str = "[ item is marked deleted in the database ]"
        } else if App.behavior.isOnlineResource(record: record) {
            if let onlineLocation = record.firstOnlineLocation,
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

    private func setupButtons() {
        placeHoldButton.addTarget(self, action: #selector(placeHoldPressed(sender:)), for: .touchUpInside)
        copyInfoButton.addTarget(self, action: #selector(copyInfoPressed(sender:)), for: .touchUpInside)
        addToListButton.addTarget(self, action: #selector(addToListPressed(sender:)), for: .touchUpInside)
        onlineAccessButton.addTarget(self, action: #selector(onlineAccessPressed(sender:)), for: .touchUpInside)

        Style.styleButton(asInverse: placeHoldButton)
        Style.styleButton(asOutline: copyInfoButton)
        Style.styleButton(asOutline: addToListButton)
        Style.styleButton(asPlain: onlineAccessButton)
    }

    private func updateButtonViews() {
        print("updateButtonViews: title:\(record.title)")
        if record.isDeleted {
            placeHoldButton.isEnabled = false
            copyInfoButton.isEnabled = false
            addToListButton.isEnabled = false
            return
        }

        let org = Organization.find(byShortName: displayOptions.orgShortName)
        let links = App.behavior.onlineLocations(record: record, forSearchOrg: org?.shortname)
        let numCopies = record.totalCopies(atOrgID: org?.id)
        print("updateButtonViews: title:\(record.title) links:\(links.count) copies:\(numCopies)")

        if numCopies > 0 {
            placeHoldButton.isEnabled = displayOptions.enablePlaceHold
            copyInfoButton.isEnabled = true
        } else {
            placeHoldButton.isEnabled = false
            copyInfoButton.isEnabled = false
        }

        onlineAccessButton.isHidden = !(links.count > 0)
        onlineAccessButton.isEnabled = (links.count > 0)
    }

    func setupExtrasButton() {
        if !showExtrasButton {
            extrasButton.isHidden = true
            return
        }

        extrasButton.setTitle(App.config.detailsExtraLinkText, for: .normal)
        extrasButton.addTarget(self, action: #selector(extrasPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asPlain: extrasButton)
    }

    func have(_ val: Any?) -> String {
        if val != nil {
            return "YES"
        }
        return "nil"
    }

    @MainActor
    func fetchData() async {
        let orgID = Organization.find(byShortName: displayOptions.orgShortName)?.id ?? Organization.consortiumOrgID

        do {
            print("record.hasAttrs:    \(record.hasAttributes)")
            print("record.hasMARC:     \(record.hasMARC)")
            print("record.hasMetadata: \(record.hasMetadata)")
            async let details: Void = App.serviceConfig.biblioService.loadRecordDetails(forRecord: record, needMARC: App.config.needMARCRecord)
            async let attrs: Void = App.serviceConfig.biblioService.loadRecordAttributes(forRecord: record)
            async let ccounts: Void = App.serviceConfig.biblioService.loadRecordCopyCounts(forRecord: record, orgId: orgID)
            let _ = try await (details, attrs, ccounts)
        } catch {
            presentGatewayAlert(forError: error)
        }

        setupAsyncViews()
    }

    //MARK: - Actions

    @objc func onlineAccessPressed(sender: UIButton) {
        let links = App.behavior.onlineLocations(record: record, forSearchOrg: displayOptions.orgShortName)
        guard links.count > 0 else { return }

        // If there's only one link, open it without ceremony
        if links.count == 1 && !App.config.alwaysUseActionSheetForOnlineLinks {
            openOnlineLocation(vc: self, href: links[0].href)
            return
        }

        // Build an action sheet to present the links
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        for link in links {
            alertController.addAction(UIAlertAction(title: link.text, style: .default) { action in
                self.openOnlineLocation(vc: self, href: link.href)
            })
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            let view: UIView = sender as UIView
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        self.present(alertController, animated: true)
    }

    @objc func placeHoldPressed(sender: Any) {
        guard let vc = PlaceHoldViewController.make(record: record) else { return }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func copyInfoPressed(sender: Any) {
        let org = Organization.find(byShortName: self.displayOptions.orgShortName) ?? Organization.consortium()
        guard let vc = UIStoryboard(name: "CopyInfo", bundle: nil).instantiateInitialViewController() as? CopyInfoViewController else { return }

        vc.org = org
        vc.record = record
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func addToListPressed(sender: Any) {
        // TODO: load bookbags if not already loaded
        if App.account?.bookBagsEverLoaded == true {
            addToList()
            return
        }

        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }

        // fetch the list of bookbags
        Task { await fetchPatronLists(account: account) }
    }

    @MainActor
    func fetchPatronLists(account: Account) async {
        do {
            try await App.serviceConfig.userService.loadPatronLists(account: account)
            self.addToList()
        } catch {
            presentGatewayAlert(forError: error, title: "Error fetching lists")
        }
    }

    func addToList() {
        guard let bookBags = App.account?.bookBags,
              bookBags.count > 0 else
        {
            navigationController?.view.makeToast("No lists")
            return
        }

        // Build an action sheet to display the options
        let alertController = UIAlertController(title: "Add to List", message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        for bookBag in bookBags {
            alertController.addAction(UIAlertAction(title: bookBag.name, style: .default) { action in
                Task { await self.addItem(toBookBag: bookBag) }
            })
        }
//        alertController.addAction(UIAlertAction(title: "Add to New List", style: .default) { action in
//            showAlert(title: "TODO", message: "create new")
//        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alertController.popoverPresentationController {
            let view: UIView = self.view
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        self.present(alertController, animated: true)
    }

    @MainActor
    func addItem(toBookBag bookBag: BookBag) async {
        guard let account = App.account else { return }

        do {
            try await App.serviceConfig.userService.addItemToPatronList(account: account, listId: bookBag.id, recordId: record.id)
            Analytics.logEvent(event: Analytics.Event.bookbagAddItem, parameters: [Analytics.Param.result: Analytics.Value.ok])
            self.navigationController?.view.makeToast("Item added to list")
        } catch {
            Analytics.logEvent(event: Analytics.Event.bookbagAddItem, parameters: [Analytics.Param.result: error.localizedDescription])
            self.presentGatewayAlert(forError: error)
        }
    }

    @objc func authorPressed(sender: Any) {
        if let mainVC = self.navigationController?.viewControllers.first,
           let searchVC = UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as? SearchViewController {
            searchVC.authorToSearchFor = self.record.author
            self.navigationController?.viewControllers = [mainVC, searchVC]
        }
    }

    @objc func extrasPressed(sender: Any) {
        var url = App.config.url + "/eg/opac/record/" + String(record.id)
        if let q = App.config.detailsExtraLinkQuery {
            url += "?" + q
        }
        if let fragment = App.config.detailsExtraLinkFragment {
            url += "#" + fragment
        }
        self.openOnlineLocation(vc: self, href: url)
    }

    func openOnlineLocation(vc: UIViewController, href: String) {
        guard let url = URL(string: href) else {
            vc.showAlert(title: "Error parsing URL", message: "Unable to parse online location \(href)")
            return
        }
        UIApplication.shared.open(url)
    }
}
