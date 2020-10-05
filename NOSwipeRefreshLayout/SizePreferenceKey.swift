//
//  HeightPreferenceKey.swift
//  NOSwipeRefreshLayout
//
//  Created by Deo on 2020/9/24.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    typealias Value = [CGFloat]
    
    static var defaultValue: [CGFloat] = [0,0]
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value[0] = nextValue()[0]
        value[1] = nextValue()[1]
    }
}
