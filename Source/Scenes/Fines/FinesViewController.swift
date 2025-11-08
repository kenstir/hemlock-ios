//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import os.log

class FinesViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var finesTable: UITableView!
    @IBOutlet weak var finesSummary: UIStackView!
    @IBOutlet weak var totalOwedStack: UIStackView!
    @IBOutlet weak var totalOwedLabel: UILabel!
    @IBOutlet weak var totalOwedVal: UILabel!
    @IBOutlet weak var totalPaidStack: UIStackView!
    @IBOutlet weak var totalPaidLabel: UILabel!
    @IBOutlet weak var totalPaidVal: UILabel!
    @IBOutlet weak var balanceOwedLabel: UILabel!
    @IBOutlet weak var balanceOwedVal: UILabel!
    @IBOutlet weak var payFinesButton: UIButton!

    weak var activityIndicator: UIActivityIndicatorView!

    var anyBalanceOwed = false
    var fines: [XPatronChargeRecord] = []

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
        if let title = R.string["Fines"] {
            self.title = title
        }

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
        
        // hide Total Owed and Total Paid columns if labels are empty
        if let str = R.string["total_owed"] {
            if str.isEmpty {
                totalOwedStack.isHidden = true
            } else {
                totalOwedLabel.text = str
            }
        }
        if let str = R.string["total_paid"] {
            if str.isEmpty {
                totalPaidStack.isHidden = true
            } else {
                totalPaidLabel.text = str
            }
        }
        if let str = R.string["balance_owed"] {
            if str.isEmpty {
                //balanceOwedStack.isHidden = true
            } else {
                balanceOwedLabel.text = str
            }
        }

        payFinesButton.isEnabled = false
        if App.config.enablePayFines {
            Style.styleButton(asOutline: payFinesButton)
        } else {
            payFinesButton.isHidden = true
        }
        if let str = R.string["button_pay_fines"] {
            payFinesButton.setTitle(str, for: .normal)
        }
    }

    func fetchHomeOrgSettings(account: Account) async throws {
        if let homeOrgID = account.homeOrgID {
            try await App.serviceConfig.orgService.loadOrgSettings(forOrgID: homeOrgID)
        }
    }

    @MainActor
    func fetchData() async {
        guard let account = App.account else { return }

        activityIndicator.startAnimating()

        do {
            async let chargesFuture = App.serviceConfig.userService.fetchPatronCharges(account: account)

            let (_, charges) = try await (fetchHomeOrgSettings(account: account), chargesFuture)

            self.anyBalanceOwed = charges.balanceOwed > 0.0
            self.updatePayFinesButton()
            self.updateCharges(withCharges: charges)
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()
    }

    func updatePayFinesButton() {
        if App.config.enablePayFines,
            let homeOrgID = App.account?.homeOrgID,
            let homeOrg = Organization.find(byId: homeOrgID),
            let isPaymentAllowed = homeOrg.isPaymentAllowedSetting,
            isPaymentAllowed && anyBalanceOwed
        {
            Style.styleButton(asInverse: payFinesButton)
            payFinesButton.isEnabled = true
            payFinesButton.addTarget(self, action: #selector(payFinesButtonPressed(_:)), for: .touchUpInside)
        }
    }

    @objc func payFinesButtonPressed(_ sender: Any) {
        if let baseurl_string = App.library?.url,
            let url = URL(string: baseurl_string + "/eg/opac/myopac/main_payment_form#pay_fines_now") {
            UIApplication.shared.open(url)
        }
    }

    func updateCharges(withCharges charges: PatronCharges) {
        totalOwedVal.text = String(format: "$ %.2f", charges.totalCharges)
        totalPaidVal.text = String(format: "$ %.2f", charges.totalPaid)
        balanceOwedVal.text = String(format: "$ %.2f", charges.balanceOwed)

        loadTransactions(fines: charges.transactions)
    }

    func loadTransactions(fines: [XPatronChargeRecord]) {
        self.fines = fines
        for fine in fines {
            print("-----------------------")
            print("title:    \(fine.title)")
            print("subtitle: \(fine.subtitle)")
            print("status:   \(fine.status)")
            if let balance = fine.balanceOwed {
                print("balance:  \(balance)")
            }
        }
        finesTable.reloadData()
    }
}

//MARK: - UITableViewDataSource
extension FinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "finesCell") as? FinesTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let fine = fines[indexPath.row]
        cell.finesTitle?.text = fine.title
        cell.finesSubtitle?.text = fine.subtitle
        cell.finesValue?.text = String(format: "$ %.2f ", fine.balanceOwed ?? 0.0)
        cell.finesStatus?.text = fine.status

        return cell
    }
}

//MARK: - UITableViewDelegate
extension FinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row >= 0 && indexPath.row < fines.count else { return }

        var selectedIndex = indexPath.row
        let currentFine = fines[indexPath.row]
        let currentRecord = currentFine.record

        var records: [MBRecord] = []
        for fine in fines {
            if let record = fine.record, !record.isPreCat {
                records.append(record)
            }
        }

        // If any of the fines are for non-circulation items ("grocery bills"), we
        // launch the Details VC with only the selected record, if we can.  We have
        // no details on grocery bills, and the Details VC doesn't handle nulls.
        if records.count != fines.count {
            records = []
            selectedIndex = 0
            if let record = currentRecord, !record.isPreCat {
                records.append(record)
            }
        }

        if records.count > 0 {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
            if let vc = XUtils.makeDetailsPager(items: records, selectedItem: selectedIndex, displayOptions: displayOptions) {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            // deselect row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
