//
//  AppConfiguration.swift
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

class CoolAppConfiguration: AppConfiguration {
    let title = "COOL"
    let url = "https://cool-cat.org"
    let bugReportEmailAddress = "kenstir.apps@gmail.com"

    let enableHierarchicalOrgTree = true
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = true
    let enableMainSceneBottomToolbar = false
    let enablePayFines = false
    let groupCopyInfoBySystem = false
    let needMARCRecord = false

    let barcodeFormat: BarcodeFormat = .Codabar
    let searchLimit = 100
    
    let searchFormatsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"Audiobooks", "f":"cdaudiobook", "L":"Audiobook"},
  {"l":"Books", "f":"book", "L":"Book"},
  {"l":"E-audiobook", "f":"eaudio"},
  {"l":"E-book", "f":"ebook"},
  {"l":"Large Print Book", "f":"lpbook"},
  {"l":"Movies & TV", "f":"moviestv"},
  {"l":"Music", "f":"music"},
  {"l":"Audiocassette music recording", "f":"casmusic", "h":1},
  {"l":"Blu-ray", "f":"blu-ray", "h":1},
  {"l":"Braille", "f":"braille", "h":1},
  {"l":"Cassette audiobook", "f":"casaudiobook", "h":1},
  {"l":"CD Music recording", "f":"cdmusic", "h":1},
  {"l":"DVD", "f":"dvd", "h":1},
  {"l":"E-video", "f":"evideo", "h":1},
  {"l":"Equipment, games, toys", "f":"equip", "h":1},
  {"l":"Kit", "f":"kit", "h":1},
  {"l":"Map", "f":"map", "h":1},
  {"l":"Microform", "f":"microform", "h":1},
  {"l":"Music Score", "f":"score", "h":1},
  {"l":"Phonograph music recording", "f":"phonomusic", "h":1},
  {"l":"Phonograph spoken recording", "f":"phonospoken", "h":1},
  {"l":"Picture", "f":"picture", "h":1},
  {"l":"Serials and magazines", "f":"serial", "h":1},
  {"l":"Software and video games", "f":"software", "h":1},
  {"l":"VHS", "f":"vhs", "h":1}
]
"""
}
