//
//  StitchTests.swift
//  ThreadfolioTests
//
//  Created by Ekaterina on 26.10.2026.
//

import Foundation
import Testing
@testable import Threadfolio

struct StitchTests {

    @Test func everyStitchIDHasSymbol() {
        for id in StitchID.allCases {
            #expect(Stitch.with(id: id) != nil, "No symbol for \(id)")
        }
    }

    @Test func eachStitchIsListedOnce() {
        let ids = Stitch.everything.map(\.id)
        #expect(ids.count == Set(ids).count)
        #expect(Set(ids) == Set(StitchID.allCases))
    }

    @Test func cellKeepsStoredFormat() throws {
        let cell = Cell(symbol: .singleCrochetPlus, color: .palette(.blue))
        let json = try #require(String(data: JSONEncoder().encode(cell), encoding: .utf8))
        #expect(json.contains(#""s":"sc+""#))
        #expect(try JSONDecoder().decode(Cell.self, from: Data(json.utf8)) == cell)
    }
}
