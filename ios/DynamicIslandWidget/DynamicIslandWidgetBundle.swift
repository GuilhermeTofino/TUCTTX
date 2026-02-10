//
//  DynamicIslandWidgetBundle.swift
//  DynamicIslandWidget
//
//  Created by Guilherme Tofino on 09/02/26.
//

import WidgetKit
import SwiftUI

@main
struct DynamicIslandWidgetBundle: WidgetBundle {
    var body: some Widget {
        DynamicIslandWidget()
        DynamicIslandWidgetControl()
        DynamicIslandWidgetLiveActivity()
    }
}
