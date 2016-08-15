//
//  TimecodeFormatter.swift
//  TAAE2
//
//  Created by Mark Jeschke on 7/17/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

import Foundation

class TimecodeFormatter {
    func convertSecondsToTimecode(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

