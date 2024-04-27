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

import XCTest
import PromiseKit
import PMKAlamofire
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
    var sessionObj: OSRFObject? = nil
    var executionCount = 0

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
    static var idlLoaded = false

    let configFile = "TestUserData/testAccount" // .json
    let consortiumOrgID = 1

    let manualTestsEnabled = true
    let updateTestsEnabled = false // only run update tests manually

    var username: String { return LiveServiceTests.config!.username } // if you error here, see TestUserData/README.md
    var password: String { return LiveServiceTests.config!.password }
    var homeOrgID: Int { return LiveServiceTests.config!.homeOrgID }
    var sampleRecordID: Int { return LiveServiceTests.config!.sampleRecordID }
    var authtoken: String? { return LiveServiceTests.state!.account.authtoken }
    var userID: Int? { return LiveServiceTests.state!.account.userID }

    //MARK: - functions

    override func setUp() {
        super.setUp()

        initTestConfig()
        initTestState()

        App.library = Library(LiveServiceTests.config!.url)

        LiveServiceTests.state?.executionCount += 1
        print("setUp: executionCount  = \(LiveServiceTests.state?.executionCount ?? 0)")
    }

    override func tearDown() {
    }

    func initTestConfig() {
        guard LiveServiceTests.config == nil else { return }

        print("LiveServiceTests: INITIALIZING TEST CONFIG")

        // read configFile as json
        let testBundle = Bundle(for: type(of: self))
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
    }

    func initTestState() {
        guard LiveServiceTests.state == nil else { return }

        LiveServiceTests.state = TestState(username: username, password: password)
    }

    func loadIDL() -> Bool {
        guard !LiveServiceTests.idlLoaded else { return true }

        print("LiveServiceTests: LOADING IDL")
        let parser = IDLParser(contentsOf: URL(string: Gateway.idlURL())!)
        let ok = parser.parse()
        LiveServiceTests.idlLoaded = ok
        return ok
    }

    /// return a promise for an authtoken for the test user, but calling the server only once
    func makeAuthtokenPromise() -> Promise<(String)> {
        if let authtoken = LiveServiceTests.state!.account.authtoken {
            let promise = Promise<(String)>() { seal in
                seal.fulfill(authtoken)
            }
            return promise
        } else {
            print("LiveServiceTests: FETCHING AUTHTOKEN")
            let credential = Credential(username: username, password: password)
            let promise = AuthService.fetchAuthToken(credential: credential)
            return promise.then { (authtoken: String) -> Promise<(String)> in
                LiveServiceTests.state!.account.authtoken = authtoken
                return Promise<(String)>() { seal in
                    seal.fulfill(authtoken)
                }
            }
        }
    }

    /// return a promise for a session obj, but calling the server only once
    func makeFetchSessionPromise() -> Promise<Void> {
        if (LiveServiceTests.state?.sessionObj) != nil {
            let promise = Promise<Void>() { seal in
                seal.fulfill(Void())
            }
            return promise
        } else {
            let promise = makeAuthtokenPromise()
            return promise.then { (authtoken: String) -> Promise<(OSRFObject)> in
                print("LiveServiceTests: FETCHING SESSION")
                return AuthService.fetchSession(authtoken: authtoken)
            }.then { (obj: OSRFObject) -> Promise<Void> in
                LiveServiceTests.state?.sessionObj = obj
                return Promise<Void>()
            }
        }
    }

    //MARK: - Promise tests
    
    // Test a basic promise chain, it does not actually login
    // but it goes through the mechanics of logging in.
    func test_promiseBasic() {
        let expectation = XCTestExpectation(description: "async response")
        
        let args: [Any] = [username]
        let req = Gateway.makeRequest(service: API.auth, method: API.authInit, args: args, shouldCache: false)
        req.responseJSON().then { (json: Any, response: PMKAlamofireDataResponse) -> Promise<(json: Any, response: PMKAlamofireDataResponse)> in
            print("then: \(json)")
            let objectParam = ["type": "opac",
                               "username": "hemlock_app_bogus_user",
                               "password": "badbeef"]
            return Gateway.makeRequest(service: API.auth, method: API.authComplete, args: [objectParam], shouldCache: false).responseJSON()
        }.done { (json,response) in
            print("done: \(json)")
            expectation.fulfill()
        }.ensure {
            // nada
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - Auth tests

    func test_fetchAuthToken_ok() {
        let expectation = XCTestExpectation(description: "async response")

        let promise = makeAuthtokenPromise()
        promise.done { authtoken in
            XCTAssertFalse(authtoken.isEmpty)
            print("authtoken: \(authtoken)")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_fetchAuthToken_fail() {
        let expectation = XCTestExpectation(description: "async response")

        let credential = Credential(username: "peterpan", password: "password1")
        let promise = AuthService.fetchAuthToken(credential: credential)
        promise.done { authtoken in
            XCTFail("fetchAuthToken succeeded but should have failed")
            expectation.fulfill()
        }.catch { error in
            XCTAssertEqual(error.localizedDescription, "User login failed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_fetchSession() {
        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")

        let promise = makeFetchSessionPromise()
        promise.done {
            let obj = LiveServiceTests.state!.sessionObj
            XCTAssertNotNil(obj)
            let userID = obj?.getInt("id")
            XCTAssertNotNil(userID)
            let homeOrgID = obj?.getInt("home_ou")
            XCTAssertNotNil(homeOrgID)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - IDL

    // Test that parseIDL registers exactly as many netClasses as we asked for
    func test_parseIDL_subset() {
        XCTAssertTrue(loadIDL())
        let expected = API.netClasses.split(separator: ",").count
        XCTAssertEqual(OSRFCoder.registryCount(), expected)
    }

    //MARK: - orgTypesRetrieve
    
    func test_orgTypesRetrieve() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = ActorService.fetchOrgTypes()
        promise.done {
            let orgTypes = OrgType.orgTypes
            XCTAssert(orgTypes.count > 0, "found some org types")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - orgTreeRetrieve
    
    func test_orgTreeRetrieve() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = ActorService.fetchOrgTreeAndSettings()
        promise.done {
            let org = Organization.find(byId: 1)
            XCTAssertNotNil(org)
            XCTAssertNotNil(org?.name)
            let consortium = Organization.consortium()
            XCTAssertNotNil(consortium)
            XCTAssertEqual(1, consortium?.id)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - orgUnitSetting
    
    func test_orgUnitSetting() {
        let expectation = XCTestExpectation(description: "async response")

        let orgID = self.consortiumOrgID
        let setting = API.settingSMSEnable
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSetting, args: [orgID, setting, API.anonymousAuthToken], shouldCache: false)
        req.gatewayOptionalObjectResponse().done { obj in
            let value = obj?.getBool("value")
            print("org \(orgID) setting \(setting) value \(String(describing: value))")
            XCTAssertTrue(true, "we do not know what settings what orgs will or will not have")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_orgUnitSettingBatch() {
        let expectation = XCTestExpectation(description: "async response")
        
        let orgID = self.consortiumOrgID
        let settings = [API.settingNotPickupLib, API.settingSMSEnable]
        var notPickupLib = false
        var smsEnable = false
        let req = Gateway.makeRequest(service: API.actor, method: API.orgUnitSettingBatch, args: [orgID, settings, API.anonymousAuthToken], shouldCache: false)
        req.gatewayOptionalObjectResponse().done { obj in
            if let settingObj = obj?.getObject(API.settingNotPickupLib),
                let settingValue = settingObj.getBool("value")
            {
                notPickupLib = settingValue
            }
            if let settingObj = obj?.getObject(API.settingSMSEnable),
                let settingValue = settingObj.getBool("value")
            {
                smsEnable = settingValue
            }
            print("org \(orgID) setting \(API.settingNotPickupLib) value \(notPickupLib)")
            print("org \(orgID) setting \(API.settingSMSEnable) value \(smsEnable)")
            XCTAssertTrue(true, "we do not know what settings what orgs will or will not have")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - sms carriers

    func test_fetchSMSCarriers() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = PCRUDService.fetchSMSCarriers()
        promise.done {
            let carriers = SMSCarrier.getSpinnerLabels()
            for l in carriers {
                print ("carrier: \(l)")
            }
            XCTAssertGreaterThan(carriers.count, 0)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    //MARK: - Copy Status

    func test_copyStatusAll() {
        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")
        
        let promise = SearchService.fetchCopyStatusAll()
        print("xxx promise made")
        promise.done {
            XCTAssertGreaterThan(CopyStatus.status.count, 0)
            expectation.fulfill()
        }.catch { error in
            print("xxx promise caught")
            let str = error.localizedDescription
            print("xxx \(str)")
            XCTFail(error.localizedDescription)
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_copyCounts() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = SearchService.fetchCopyCount(orgID: self.consortiumOrgID, recordID: self.sampleRecordID)
        promise.done { array in
            let copyCounts = CopyCount.makeArray(fromArray: array)
            XCTAssertGreaterThan(copyCounts.count, 0)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func test_copyLocationCounts() {
        let expectation = XCTestExpectation(description: "async response")
        
        let org = Organization(id: 1, level: 0, name: "Consort", shortname: "CONS", ouType: 0, opacVisible: true, aouObj: OSRFObject())
        let promise = SearchService.fetchCopyLocationCounts(org: org, recordID: sampleRecordID)
        promise.done { resp in
            XCTAssertNotNil(resp.payload)
            let copyLocationCounts = CopyLocationCounts.makeArray(fromPayload: resp.payload!)
            XCTAssertNotNil(copyLocationCounts)
            //XCTAssertEqual(copyLocationCounts.count, 1)
            //let copyLocationCount = copyLocationCounts.first
            //XCTAssertEqual(copyLocationCount?.countsByStatus.count, 1)
            //XCTAssertEqual(copyLocationCount?.shelvingLocation, "Adult")
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    //MARK: - misc API
    
    func test_retrieveBRE() {
        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")
        
        let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveBRE, args: [API.anonymousAuthToken, self.sampleRecordID], shouldCache: false)
        req.gatewayObjectResponse().done({ obj in
            let marcXML = obj.getString("marc")
            XCTAssertNotNil(marcXML)
            let parser = MARCXMLParser(data: marcXML!.data(using: .utf8)!)
            if let marcRecord = try? parser.parse() {
                print("marcRecord = \(marcRecord)")
            } else {
                XCTFail(parser.error?.localizedDescription ?? "??")
            }
            expectation.fulfill()
        }).catch({ error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func test_hoursOfOperation() {
        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")

        let promise = makeAuthtokenPromise()
        promise.then { (authtoken: String) -> Promise<(OSRFObject?)> in
            XCTAssertFalse(authtoken.isEmpty)
            return ActorService.fetchOrgHours(authtoken: authtoken, forOrgID: self.homeOrgID)
        }.done { obj in
            XCTAssertNotNil(obj)
            let mondayOpen = obj?.getString("dow_0_open")
            XCTAssertEqual(mondayOpen?.isEmpty, false)
            let sundayClose = obj?.getString("dow_6_close")
            XCTAssertEqual(sundayClose?.isEmpty, false)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - serverVersion

    func test_serverVersion() {
        let expectation = XCTestExpectation(description: "async response")
        
        let promise = ActorService.fetchServerVersion()
        promise.done {
            XCTAssertNotNil(Gateway.serverVersionString)
            expectation.fulfill()
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 20.0)
    }

    //MARK: - API Manual Test Playground
    // these tests are skipped unless run manually

    func test_checkoutHistory() throws {
        if !manualTestsEnabled {
            throw XCTSkip("manual test")
        }

        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")

        let promise = makeAuthtokenPromise()
        promise.then { (authtoken: String) -> Promise<[OSRFObject]> in
            XCTAssertFalse(authtoken.isEmpty)
            return ActorService.fetchCheckoutHistory(authtoken: authtoken)
        }.done { arr in
            XCTAssertNotNil(arr)
            expectation.fulfill()
            let objs = HistoryRecord.makeArray(arr)
            if objs.count > 0 {
                let item = objs[0]
                print("objs[0] = \(item)")
            }
            if objs.count > 1 {
                let item = objs[1]
                print("objs[1] = \(item)")
            }
            print("stop here")
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2000.0)
    }

    func test_patronSettingUpdate() throws {
        if !updateTestsEnabled {
            throw XCTSkip("update tests not enabled")
        }

        XCTAssertTrue(loadIDL())

        let expectation = XCTestExpectation(description: "async response")

        let promise = makeFetchSessionPromise()
        promise.then {
            let account = LiveServiceTests.state!.account
            let obj = LiveServiceTests.state!.sessionObj
            account.loadSession(fromObject: obj!)
            return ActorService.updatePatronSetting(authtoken: self.authtoken!, userID: self.userID!, name: API.userSettingCircHistoryStart, value: "2023-12-22")
        }.done { str in
            XCTAssertNotNil(str)
            expectation.fulfill()
            print("resp = \(str)")
        }.catch { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2000.0)
    }
}
