//
//  ScrollOffsetPreferenceKey.swift
//  NOSwipeRefreshList
//
//  Created by Deo on 2020/9/24.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
