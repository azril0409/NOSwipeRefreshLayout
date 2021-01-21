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
    @State private var items:[Item] = [Item(),Item(),Item(),Item(),Item(),Item(),Item(),Item()]
    @State private var text = ""
    
    var body: some View {
        VStack{
            self.layout
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var layout: some View {
        NOSwipeRefreshLayout(axes: .horizontal,
                             progressBarView: AnyView(Color.yellow),
                             progressBarAxes: .leading,
                             isShowProgressBar: self.$isShowProgressBar,
                             onScroll:{ rect in
                                self.text = "x:\(rect.origin.x), y:\(rect.origin.y), width:\(rect.size.width), height:\(rect.size.height)"
                             },
                             onRefresh: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.isShowProgressBar = false
                                    self.items.removeAll()
                                }
                             },
                             onAppend:{
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.isShowProgressBar = false
                                    self.items.append(Item())
                                }
                             }
        ){
            HStack{
                ForEach(self.items) { item in
                    Text(item.id.uuidString)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.cornerRadius(8).shadow(color: .gray, radius: 2, x: 2, y: 2)).padding()
                }
                Spacer()
            }.padding()
        }
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
