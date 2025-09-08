//
//  CopyInfoViewController.swift
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

import UIKit
import os.log

class CopyInfoViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var placeHoldButton: UIButton!
    
    var org: Organization?
    var record: MBRecord?
    var items: [CopyLocationCounts] = []
    var didCompleteFetch = false
    
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
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView() // prevent display of ghost rows at end of table
        self.setupHomeButton()
        
        Style.styleButton(asInverse: placeHoldButton)
        placeHoldButton.addTarget(self, action: #selector(placeHoldPressed(sender:)), for: .touchUpInside)
    }

    @MainActor
    func fetchData() async {
        let searchOrg = self.org ?? Organization.find(byId: Organization.consortiumOrgID)
        guard let recordID = record?.id,
            let org = searchOrg else
        {
            self.showAlert(title: "Error", error: HemlockError.shouldNotHappen("Missing record ID or search org"))
            return
        }

        do {
            let resp = try await SearchService.fetchCopyLocationCounts(recordID: recordID, org: org)
            self.items = CopyLocationCounts.makeArray(fromPayload: resp.payload)
            self.updateItems()
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    func updateItems() {
        self.didCompleteFetch = true
        table.reloadData()
    }

    @objc func placeHoldPressed(sender: UIButton) {
        guard let record = self.record else { return }
        guard let vc = PlaceHoldViewController.make(record: record) else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: - UITableViewDataSource

extension CopyInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return record?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "copyInfoCell", for: indexPath) as? CopyInfoTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.headingLabel.text = item.copyInfoHeading
        cell.subheadingLabel.text = item.copyInfoSubheading
        cell.locationLabel.text = item.shelvingLocation
        cell.callNumberLabel.text = item.callNumber
        cell.copyInfoLabel.text = item.countsByStatusLabel
        cell.accessoryType = (App.config.enableCopyInfoWebLinks ? .disclosureIndicator : .none)
        
        return cell
    }
}

//MARK: - UITableViewDelegate

extension CopyInfoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return App.config.enableCopyInfoWebLinks
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if let vc = UIStoryboard(name: "OrgDetails", bundle: nil).instantiateInitialViewController() as? OrgDetailsViewController {
            vc.orgID = item.orgID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

