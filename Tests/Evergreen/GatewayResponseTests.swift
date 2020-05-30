//
//  GatewayResponseTests.swift
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
import Foundation
@testable import Hemlock

class GatewayResponseTests: XCTestCase {
    
    func test_failed_badJSON() {
        let json = """
            xyzzy
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "Internal Server Error; the server response is not JSON")
    }
    
    func test_failed_missingStatus() {
        let json = """
            {}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "Internal Server Error; the server response has no status")
    }
    
    func test_failed_badStatus() {
        let json = """
            {"status":404}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "Request failed with status 404")
    }
    
    func test_degenerateResponse() {
        let json = """
            {"payload":[[]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.type, .array)
        XCTAssertEqual(resp.arrayResult?.count, 0)
    }

    func test_authInitResponse() {
        let json = """
            {"payload":["nonce"],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.stringResult, "nonce")
    }
    
    func test_authCompleteSuccess() {
        let json = """
            {"payload":[{"ilsevent":0,"textcode":"SUCCESS","desc":"Success","pid":6939,"stacktrace":"oils_auth.c:634","payload":{"authtoken":"985cda3d943232fbfd987d85d1f1a8af","authtime":420}}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.obj?.getString("textcode"), "SUCCESS")
        XCTAssertEqual(resp.obj?.getString("desc"), "Success")
        let payload = resp.obj?.getObject("payload")
        XCTAssertEqual(payload?.getInt("authtime"), 420)
    }

    func test_authCompleteFailed() {
        let json = """
            {"payload":[{"ilsevent":1000,"textcode":"LOGIN_FAILED","desc":"User login failed"}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "User login failed")
    }
    
    func test_renewFailed() {
        let json = """
            {"payload":[{"ilsevent":"7008","servertime":"Sun Jul  1 23:15:38 2018","pid":22531,"desc":" Circulation has no more renewals remaining ","textcode":"MAX_RENEWALS_REACHED","stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:3701 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:274 /usr/local/share/perl/5.22.1/OpenSRF/Application.pm:628"}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, " Circulation has no more renewals remaining ")
    }
    
    func test_renewFailedForTwoReasons() {
        let json = """
            {"payload":[[{"payload":{"fail_part":"asset.copy_location.circulate"},"stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:1293 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4082 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4034","desc":" Target copy is not allowed to circulate ","ilsevent":"7003","textcode":"COPY_CIRC_NOT_ALLOWED","servertime":"Sat Feb 23 20:55:17 2019","pid":17822},{"payload":{"fail_part":"PATRON_EXCEEDS_FINES"},"pid":17822,"ilsevent":"7013","servertime":"Sat Feb 23 20:55:17 2019","textcode":"PATRON_EXCEEDS_FINES","stacktrace":"/usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:1293 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4082 /usr/local/share/perl/5.22.1/OpenILS/Application/Circ/Circulate.pm:4034","desc":"The patron in question has reached the maximum fine amount"}]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, " Target copy is not allowed to circulate ")
    }
    
    func test_actorCheckedOut() {
        let json = """
            {"status":200,"payload":[{"overdue":[],"out":["73107615","72954513"],"lost":[1,2]}]}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))

        // we can treat "out" as a list of Any
        guard let out = resp.obj?.getAny("out") as? [Any] else {
            XCTFail()
            return
        }
        XCTAssertEqual(out.count, 2)

        // or as a list of IDs
        XCTAssertEqual(resp.obj?.getIDList("out"), [73107615, 72954513])
        XCTAssertEqual(resp.obj?.getIDList("overdue"), [])
        XCTAssertEqual(resp.obj?.getIDList("lost"), [1,2])
    }

    func test_withNullValue() {
        let json = """
            {"payload":[{"children":null}],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        guard let obj = resp.obj else {
            XCTFail()
            return
        }
        if let children = obj.dict["children"] {
            XCTAssertNil(children)
        } else {
            XCTFail()
        }
    }
    
    func test_copyLocationCounts() {
        let json = """
            {"payload":[[["280","","782.2530973 AMERICAN","","Adult",{"1":1}]]],"status":200}
            """
        let resp = GatewayResponse(json)
        XCTAssertFalse(resp.failed, String(describing: resp.error))
        XCTAssertEqual(resp.type, .unknown)
        guard let payload = resp.payload,
            let payloadArray = payload as? [Any],
            let first = payloadArray.first as? [Any],
            let counts = first.first as? [Any] else
        {
            XCTFail()
            return
        }
        XCTAssertEqual(payloadArray.count, 1)
        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(counts.count, 6)
    }
    
    func test_errorResponseNotJSON() {
        let jsonIsh = """
            {"payload":[],"debug": "osrfMethodException :  *** Call to [open-ils.search.biblio.multiclass.query] failed for session [1590536419.970333.159053641999519], thread trace [1]:\nException: OpenSRF::EX::ERROR 2020-05-26T19:41:01 OpenSRF::Application /usr/local/share/perl/5.22.1/OpenSRF/Application.pm:243 System ERROR: Call to open-ils.storage for method open-ils.storage.biblio.multiclass.staged.search_fts.atomic \n failed with exception: Exception: OpenSRF::EX::ERROR 2020-05-26T19:41:01 OpenILS::Application::AppUtils /usr/local/share/perl/5.22.1/OpenILS/Application/AppUtils.pm:201 System ERROR: Exception: OpenSRF::DomainObject::oilsMethodException 2020-05-26T19:41:01 OpenSRF::AppRequest /usr/local/share/perl/5.22.1/OpenSRF/AppSession.pm:1159 <500>   *** Call to [open-ils.storage.biblio.multiclass.staged.search_fts.atomic] failed for session [1590536419.97576725.9316069925], thread trace [1]:\nDBD::Pg::st execute failed: ERROR:  canceling statement due to user request [for Statement \"        -- bib search: #CD_documentLength #CD_meanHarmonic #CD_uniqueWords core_limit(10000) badge_orgs(129,1,124) estimation_strategy(inclusion) skip_check(0) check_limit(1000) subject:romance fiction site(CLAYTN-MOR)\n        WITH w AS (\n\n\nWITH xf24f4e0_subject_xq AS (SELECT \n      (to_tsquery('english_nostop', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$romance$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), '')) || to_tsquery('simple', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$romance$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), '')))&&\n      (to_tsquery('simple', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$fiction$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), '')) || to_tsquery('english_nostop', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$fiction$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), ''))) AS tsq,\n      (to_tsquery('english_nostop', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$romance$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), '')) || to_tsquery('simple', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$romance$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), ''))) ||\n      (to_tsquery('simple', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$fiction$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), '')) || to_tsquery('english_nostop', COALESCE(NULLIF( '(' || btrim(regexp_replace(search_normalize(split_date_range($_100403$fiction$_100403$)),E'(?:\\\\s+|:)','&','g'),'&|')  || ')', '()'), ''))) AS tsq_rank ),lang_with AS (SELECT id FROM config.coded_value_map WHERE ctype = 'item_lang' AND code = $_100403$eng$_100403$),        pop_with AS (\n            SELECT  record,\n                    ARRAY_AGG(badge) AS badges,\n                    SUM(s.score::NUMERIC*b.weight::NUMERIC)/SUM(b.weight::NUMERIC) AS total_score\n              FROM  rating.record_badge_score s\n                    JOIN rating.badge b ON (\n                        b.id = s.badge\n AND b.scope = ANY ('{129,1,124}')) GROUP BY 1)\n,c_attr AS (SELECT (ARRAY_TO_STRING(ARRAY[c_attrs,search.calculate_visibility_attribute_test('circ_lib','{129}',FALSE)],'&'))::query_int AS vis_test FROM asset.patron_default_visibility_mask() x)\n,b_attr AS (SELECT (b_attrs||search.calculate_visibility_attribute_test('luri_org','{129,1,124}',FALSE))::query_int AS vis_test FROM asset.patron_default_visibility_mask() x)\nSELECT  id,\n        rel,\n        CASE WHEN cardinality(records) = 1 THEN records[1] ELSE NULL END AS record,\n        NULL::INT AS total,\n        NULL::INT AS checked,\n        NULL::INT AS visible,\n        NULL::INT AS deleted,\n        NULL::INT AS excluded,\n        badges,\n        popularity\n  FROM  (SELECT m.source AS id,\n                ARRAY[m.source] AS records,\n                (AVG(\n          (COALESCE(ts_rank_cd('{0.1, 0.2, 0.4, 1.0}', xf24f4e0_subject.index_vector, xf24f4e0_subject.tsq_rank, 14) * xf24f4e0_subject.weight * 1000, 0.0))\n        )+1 * COALESCE( NULLIF( FIRST(mrv.vlist @> ARRAY[lang_with.id]), FALSE )::INT * 5, 1))::NUMERIC AS rel,\n                1.0/((AVG(\n          (COALESCE(ts_rank_cd('{0.1, 0.2, 0.4, 1.0}', xf24f4e0_subject.index_vector, xf24f4e0_subject.tsq_rank, 14) * xf24f4e0_subject.weight * 1000, 0.0))\n        )+1 * COALESCE( NULLIF( FIRST(mrv.vlist @> ARRAY[lang_with.id]), FALSE )::INT * 5, 1)))::NUMERIC AS rank, \n                FIRST(pubdate_t.value) AS tie_break,\n                STRING_AGG(ARRAY_TO_STRING(pop_with.badges,','),',') AS badges,\n                AVG(COALESCE(pop_with.total_score::NUMERIC,0.0::NUMERIC))::NUMERIC(2,1) AS popularity\n          FROM  metabib.metarecord_source_map m\n                \n        LEFT JOIN (\n          SELECT fe.*, fe_weight.weight, xf24f4e0_subject_xq.tsq, xf24f4e0_subject_xq.tsq_rank /* search */\n            FROM  metabib.subject_field_entry AS fe\n              JOIN config.metabib_field AS fe_weight ON (fe_weight.id = fe.field)\n              JOIN metabib.combined_subject_field_entry AS com ON (com.record = fe.source AND com.metabib_field IS NULL)\n              JOIN xf24f4e0_subject_xq ON (com.index_vector @@ xf24f4e0_subject_xq.tsq)\n        ) AS xf24f4e0_subject ON (m.source = xf24f4e0_subject.source)\n                \n                INNER JOIN metabib.record_attr_vector_list mrv ON m.source = mrv.source\n                INNER JOIN biblio.record_entry bre ON m.source = bre.id AND NOT bre.deleted\n                LEFT JOIN pop_with ON ( m.source = pop_with.record )\n                LEFT JOIN metabib.record_sorter pubdate_t ON m.source = pubdate_t.source AND attr = 'pubdate'\n                ,lang_with\n                ,c_attr\n                ,b_attr \n          WHERE 1=1\n                AND (\n          (xf24f4e0_subject.id IS NOT NULL)\n        )\n        AND (\n          (EXISTS (SELECT 1 FROM asset.copy_vis_attr_cache WHERE record = m.source AND vis_attr_vector @@ c_attr.vis_test)) OR ((b_attr.vis_test IS NULL OR bre.vis_attr_vector @@ b_attr.vis_test))\n        )\n          GROUP BY 1\n          ORDER BY 4 ASC NULLS LAST,  5 DESC NULLS LAST, 3 DESC\n          LIMIT 10000\n        ) AS core_query\n) (SELECT * FROM w LIMIT 1000 OFFSET 0)\n        UNION ALL\n  SELECT NULL,NULL,NULL,COUNT(*),COUNT(*),COUNT(*),0,0,NULL,NULL F,"status":500}
            """
        let resp = GatewayResponse(jsonIsh)
        XCTAssertTrue(resp.failed)
        XCTAssertEqual(resp.errorMessage, "Timeout; the request took too long to complete and the server killed it")
    }
}
