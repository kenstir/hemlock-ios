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

import XCTest
@testable import Hemlock

/// the test account config, so we don't have to load it for every test
class TestConfig {
    let url: String
    let username: String
    let password: String
    let homeOrgID: Int
    let sampleRecordID: Int

    init(url: String, username: String, password: String, homeOrgID: Int, sampleRecordID: Int) {
        self.url = url
        self.username = username
        self.password = password
        self.homeOrgID = homeOrgID
        self.sampleRecordID = sampleRecordID
    }
}

/// the test account server state, so we don't have to login for every test
class TestState {
    var account: Account

    init(username: String, password: String) {
        self.account = Account(username, password: password)
    }
}

/// These tests run against the live service configured in TestUserData/testAccount.json.
/// Don't do anything crazy here.
class LiveServiceTests: XCTestCase {

    //MARK: - properties

    static var config: TestConfig?
    static var state: TestState?
    static var prerequisitesLoaded = false
    static var sessionLoaded = false

    static let configFile = "TestUserData/testAccount" // .json

    let manualTestsEnabled = false // hack to limit certain tests
    let updateTestsEnabled = false // hack to limit certain tests

    var username: String { return LiveServiceTests.config!.username } // if you error here, see TestUserData/README.md
    var password: String { return LiveServiceTests.config!.password }
    var homeOrgID: Int { return LiveServiceTests.config!.homeOrgID }
    var sampleRecordID: Int { return LiveServiceTests.config!.sampleRecordID }
    var authtoken: String? { return LiveServiceTests.state!.account.authtoken }
    var userID: Int? { return LiveServiceTests.state!.account.userID }

    //MARK: - functions

    override class func setUp() {
        super.setUp()

        initTestState()

        App.library = Library(LiveServiceTests.config!.url)
    }

    override class func tearDown() {
        super.tearDown()

        Task {
            try await LiveServiceTests.once_deleteSession()
        }
    }

    static func initTestState() {
        print("LiveServiceTests: INITIALIZING TEST CONFIG")

        // read configFile as json
        let testBundle = Bundle(for: LiveServiceTests.self)
        guard
            let path = testBundle.path(forResource: configFile, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any],
            let url = jsonObject["url"] as? String,
            let username = jsonObject["username"] as? String,
            let password = jsonObject["password"] as? String,
            let homeOrgID = jsonObject["homeOrgID"] as? Int,
            let sampleRecordID = jsonObject["sampleRecordID"] as? Int else
        {
            XCTFail("unable to read JSON data from \(configFile).json, see TestUserData/README.md")
            return
        }

        LiveServiceTests.config = TestConfig(url: url, username: username, password: password, homeOrgID: homeOrgID, sampleRecordID: sampleRecordID)
        LiveServiceTests.state = TestState(username: username, password: password)
    }

    //MARK: - Async helpers

    func once_fetchAuthToken(credential: Credential) async throws -> String {
        if let authtoken = LiveServiceTests.state!.account.authtoken {
            return authtoken
        }
        let service = EvergreenAuthService()
        let credential = Credential(username: username, password: password)
        let authToken = try await service.fetchAuthToken(credential: credential)
        LiveServiceTests.state!.account.setAuthToken(authToken)
        return authToken
    }

    func once_loadStartupPrerequisites() async throws {
        if LiveServiceTests.prerequisitesLoaded {
            return
        }
        let service = EvergreenLoaderService()
        try await service.loadStartupPrerequisites(options: LoadStartupOptions(
            clientCacheKey: Bundle.appVersionUrlSafe, useHierarchicalOrgTree: true
        ))
        LiveServiceTests.prerequisitesLoaded = true
    }

    func once_loadSession() async throws {
        if LiveServiceTests.sessionLoaded {
            return
        }
        let service = EvergreenUserService()
        try await service.loadSession(account: LiveServiceTests.state!.account)
        LiveServiceTests.sessionLoaded = true
    }

    static func once_deleteSession() async throws {
        if !LiveServiceTests.sessionLoaded {
            return
        }
        let service = EvergreenUserService()
        try await service.deleteSession(account: LiveServiceTests.state!.account)
        LiveServiceTests.sessionLoaded = false
    }

    //MARK: - AuthService tests

    func test_fetchAuthToken_ok() async throws {
        let credential = Credential(username: username, password: password)
        let authToken = try await once_fetchAuthToken(credential: credential)
        XCTAssertFalse(authToken.isEmpty, "authToken should not be empty")
    }

    func test_fetchAuthToken_fail() async throws {
        let credential = Credential(username: "peterpan", password: "password1")
        let service = EvergreenAuthService()
        do {
            let authToken = try await service.fetchAuthToken(credential: credential)
            XCTFail("fetchAuthToken succeeded but should have failed, authToken: \(authToken)")
        } catch {
            XCTAssertEqual(error.localizedDescription, "User login failed")
        }
    }

    //MARK: - LoaderService tests

    func test_loadStartupPrerequisites() async throws {
        try await once_loadStartupPrerequisites()
        XCTAssertTrue(App.idlLoaded ?? false, "IDL should be loaded")
    }

    // Test that parseIDL registers exactly as many netClasses as we asked for
    func test_parseIDL_subset() async throws {
        try await once_loadStartupPrerequisites()
        let expected = API.netClasses.split(separator: ",").count
        XCTAssertEqual(OSRFCoder.registryCount(), expected)
    }

    func test_orgTypes() async throws {
        try await once_loadStartupPrerequisites()
        let orgTypes = OrgType.orgTypes
        XCTAssert(orgTypes.count > 0, "found some org types")
    }

    func test_orgTree() async throws {
        try await once_loadStartupPrerequisites()

        let org = Organization.find(byId: 1)
        XCTAssertNotNil(org)
        XCTAssertNotNil(org?.name)
        let consortium = Organization.consortium()
        XCTAssertNotNil(consortium)
        XCTAssertEqual(1, consortium?.id)
    }

    func test_copyStatuses() async throws {
        try await once_loadStartupPrerequisites()

        XCTAssertGreaterThan(CopyStatus.status.count, 0)
    }

    //MARK: - UserService tests

    func test_fetchSession() async throws {
        try await once_loadStartupPrerequisites()
        let authtoken = try await once_fetchAuthToken(credential: Credential(username: username, password: password))
        try await once_loadSession()

        XCTAssertFalse(authtoken.isEmpty, "authtoken should not be empty")
        XCTAssertNotNil(LiveServiceTests.state!.account.userID, "userID should not be nil")
    }
}
