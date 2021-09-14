//  API.swift
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

/// `API` defines the services and methods of the Gateway
struct API {

    //MARK: - misc

    static let anonymousAuthToken = "ANONYMOUS" // can be passed as authtoken in some requests
    static let netClasses = "ac,acn,acp,ahr,ahrn,ahtc,aoa,aou,aouhoo,aout,au,aua,auact,aum,aus,bmp,bre,cbreb,cbrebi,cbrebin,cbrebn,ccs,ccvm,cfg,circ,csc,cuat,ex,mbt,mbts,mous,mra,mraf,mus,mvr,perm_ex"

    //MARK: - actor service

    static let actor = "open-ils.actor"
    static let actorCheckedOut = "open-ils.actor.user.checked_out"
    static let finesSummary = "open-ils.actor.user.fines.summary"
    static let messagesRetrieve = "open-ils.actor.message.retrieve"
    static let orgTreeRetrieve = "open-ils.actor.org_tree.retrieve"
    static let orgTypesRetrieve = "open-ils.actor.org_types.retrieve"
    static let orgUnitRetrieve = "open-ils.actor.org_unit.retrieve"
    static let orgUnitSetting = "open-ils.actor.ou_setting.ancestor_default"
    static let orgUnitSettingBatch = "open-ils.actor.ou_setting.ancestor_default.batch"
    static let orgUnitHoursOfOperationRetrieve = "open-ils.actor.org_unit.hours_of_operation.retrieve"
    static let orgUnitAddressRetrieve = "open-ils.actor.org_unit.address.retrieve"
    static let settingSMSEnable = "sms.enable"
    static let settingNotPickupLib = "opac.holds.org_unit_not_pickup_lib"
    static let settingCreditPaymentsAllow = "credit.payments.allow"
    static let settingInfoURL = "lib.info_url"
    static let transactionsWithCharges = "open-ils.actor.user.transactions.have_charge.fleshed"
    static let userFleshedRetrieve = "open-ils.actor.user.fleshed.retrieve"
    static let userSettingHoldNotify = "opac.hold_notify" // e.g. "email|sms"
    static let userSettingDefaultPhone = "opac.default_phone"
    static let userSettingDefaultPickupLocation = "opac.default_pickup_location"
    static let userSettingDefaultSearchLocation =  "opac.default_search_location"
    static let userSettingDefaultSMSCarrier = "opac.default_sms_carrier"
    static let userSettingDefaultSMSNotify = "opac.default_sms_notify"

    //MARK: - auth service

    static let auth = "open-ils.auth"
    static let authInit = "open-ils.auth.authenticate.init"
    static let authComplete = "open-ils.auth.authenticate.complete"
    static let authGetSession = "open-ils.auth.session.retrieve"
    
    //MARK: - circ service
    
    static let circ = "open-ils.circ"
    static let circRetrieve = "open-ils.circ.retrieve"
    static let holdsRetrieve = "open-ils.circ.holds.retrieve"
    static let holdCancel = "open-ils.circ.hold.cancel"
    static let holdTestAndCreate = "open-ils.circ.holds.test_and_create.batch"
    static let holdUpdate = "open-ils.circ.hold.update"
    static let holdQueueStats = "open-ils.circ.hold.queue_stats.retrieve"
    static let renew = "open-ils.circ.renew"
    static let titleHoldIsPossible = "open-ils.circ.title_hold.is_possible"
    
    static let holdTypeCopy = "C"
    static let holdTypeForce = "F"
    static let holdTypeRecall = "R"
    static let holdTypeIssuance = "I"
    static let holdTypeVolume = "V"
    static let holdTypeTitle = "T"
    static let holdTypeMetarecord =  "M"
    static let holdTypePart = "P"

    //MARK: - fielder service
    
    static let fielder = "open-ils.fielder"
    static let fielderBMPAtomic = "open-ils.fielder.bmp.atomic"
    
    //MARK: - mobile service
    
    static let mobile = "open-ils.selfcheck"
    static let exists = "open-ils.selfcheck.exists"
    static let xyzzy = "open-ils.selfcheck.xyzzy"

    //MARK: - pcrud service
    
    static let pcrud = "open-ils.pcrud"
    static let retrieveBRE = "open-ils.pcrud.retrieve.bre"
    static let retrieveMRA = "open-ils.pcrud.retrieve.mra"
    static let searchCCVM = "open-ils.pcrud.search.ccvm.atomic"
    static let searchSMSCarriers = "open-ils.pcrud.search.csc.atomic"

    //MARK: - search service
    
    static let search = "open-ils.search"
    static let assetCallNumberRetrieve = "open-ils.search.asset.call_number.retrieve"
    static let assetCopyRetrieve = "open-ils.search.asset.copy.retrieve"
    static let metarecordModsRetrieve = "open-ils.search.biblio.metarecord.mods_slim.retrieve"
    static let modsFromCopy = "open-ils.search.biblio.mods_from_copy"
    static let recordModsRetrieve = "open-ils.search.biblio.record.mods_slim.retrieve"
    static let multiclassQuery = "open-ils.search.biblio.multiclass.query"
    static let copyStatusRetrieveAll = "open-ils.search.config.copy_status.retrieve.all"
    static let copyCount = "open-ils.search.biblio.record.copy_count"
    static let copyLocationCounts = "open-ils.search.biblio.copy_location_counts.summary.retrieve"
    static let holdParts = "open-ils.search.biblio.record_hold_parts"
    
    //MARK: - misc
    static let ilsVersion = "opensrf.open-ils.system.ils_version"

    //MARK: - supercat service
    
    //alternate for retrieving MARCXML, but was sloweer than retrieveBRE
    //static let retrieveMarcxml = "open-ils.supercat.record.marcxml.retrieve"
}
