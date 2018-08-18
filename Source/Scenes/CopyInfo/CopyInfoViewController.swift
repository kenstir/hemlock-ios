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
        self.fetchData()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView() // prevent display of ghost rows at end of table
        self.setupHomeButton()
    }
    
    func fetchData() {
        let searchOrg = self.org ?? Organization.find(byId: Organization.consortiumOrgID)
        guard let recordID = record?.id,
            let org = searchOrg else
        {
            //TODO: analytics
            self.showAlert(title: "Internal Error", message: "No record or org to search")
            return
        }
        let promise = SearchService.fetchCopyLocationCounts(org: org, recordID: recordID)
        promise.done { resp, pmkresp in
            self.items = CopyLocationCounts.makeArray(fromPayload: resp.payload)
            self.updateItems()
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    func updateItems() {
        self.didCompleteFetch = true
        table.reloadData()
    }

}

extension CopyInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return record?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CopyInfoTableViewCell", for: indexPath) as? CopyInfoTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.headingLabel.text = item.copyInfoHeading
        cell.subheadingLabel.text = item.copyInfoSubheading
        cell.locationLabel.text = item.shelvingLocation
        cell.callNumberLabel.text = item.callNumber
        cell.copyInfoLabel.text = item.countsByStatusLabel
        
        return cell
    }
}

extension CopyInfoViewController: UITableViewDelegate {
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if let org = Organization.find(byId: item.orgID),
            let baseurl_string = App.library?.url,
            let url = URL(string: baseurl_string + "/eg/opac/library/" + org.shortname + "#main-content")
        {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

