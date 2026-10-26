//
//  StitchID.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

/// Идентификатор условного обозначения петли. Строковое значение
/// записывается в схему, поэтому его нельзя менять у существующих петель.
enum StitchID: String, CaseIterable, Codable {
    
    // Крючок
    case chain = "ch"
    case slipStitch = "sl"
    case singleCrochet = "sc"
    case singleCrochetPlus = "sc+"
    case halfDoubleCrochet = "hdc"
    case doubleCrochet = "dc"
    case trebleCrochet = "tr"
    case magicRing = "mr"
    case crochetIncrease = "inc"
    case crochetDecrease = "dec"
    case backLoopOnly = "blo"
    case frontLoopOnly = "flo"
    case shell
    case puff
    case popcorn = "pop"
    case picot
    case frontPostDoubleCrochet = "fpdc"
    case backPostDoubleCrochet = "bpdc"
    case doubleCrochet2Together = "dc2tog"
    case vStitch = "v"

    // Спицы
    case knit = "k"
    case purl = "p"
    case purlDot = "pdot"
    case yarnOver = "yo"
    case knit2Together = "k2tog"
    case slipSlipKnit = "ssk"
    case knit3Together = "k3tog"
    case slipped = "slip"
    case knitThroughBackLoop = "ktbl"
    case makeOne = "m1"
    case rightCross = "c2r"
    case leftCross = "c2l"
    case bobble = "mb"
    case bindOff = "bo"
    case castOn = "co"
    case noStitch = "ns"
}
