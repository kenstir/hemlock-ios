//
//  NTLCAppConfiguration.swift
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

class NTLCAppConfiguration: AppConfiguration {
    let title = "NTLC Catalog"
    let url = "https://catalog.northtexaslibraries.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = false
    let groupCopyInfoBySystem = false
    let needMARCRecord = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100

    let searchFormatsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"All Books", "f":"book", "L":"Book"},
  {"l":"All Music", "f":"music", "L":"Music"},
  {"l":"Blu-ray", "f":"blu-ray"},
  {"l":"Braille", "f":"braille", "h":1},
  {"l":"CD Audiobook", "f":"cdaudiobook"},
  {"l":"CD Music recording", "f":"cdmusic"},
  {"l":"DVD", "f":"dvd"},
  {"l":"E-audio", "f":"eaudio"},
  {"l":"E-book", "f":"ebook"},
  {"l":"E-video", "f":"evideo"},
  {"l":"Equipment, games, toys", "f":"equip", "h":1},
  {"l":"Kit", "f":"kit", "h":1},
  {"l":"Large Print Book", "f":"lpbook"},
  {"l":"Picture", "f":"picture", "h":1},
  {"l":"Serials and magazines", "f":"serial"},
  {"l":"Software and video games", "f":"software"},
  {"l":"VHS", "f":"vhs", "h":1}
]
"""
}
