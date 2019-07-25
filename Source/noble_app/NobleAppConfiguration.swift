//
//  NobleAppConfiguration.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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

class NobleAppConfiguration: AppConfiguration {
    let title = "NOBLE Libraries"
    let url = "https://evergreen.noblenet.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"
    let sort: String? = "poprel"

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = true
    let groupCopyInfoBySystem = false
    let needMARCRecord = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100

    let searchFormatsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"Audiobook (All)", "f":"audiobook"},
  {"l":"Audiobook (CD)", "f":"audiobookcd", "L":"CD Audiobook"},
  {"l":"Audiobook (Electronic)", "f":"eaudiobook", "L":"E-audio"},
  {"l":"Audiobook (Playaway)", "f":"playaway", "L":"Playaway"},
  {"l":"Book (All)", "f":"book", "L":"Book"},
  {"l":"Book (Electronic)", "f":"ebook", "L":"E-book"},
  {"l":"Book (Large Print)", "f":"lpbook", "L":"Large Print Book"},
  {"l":"Book (Regular Print)", "f":"rpbook", "L":"Book"},
  {"l":"Magazine/Journal", "f":"serial"},
  {"l":"Map/Atlas", "f":"map", "h":true},
  {"l":"Music Recording (All)", "f":"music"},
  {"l":"Music Recording (CD)", "f":"cdmusic", "L":"CD Music Recording"},
  {"l":"Music Recording (Electronic)", "f":"emusic", "L":"E-music"},
  {"l":"Other (Equipment/Game)", "f":"equip", "h":true},
  {"l":"Other (Kit)", "f":"kit", "h":true},
  {"l":"Other (Software/Video Game)", "f":"software", "L":"Software/Video Game"},
  {"l":"Picture", "f":"picture"},
  {"l":"Score", "f":"score"},
  {"l":"Video (All)", "f":"allvideo"},
  {"l":"Video (Blu-ray)", "f":"blu-ray", "L":"Blu-ray"},
  {"l":"Video (DVD)", "f":"dvd", "L":"DVD"},
  {"l":"Video (Streaming)", "f":"vidstreaming", "L":"E-video"}
]
"""
}
