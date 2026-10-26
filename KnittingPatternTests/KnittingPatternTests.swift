//
//  KnittingPatternTests.swift
//  KnittingPatternTests
//
//  Created by Ekaterina on 26.10.2026.
//

import Foundation
import Testing
@testable import KnittingPattern

struct StitchTests {

    @Test func everyStitchIDHasSymbol() {
        for id in StitchID.allCases {
            #expect(Stitch.with(id: id) != nil, "Нет значка для \(id)")
        }
    }

    @Test func eachStitchIsListedOnce() {
        let ids = (Stitch.crochet + Stitch.knitting).map(\.id)
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
