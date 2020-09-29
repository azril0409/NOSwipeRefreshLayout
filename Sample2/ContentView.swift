//
//  ContentView.swift
//  Sample2
//
//  Created by Deo on 2020/9/29.
//

import SwiftUI
import NOSwipeRefreshLayout

struct ContentView: View {
    @State private var isShowProgressBar = false
    @State private var isOnRefresh = false
    @State private var isOnAppend = false
    @State private var items:[Item] = []
    @State private var text = ""
    
    var body: some View {
        NOSwipeRefreshLayout(axes:.vertical,
                             progressBarAxes:.vertical,
                             isShowProgressBar: self.$isShowProgressBar,
                             onScroll:{ rect in
                                self.text = "x:\(rect.origin.x), y:\(rect.origin.y), width:\(rect.size.width), height:\(rect.size.height)"
                             },
                             onRefresh: {
                                self.isOnRefresh = true },
                             onAppend:{
                                self.isOnAppend = true }
        ){
            VStack{
                Text(self.text)
                ForEach(self.items) { item in
                    Text(item.id.uuidString)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.cornerRadius(8).shadow(color: .gray, radius: 2, x: 2, y: 2)).padding()
                }
                Spacer()
                Text(self.text)
            }
        }
        .onReceive(Timer.publish(every: 3, on: .main, in: .default).autoconnect(), perform: { _ in
            self.isShowProgressBar = false
            if self.isOnRefresh {
                self.isOnRefresh = false
                self.items.removeAll()
            }
            if self.isOnAppend {
                self.isOnAppend = false
                self.items.append(Item())
            }
        })
    }
}

struct Item:Identifiable{
    let id:UUID = UUID()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
