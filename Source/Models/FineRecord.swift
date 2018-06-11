//
//  FineRecord.swift
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

class FineRecord {
    //MARK: - Properties
    var transaction: OSRFObject //mbts obj
    var circ: OSRFObject? //circ obj //TODO: make this a CircRecord?
    var record: OSRFObject? //mvr obj
    
    var title: String {
        if let title = record?.getString("title") {
            return title
        }
        if let type = transaction.getString("last_billing_type") {
            return type
        }
        return "Miscellaneous"
    }
    var subtitle: String {
        if let author = record?.getString("author") {
            return author
        }
        if let note = transaction.getString("last_billing_note") {
            return note
        }
        return ""
    }
    var balance: Double? {
        return transaction.getDouble("balance_owed")
    }
    var status: String {
        guard let record = self.record else {
            return ""
        }
        if let x = self.circ?.getDate("checkin_time") {
            return "returned"
        }
        if let balance = self.balance,
            let maxFine = self.circ?.getDouble("max_fine"),
            balance > maxFine {
            return "maximum fine"
        }
        return "fines accruing"
    }
    
    //MARK: -

    init(transaction: OSRFObject) {
        self.transaction = transaction
    }
    
    static func makeArray(_ objects: [OSRFObject]) -> [FineRecord] {
        var ret: [FineRecord] = []
        for obj in objects {
            if let transaction = obj.getObject("transaction") {
                let fine = FineRecord(transaction: transaction)
                fine.circ = obj.getObject("circ")
                fine.record = obj.getObject("record")
                ret.append(fine)
            } else {
                Analytics.logError(code: .shouldNotHappen, msg: "fine record has no txn", file: #file, line: #line)
            }
        }
        return ret
    }
}
