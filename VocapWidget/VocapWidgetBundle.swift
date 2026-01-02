//
//  VocapWidgetBundle.swift
//  VocapWidget
//
//  Created by Isaac Franks on 02/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct VocapWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocapWidget()
        VocapWidgetControl()
    }
}
