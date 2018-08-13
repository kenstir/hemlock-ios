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

class CopyInfoViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var table: UITableView!
    
    var org: Organization?
    var record: MBRecord?
    var items: [String] = []
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
        //table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView() // prevent display of ghost rows at end of table
        self.setupHomeButton()
    }
    
    func fetchData() {
        guard let recordID = record?.id,
            let org = self.org else
        {
            //TODO: analytics
            return
        }
        let promise = SearchService.fetchCopyLocationCounts(org: org, recordID: recordID)
        promise.done { resp, pmkresp in
            let copyLocationCounts = CopyLocationCounts.makeArray(fromPayload: resp.payload)
            for elem in copyLocationCounts {
                if let org = Organization.find(byId: elem.orgID) {
                    var majorLocationText = org.name
                    var minorLocationText = ""
                    if AppSettings.groupCopyInfoBySystem,
                        let parentID = org.parent,
                        let parent = Organization.find(byId: parentID)
                    {
                        majorLocationText = parent.name
                        minorLocationText = org.name
                    }
                    
                    print("---------------------------")
                    print(majorLocationText)
                    print(minorLocationText)
                    print(elem.location)
                    print(elem.callNumber)
                    for (copyStatusID, copyCount) in elem.countsByStatus {
                        let copyStatus = CopyStatus.label(forID: copyStatusID)
                        print("\(copyCount) \(copyStatus)")
                    }
                }
            }
            print("stop here")
        }.catch { error in
            self.showAlert(error: error)
        }
    }
}

extension CopyInfoViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CopyInfoTableViewCell", for: indexPath) as? CopyInfoTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        
        return cell
    }
}

extension CopyInfoViewController: UITableViewDelegate {
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

