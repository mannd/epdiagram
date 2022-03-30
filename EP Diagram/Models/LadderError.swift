//
//  LadderError.swift
//  EP Diagram
//
//  Created by David Mann on 4/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation

/// Errors that are used when editing marks.
enum LadderError: Error {
    case notCalibrated
    case tooFewMarks
    case requireTwoMarks
    case marksInDifferentRegions
    case marksNotContiguous
    case tooManyRegions
    case marksIntersect
    case marksNotVertical
    case intervalTooShort
    case marksNotParallel
    case noMarks
    case illegalPattern
    case noJoiningMark
    case illegalJoiningMark
    case didNotTapAMark
    case onlyOneSelectedMarkInRegion
    case markNotAtEitherEndOfSelection
    case periodsAreNotSimilar
    case noRegionSelected
    case noPeriodsInLadder
}

extension LadderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notCalibrated:
            return L("Diagram is not calibrated.  You must calibrate first.")
        case .tooFewMarks:
            return L("There are too few marks.  You need to select at least 2 marks.")
        case .requireTwoMarks:
            return L("Exactly two marks must be selected.")
        case .marksInDifferentRegions:
            return L("Selected marks are in different regions.  Marks must be in the same region.")
        case .marksNotContiguous:
            return L("Marks are not contiguous.  Selected marks must be contiguous.")
        case .tooManyRegions:
            return L("Rhythm can only be set in one region at a time.")
        case .marksIntersect:
            return L("Marks cannot intersect")
        case .marksNotVertical:
            return L("Marks must be vertical.")
        case .intervalTooShort:
            return L("Interval is too short.")
        case .marksNotParallel:
            return L("Marks are not parallel.")
        case .noMarks:
            return L("No marks are selected.")
        case .illegalPattern:
            return L("Illegal pattern.")
        case .noJoiningMark:
            return L("Pattern doesn't have a joining mark.")
        case .illegalJoiningMark:
            return L("Mark doesn't qualify as joining mark.")
        case .didNotTapAMark:
            return L("You must select a mark.")
        case .onlyOneSelectedMarkInRegion:
            return L("There is only one selected mark in this region.")
        case .markNotAtEitherEndOfSelection:
            return L("Mark not at either end of selection.")
        case .periodsAreNotSimilar:
            return L("You can only edit periods of multiple marks if the periods are all the same.")
        case .noRegionSelected:
            return L("You must select a region or zone to add a rhythm.")
        case .noPeriodsInLadder:
            return L("This ladder has no periods yet that can be copied.  Add at least one period to a mark first.")
        }
    }
}

