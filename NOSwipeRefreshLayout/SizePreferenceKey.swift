//
//  HeightPreferenceKey.swift
//  NOSwipeRefreshLayout
//
//  Created by Deo on 2020/9/24.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    
    static var defaultValue: CGSize = CGSize(width: 0, height: 0)
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
