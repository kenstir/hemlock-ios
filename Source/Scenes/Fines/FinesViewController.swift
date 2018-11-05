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
    @IBOutlet weak var payFinesButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!

    var fines: [FineRecord] = []
    
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
        finesTable.delegate = self
        finesTable.dataSource = self
        finesTable.tableFooterView = UIView() // prevent display of ghost rows at end of table
        
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()

        Style.styleStackView(asTableHeader: finesSummary)
        Style.styleLabel(asTableHeader: totalOwedLabel)
        Style.styleLabel(asTableHeader: totalOwedVal)
        Style.styleLabel(asTableHeader: totalPaidLabel)
        Style.styleLabel(asTableHeader: totalPaidVal)
        Style.styleLabel(asTableHeader: balanceOwedLabel)
        Style.styleLabel(asTableHeader: balanceOwedVal)
        Style.styleButton(asPlain: payFinesButton)
        payFinesButton.isEnabled = false
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTreeAndSettings())

        activityIndicator.startAnimating()

        // fetch the summary
        let req1 = Gateway.makeRequest(service: API.actor, method: API.finesSummary, args: [authtoken, userid])
        let promise1 = req1.gatewayOptionalObjectResponse().done { obj in
            self.loadFinesSummary(fromObj: obj)
        }
        promises.append(promise1)
        
        // fetch the transactions
        let req2 = Gateway.makeRequest(service: API.actor, method: API.transactionsWithCharges, args: [authtoken, userid])
        let promise2 = req2.gatewayArrayResponse().done { objects in
            self.loadTransactions(fines: FineRecord.makeArray(objects))
        }
        promises.append(promise2)
        
        // wait for them to finish
        firstly {
            when(fulfilled: promises)
        }.done {
            self.updatePayFinesButton()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func updatePayFinesButton() {
        payFinesButton.isEnabled = true
    }
    
    func loadFinesSummary(fromObj obj: OSRFObject?) {
        let totalOwed = obj?.getDouble("total_owed") ?? 0.0
        let totalPaid = obj?.getDouble("total_paid") ?? 0.0
        let balanceOwed = obj?.getDouble("balance_owed") ?? 0.0
        totalOwedVal.text = String(format: "$ %.2f", totalOwed)
        totalPaidVal.text = String(format: "$ %.2f", totalPaid)
        balanceOwedVal.text = String(format: "$ %.2f", balanceOwed)
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

extension FinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //need stuff here
    }
}

extension FinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: FinesTableViewCell = tableView.dequeueReusableCell(withIdentifier: "finesCell") as? FinesTableViewCell else {
            fatalError("Could not dequeue a cell")
        }
        let fine = fines[indexPath.row]
        cell.finesTitle?.text = fine.title
        cell.finesSubtitle?.text = fine.subtitle
        cell.finesValue?.text = String(format: "$ %.2f ", fine.balance!)
        cell.finesStatus?.text = fine.status
        return cell
    }
    
}


