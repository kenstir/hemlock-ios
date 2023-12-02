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

    var mbtsObj: OSRFObject
    var circObj: OSRFObject?
    var mvrObj: OSRFObject?
    
    var title: String {
        if let title = mvrObj?.getString("title") {
            return title
        }
        if let type = mbtsObj.getString("last_billing_type") {
            return type
        }
        return "Miscellaneous"
    }
    var subtitle: String {
        if let author = mvrObj?.getString("author") {
            return author
        }
        if let note = mbtsObj.getString("last_billing_note") {
            return note
        }
        return ""
    }
    var balance: Double? {
        return mbtsObj.getDouble("balance_owed")
    }
    var status: String {
        guard let _ = self.mvrObj else {
            return ""
        }
        if let _ = self.circObj?.getDate("checkin_time") {
            return "returned"
        }
        if let balance = self.balance,
            let maxFine = self.circObj?.getDouble("max_fine"),
            balance > maxFine {
            return "maximum fine"
        }
        return "fines accruing"
    }
    
    //MARK: - Functions

    init(transaction: OSRFObject) {
        self.mbtsObj = transaction
    }
    
    static func makeArray(_ objects: [OSRFObject]) -> [FineRecord] {
        var ret: [FineRecord] = []
        for obj in objects {
            if let transaction = obj.getObject("transaction") {
                let fine = FineRecord(transaction: transaction)
                fine.circObj = obj.getObject("circ")
                fine.mvrObj = obj.getObject("record")
                ret.append(fine)
            } else {
                Analytics.logError(code: .shouldNotHappen, msg: "fine record has no txn", file: #file, line: #line)
            }
        }
        return ret
    }
}
