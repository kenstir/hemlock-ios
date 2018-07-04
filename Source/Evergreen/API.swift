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
    //MARK: - classes used
    static let netClasses = "ac,acn,acp,ahr,ahtc,aou,aout,au,aua,auact,aum,aus,bmp,cbreb,cbrebi,cbrebin,cbrebn,ccs,circ,csc,cuat,ex,mbt,mbts,mous,mra,mraf,mus,mvr,perm_ex"

    //MARK: - actor service

    static let actor = "open-ils.actor"
    static let actorCheckedOut = "open-ils.actor.user.checked_out"
    static let finesSummary = "open-ils.actor.user.fines.summary"
    static let transactionsWithCharges = "open-ils.actor.user.transactions.have_charge.fleshed"

    //MARK: - auth service

    static let auth = "open-ils.auth"
    static let authInit = "open-ils.auth.authenticate.init"
    static let authComplete = "open-ils.auth.authenticate.complete"
    static let authGetSession = "open-ils.auth.session.retrieve"
    
    //MARK: - circ service
    
    static let circ = "open-ils.circ"
    static let circRetrieve = "open-ils.circ.retrieve"
    static let holdsRetrieve = "open-ils.circ.holds.retrieve"
    static let holdQueueStats = "open-ils.circ.hold.queue_stats.retrieve"
    static let renew = "open-ils.circ.renew"
    
    //MARK: - pcrud service
    
    static let pcrud = "open-ils.pcrud"
    static let searchMRA = "open-ils.pcrud.search.mra.atomic"
    static let retrieveMRA = "open-ils.pcrud.retrieve.mra"

    //MARK: - search service
    
    static let search = "open-ils.search"
    static let metarecordModsRetrieve = "open-ils.search.biblio.metarecord.mods_slim.retrieve"
    static let modsFromCopy = "open-ils.search.biblio.mods_from_copy"
    static let recordModsRetrieve = "open-ils.search.biblio.record.mods_slim.retrieve"
    static let query = "open-ils.search.biblio.multiclass.query"
}
