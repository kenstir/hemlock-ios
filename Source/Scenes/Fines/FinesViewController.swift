//
//  FinesViewController.swift
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

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire

class FinesViewController: UIViewController {
    //MARK: - Properties
    @IBOutlet weak var finesTable: UITableView!
    @IBOutlet weak var finesSummary: UIStackView!
    @IBOutlet weak var totalOwedLabel: UILabel!
    @IBOutlet weak var totalPaidLabel: UILabel!
    @IBOutlet weak var balanceOwedLabel: UILabel!
    @IBOutlet weak var totalOwedVal: UILabel!
    @IBOutlet weak var totalPaidVal: UILabel!
    @IBOutlet weak var balanceOwedVal: UILabel!
    var fines: [FineRecord] = []
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFines()
//        tableView.delegate = self
        finesTable.dataSource = self
    }
    
    //MARK: - Functions
    
    func fetchFines() {
        guard let authtoken = AppSettings.account?.authtoken,
            let userid = AppSettings.account?.userID else
        {
            return //todo add analytics
        }
        
        // fetch the summary
        let req = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, userid])
        //todo: create gatewayResponseObj() promise that requires an osrfobject response
        req.gatewayResponse().done { resp, pmkresp in
            guard let obj = resp.obj else {
                throw HemlockError.unexpectedNetworkResponse("fines summary") //todo add analytics
            }
            self.loadFinesSummary(fromObj: obj)
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
        
        // fetch the transactions
        let req2 = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, userid])
        req2.gatewayArrayResponse().done { objects in
            self.loadTransactions(fines: FineRecord.makeArray(objects))
        }.catch { error in
            self.showAlert(title: "Request failed", message: error.localizedDescription)
        }
    }
    
    func loadFinesSummary(fromObj obj: OSRFObject) {
        debugPrint(obj)
        totalOwedVal.text = String(format: "$ %.2f", obj.getDouble("total_owed")!)
        totalPaidVal.text = String(format: "$ %.2f", obj.getDouble("total_owed")!)
        balanceOwedVal.text = String(format: "$ %.2f", obj.getDouble("balance_owed")!)
        print("stop here")
    }
    
    func loadTransactions(fines: [FineRecord]) {
        self.fines = fines
        for fine in fines {
            print("-----------------------")
            print("title:    \(fine.title)")
            print("subtitle: \(fine.subtitle)")
            print("status:   \(fine.status)")
            if let balance = fine.balance {
                print("balance:  \(balance)")
            }
        }
        finesTable.reloadData()
    }
}

//extension FinesViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        //need stuff here
//    }
//}

extension FinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FinesCellIdentifier") else {
            fatalError("Could not dequeue a cell")
        }
        let fine = fines[indexPath.row]
        cell.textLabel?.text = fine.title
        return cell
    }
    
}


