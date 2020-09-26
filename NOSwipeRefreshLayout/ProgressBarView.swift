//
//  ProgressBarView.swift
//  NOSwipeRefreshList
//
//  Created by Deo on 2020/9/24.
//

import SwiftUI

public struct ProgressBarView: View {
    @State var spinCircle = false
    @State private var schedule:Double = 0
    
    public init(){}
    
    public var body: some View{
        GeometryReader { geometry in
            Image(systemName: "arrow.2.circlepath")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(minWidth:1 , maxWidth: .infinity, minHeight: 1, maxHeight: .infinity)
                .rotationEffect(.degrees(self.schedule))
                .foregroundColor(.gray)
                .padding(self.getPadding(geometry))
                .background(Circle().foregroundColor(.white).shadow(color: .gray, radius: 2, x: 2, y: 2))
                .onReceive(Timer.publish(every: 1.0/60.0, on: .main, in: .default).autoconnect()) { _ in
                    let progress = 4
                    let befor = Int(self.schedule) / progress
                    self.schedule = Double(((befor + 1) * progress) % 360)
                }.padding(4)
        }
        
    }
    
    private func getPadding(_ geometry:GeometryProxy)->CGFloat{
        let w = geometry.size.width
        let h = geometry.size.height
        let v = w > h ? h : w
        return v/10
    }
}
