//
//  HoldRecord.swift
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

class HoldRecord {
    private let lock = NSRecursiveLock()

    //MARK: - Properties

    private(set) var ahrObj: OSRFObject
    private(set) var metabibRecord: MBRecord?
    private(set) var qstatsObj: OSRFObject?
    private(set) var label: String? // if the hold is a "P" type, this is the part label

    var author: String { return metabibRecord?.author ?? "" }
    var format: String {
        if holdType == "M" { return metarecordHoldFormatLabel() }
        return metabibRecord?.iconFormatLabel ?? ""
    }
    var title: String {
        if let title = metabibRecord?.title {
            if let l = label {
                return "\(title) (\(l))"
            } else {
                return title
            }
        } else {
            return "Unknown Title"
        }
    }

    var id: Int? { return ahrObj.getInt("id") }
    var target: Int? { return ahrObj.getID("target") }
    var holdType: String? { return ahrObj.getString("hold_type") }
    var hasEmailNotify: Bool? { return ahrObj.getBool("email_notify") }
    var hasPhoneNotify: Bool? {
        if ahrObj.getString("phone_notify") != nil {
            return true
        }
        return nil
    }
    var phoneNotify: String? { return ahrObj.getString("phone_notify") }
    var hasSmsNotify: Bool? {
        if ahrObj.getString("sms_notify") != nil {
            return true
        }
        return nil
    }
    var smsNotify: String? { return ahrObj.getString("sms_notify") }
    var smsCarrier: Int? { return ahrObj.getInt("sms_carrier") }
    var pickupOrgId: Int? { return ahrObj.getInt("pickup_lib") }
    var expireDate: Date? { return ahrObj.getDate("expire_time") }
    var shelfExpireDate: Date? { return ahrObj.getDate("shelf_expire_time") }
    var thawDate: Date? { return ahrObj.getDate("thaw_date") }
    var isSuspended: Bool? { return ahrObj.getBool("frozen") }

    var queuePosition: Int { return qstatsObj?.getInt("queue_position") ?? 0 }
    var totalHolds: Int { return qstatsObj?.getInt("total_holds") ?? 0 }
    var potentialCopies: Int { return qstatsObj?.getInt("potential_copies") ?? 0 }
    var status: String {
        let s = qstatsObj?.getInt("status") ?? -1
        if s == 4 {
            var str = "Ready for pickup"
            if App.config.enableHoldShowPickupLib,
               let name = pickupOrgName {
                str = "\(str) at \(name)"
            }
            if App.config.enableHoldShowExpiration,
               let date = shelfExpireDate {
                let dateStr = OSRFObject.outputDateFormatter.string(from: date)
                str = "\(str)\n\(R.getString("Expires")) \(dateStr)"
            }
            return str
        } else if s == 7 {
            return "Suspended"
        } else if s == 3 || s == 8 {
            return "In transit from \(transitFrom)\nSince \(transitSince)"
        } else if s < 3 {
            let copyStatus = "\(totalHolds) holds on \(potentialCopies) copies"
            let qStatus = App.config.enableHoldShowQueuePosition ? "(queue position: \(queuePosition))" : ""
            return "Waiting for copy\n\(copyStatus) \(qStatus)"
        } else {
            return ""
        }
    }
    var pickupOrgName: String? {
        return Organization.find(byId: pickupOrgId)?.name
    }
    var transitFrom: String {
        if let transit = ahrObj.getObject("transit"),
            let source = transit.getInt("source"),
            let org = Organization.find(byId: source) {
            return org.name
        }
        return "unknown"
    }
    var transitSince: String {
        if let transit = ahrObj.getObject("transit"),
            let date = transit.getDate("source_send_time") {
            return OSRFObject.outputDateFormatter.string(from: date)
        }
        return "unknown"
    }

    //MARK: - Functions
    
    init(obj: OSRFObject) {
        self.ahrObj = obj
    }

    /// mt-safe
    func setAhrObj(_ obj: OSRFObject) {
        lock.lock(); defer { lock.unlock() }
        ahrObj = obj
    }

    /// mt-safe
    func setMetabibRecord(_ record: MBRecord) {
        lock.lock(); defer { lock.unlock() }
        metabibRecord = record
    }

    /// mt-safe
    func setQstatsObj(_ obj: OSRFObject) {
        lock.lock(); defer { lock.unlock() }
        qstatsObj = obj
    }

    /// mt-safe
    func setLabel(_ label: String?) {
        lock.lock(); defer { lock.unlock() }
        self.label = label
    }

    static func makeArray(_ objects: [OSRFObject]) -> [HoldRecord] {
        var ret: [HoldRecord] = []
        for obj in objects {
            ret.append(HoldRecord(obj: obj))
        }
        return ret
    }
    
    func metarecordHoldFormatLabel() -> String {
        let formats = HoldRecord.parseHoldableFormats(holdableFormats: ahrObj.getString("holdable_formats"))
        let iconFormats = formats.map { CodedValueMap.iconFormatLabel(forCode: $0) }
        return iconFormats.joined(separator: " or ")
    }

    static func parseHoldableFormats(holdableFormats: String?) -> [String] {
        var formats: [String] = []
        guard
            let data = holdableFormats?.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let obj = json as? JSONDictionary else
        {
            return formats
        }
        for (_, v) in obj {
            if let l = v as? [[String: String]] {
                for e in l {
                    if let attr = e["_attr"],
                        let value = e["_val"],
                        attr == "mr_hold_format"
                    {
                        formats.append(value)
                    }
                }
            }
        }
        return formats
    }

}
