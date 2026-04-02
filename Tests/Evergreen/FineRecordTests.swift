//
//  Copyright (c) 2026 Kenneth H. Cox
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

import XCTest
@testable import Hemlock

class FineRecordTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let circFields = ["checkin_lib","checkin_staff","checkin_time","circ_lib","circ_staff","desk_renewal","due_date","duration","duration_rule","fine_interval","id","max_fine","max_fine_rule","opac_renewal","phone_renewal","recurring_fine","recurring_fine_rule","renewal_remaining","grace_period","stop_fines","stop_fines_time","target_copy","usr","xact_finish","xact_start","create_time","workstation","checkin_workstation","checkin_scan_time","parent_circ","billings","payments","billable_transaction","circ_type","billing_total","payment_total","unrecovered","copy_location","aaactsc_entries","aaasc_entries","auto_renewal","auto_renewal_remaining"]
        let mbtsFields = ["balance_owed","id","last_billing_note","last_billing_ts","last_billing_type","last_payment_note","last_payment_ts","last_payment_type","total_owed","total_paid","usr","xact_finish","xact_start","xact_type"]
        let mvrFields = ["title","author","doc_id","doc_type","pubdate","isbn","publisher","tcn","subject","types_of_resource","call_numbers","edition","online_loc","synopsis","physical_description","toc","copy_count","series","serials","foreign_copy_maps"]
        OSRFCoder.registerClass("circ", fields: circFields)
        OSRFCoder.registerClass("mbts", fields: mbtsFields)
        OSRFCoder.registerClass("mvr", fields: mvrFields)
    }

    func test_makeArray_oneCircCharge() throws {
        // open-ils.actor.user.transactions.have_charge.fleshed with one charge
        let json = """
            {"payload":[[{"circ":{"__c":"circ","__p":[null,null,null,69,3788,"f","2019-11-21T23:59:59-0500","21 days","default","1 day",90763841,"1.00","overdue_1","f","f","0.02","02_cent_per_day",1,"00:00:00",null,null,19331811,409071,null,"2019-10-31T13:27:47-0400","2019-10-31T13:27:47-0400",6355,null,null,null,null,null,null,null,null,null,null,614,null,null,"f",1]},"copy":null,"transaction":{"__c":"mbts","__p":["0.42",90763841,"System Generated Overdue Fine","2019-12-14T23:59:59-0500","Overdue materials",null,null,null,"0.42","0.0",409071,null,"2019-10-31T13:27:47-0400","circulation"]},"record":{"__c":"mvr","__p":["The testaments","Atwood, Margaret",4286727,null,"2019","9780385543781",null,"4286727",{"Misogyny":1,"Surrogate mothers":1,"Women":1,"Man-woman relationships":1},["text"],[],"First edition.",[],"yadda yadda yadda.","print x, 419 pages ; 25 cm","Intro -- Finale -- Coda.",null,[]]}}]],"status":200}
            """
        let array = try GatewayResponse(json).asArray()
        let fines = FineRecord.makeArray(array)

        XCTAssertEqual(1, fines.count)
        let fine = fines[0]
        XCTAssertEqual("The testaments", fine.title)
        XCTAssertEqual("Atwood, Margaret", fine.subtitle)
        XCTAssertEqual(0.42, fine.balanceOwed)
        XCTAssertEqual("fines accruing", fine.status)
    }

    func test_makeArray_twoGroceryBills() throws {
        // two grocery bills, with neither circ nor record
        let json = """
            {"payload":[[
             {"transaction":{"__c":"mbts","__p":["2.00",221301311,null,"2021-03-15T09:49:53-0400","Card: Lost Fee",null,null,null,"2.00","0.0",4212142,null,"2021-03-15T09:49:52-0400","grocery"]}},
             {"transaction":{"__c":"mbts","__p":["3.75",221301316,"Photocopies","2021-03-15T09:50:15-0400","Miscellaneous",null,null,null,"3.75","0.0",4212142,null,"2021-03-15T09:50:15-0400","grocery"]}}
            ]],"status":200}
            """
        let array = try GatewayResponse(json).asArray()
        let fines = FineRecord.makeArray(array)

        XCTAssertEqual(2, fines.count)
        let fine = fines[0]
        XCTAssertEqual("Card: Lost Fee", fine.title)
        XCTAssertEqual("", fine.subtitle)
        XCTAssertEqual(2.0, fine.balanceOwed)
        XCTAssertEqual("", fine.status)
    }

    func test_status() {
        let mbtsObj = OSRFObject([
            "xact_type": "circulation",
            "balance_owed": "1.00",
        ])
        let circObjMaxFines = OSRFObject([
            "max_fine": "10.00",
            "stop_fines": "MAXFINES",
            "checkin_time": nil,
        ])
        let circObjReturned = OSRFObject([
            "max_fine": "10.00",
            "stop_fines": "CHECKIN",
            "checkin_time": "2026-04-01T12:00:00-0400",
        ])
        let circObjRenewed = OSRFObject([
            "max_fine": "10.00",
            "stop_fines": "RENEW",
            "checkin_time": "2026-04-01T12:00:00-0400",
        ])
        let circObjAccruing = OSRFObject([
            "max_fine": "10.00",
            "stop_fines": nil,
            "checkin_time": nil,
        ])
        let mvrObj = OSRFObject([
            "title": "The testaments",
            "author": "Atwood, Margaret",
        ])

        let fine1 = FineRecord(mbtsObj: mbtsObj, circObj: circObjMaxFines, mvrObj: mvrObj)
        XCTAssertEqual("maximum fine", fine1.status)

        let fine2 = FineRecord(mbtsObj: mbtsObj, circObj: circObjReturned, mvrObj: mvrObj)
        XCTAssertEqual("returned", fine2.status)

        let fine3 = FineRecord(mbtsObj: mbtsObj, circObj: circObjRenewed, mvrObj: mvrObj)
        XCTAssertEqual("renewed", fine3.status)

        let fine4 = FineRecord(mbtsObj: mbtsObj, circObj: circObjAccruing, mvrObj: mvrObj)
        XCTAssertEqual("fines accruing", fine4.status)

        let groceryMbtsObj = OSRFObject([
            "xact_type": "grocery",
            "balance_owed": "1.00",
            "last_billing_type": "Photocopies",
            "last_billing_note": "Miscellaneous",
        ])
        let fine5 = FineRecord(mbtsObj: groceryMbtsObj)
        XCTAssertEqual("", fine5.status)
    }
}
