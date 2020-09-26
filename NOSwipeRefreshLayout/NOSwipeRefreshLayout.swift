//
//  NOSwipeRefreshList.swift
//  NOSwipeRefreshList
//
//  Created by Deo on 2020/9/24.
//

import Combine
import SwiftUI

public struct NOSwipeRefreshLayout<Content:View>: View {
    private let axes: Axis.Set
    private let showsIndicators:Bool
    private let progressBarView:AnyView
    private let progressBarAxes: Axis.Set
    private let content:()->Content
    private let thresholdValue:CGFloat
    @Binding private var isShowProgressBar:Bool
    private let enableRefresh:Bool
    private let enableAppend:Bool
    private let onScroll:(CGRect)->Void
    private let onRefresh:()->Void
    private let onAppend:()->Void
    @State private var beforeValue:CGFloat = 0
    @State private var afterValue:CGFloat = 0
    @State private var refreshFirstThreshold = false
    @State private var refreshSecondThreshold = false
    @State private var appendFirstThreshold = false
    @State private var appendSecondThreshold = false
    @State private var insideHeight:CGFloat = 0
    @State private var insideWidth:CGFloat = 0
    @State private var beforeProgressBarStatus = false
    
    @State var log = ""
    
    public init(axes: Axis.Set = .vertical,
                showsIndicators:Bool = true,
                progressBarView: AnyView = AnyView(ZStack{ProgressBarView().frame(maxWidth: 48, maxHeight: 48)}),
                progressBarAxes: Axis.Set = .vertical,
                thresholdValue:CGFloat = 96,
                isShowProgressBar: Binding<Bool>,
                enableRefresh:Bool = true,
                enableAppend:Bool = true,
                onScroll:@escaping (CGRect)->Void = {_ in},
                onRefresh:@escaping ()->Void = {},
                onAppend:@escaping ()->Void = {},
                @ViewBuilder content:@escaping ()->Content){
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.progressBarView = progressBarView
        self.progressBarAxes = progressBarAxes
        self.thresholdValue = thresholdValue
        self._isShowProgressBar = isShowProgressBar
        self.enableRefresh = enableRefresh
        self.enableAppend = enableAppend
        self.onScroll = onScroll
        self.onRefresh = onRefresh
        self.onAppend = onAppend
        self.content = content
    }
    
    
    public var body: some View {
        ZStack{
            GeometryReader { outsideProxy in
                ScrollView(self.axes, showsIndicators: self.showsIndicators){
                    ZStack{
                        GeometryReader { insideProxy in
                            Color.clear.onAppear{
                                self.isShowProgressBar = false
                            }
                            .preference(key: ScrollOffsetPreferenceKey.self, value: self.calculateContentOffset(outsideProxy, insideProxy))
                            .preference(key: SizePreferenceKey.self, value: insideProxy.size)
                        }.onPreferenceChange(ScrollOffsetPreferenceKey.self){ value in
                            self.onScrollOffsetChange(outsideProxy: outsideProxy, value: value)
                            self.oncalculateScrollCallback(outsideProxy: outsideProxy, value: value)
                        }.onPreferenceChange(SizePreferenceKey.self){ size in
                            self.insideHeight = size.height
                            self.insideWidth = size.width
                        }
                        self.content()
                    }.frame( minWidth:outsideProxy.size.width,
                             maxWidth: .infinity,
                             minHeight: outsideProxy.size.height,
                             maxHeight: .infinity)
                }
                
                VStack(){
                    self.progressBarView.frame(width: self.getProgressBarWidth(outsideProxy), height: self.getProgressBarHeight(outsideProxy)).clipped()
                    Spacer()
                }
                VStack{
                    Text(self.log)
                }
            }
        }
        .clipped()
        .edgesIgnoringSafeArea(.all)
        .onReceive(Just(self.isShowProgressBar), perform: { value in
            if value != self.beforeProgressBarStatus {
                if value == false {
                    withAnimation(.spring()){
                        self.afterValue = 0
                        self.beforeValue = 0
                    }
                }
            }
            self.beforeProgressBarStatus = value
        })
    }
    
    private func onScrollOffsetChange(outsideProxy:GeometryProxy, value:CGFloat){
        if !self.isShowProgressBar {
            self.afterValue = value
            let v :CGFloat
            if self.axes == .vertical {
                v = (self.insideHeight - outsideProxy.size.height - self.afterValue)
            } else {
                v = (self.insideWidth - outsideProxy.size.width - self.afterValue)
            }
            if self.enableRefresh && self.afterValue < 0{
                if self.refreshFirstThreshold && self.refreshSecondThreshold && abs(self.afterValue) <= self.thresholdValue {
                    self.refreshFirstThreshold = false
                    self.refreshSecondThreshold = false
                    self.isShowProgressBar = true
                    self.onRefresh()
                }else if self.refreshFirstThreshold && self.afterValue > self.beforeValue{
                    self.refreshSecondThreshold = true
                }else if abs(self.afterValue) > self.thresholdValue {
                    self.refreshFirstThreshold = true
                }
            }else if self.enableAppend && v < 0 {
                if self.appendFirstThreshold && self.appendSecondThreshold && abs(v) <= self.thresholdValue {
                    self.appendFirstThreshold = false
                    self.appendSecondThreshold = false
                    self.isShowProgressBar = true
                    self.onAppend()
                }else if self.appendFirstThreshold && self.beforeValue > self.afterValue {
                    self.appendSecondThreshold = true
                }else if abs(v) > self.thresholdValue {
                    self.appendFirstThreshold = true
                }
            }
        }
        self.beforeValue = value
    }
    
    private func oncalculateScrollCallback(outsideProxy:GeometryProxy, value:CGFloat){
        if self.axes == .horizontal {
            let y:CGFloat = 0
            let height = outsideProxy.size.height
            let x = value
            var width = x + outsideProxy.size.width
            if width > insideWidth {
                width = insideWidth
            }
            onScroll(CGRect(x: x, y: y, width: width, height: height))
        }else{
            let x:CGFloat = 0
            let width = outsideProxy.size.width
            let y = value
            var height = y + outsideProxy.size.height
            if height > insideHeight {
                height = insideHeight
            }
            onScroll(CGRect(x: x, y: y, width: width, height: height))
        }
    }
    
    
    private func calculateContentOffset(_ outsideProxy: GeometryProxy,_ insideProxy: GeometryProxy) -> CGFloat {
        if axes == .vertical {
            let outsideGlobal = outsideProxy.frame(in: .global).maxY
            let insideGlobal = insideProxy.frame(in: .global).maxY
            let outsideHeight = outsideProxy.size.height
            let insideHeight = insideProxy.size.height
            return outsideGlobal - insideGlobal + insideHeight - outsideHeight
        } else {
            let outsideGlobal = outsideProxy.frame(in: .global).minX
            let insideGlobal = insideProxy.frame(in: .global).minX
            return outsideGlobal - insideGlobal
        }
    }
    
    private func getProgressBarWidth(_ outsideProxy:GeometryProxy) -> CGFloat{
        if self.progressBarAxes == .horizontal {
            let value:CGFloat
            if self.axes == .horizontal {
                if self.afterValue > 0 {
                    let v = getHorizontalDifferenceValue(outsideProxy)
                    if v > 0 {
                        value = 0
                    }else{
                        value = self.enableAppend ? abs(v) : 0
                    }
                }else{
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }else{
                if self.afterValue > 0 {
                    let v = self.getVerticalDifferenceValue(outsideProxy)
                    if v > 0 {
                        value = 0
                    }else{
                        value = self.enableAppend ? abs(v) : 0
                    }
                }else{
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }
            if self.isShowProgressBar || self.appendSecondThreshold || self.refreshSecondThreshold {
                return value >= 0 ? value : 0
            }
            return value
        }else{
            return outsideProxy.size.width
        }
    }
    
    private func getProgressBarHeight(_ outsideProxy:GeometryProxy) -> CGFloat{
        if self.progressBarAxes == .horizontal {
            return outsideProxy.size.height
        } else {
            let value:CGFloat
            if self.axes == .horizontal {
                if self.afterValue >= 0 {
                    let v = getHorizontalDifferenceValue(outsideProxy)
                    if  v < 0 {
                        value = self.enableAppend ? abs(v) : 0
                    }else{
                        value = 0
                    }
                }else {
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }else{
                if self.afterValue >= 0 {
                    let v = self.getVerticalDifferenceValue(outsideProxy)
                    if  v < 0 {
                        value = self.enableAppend ? abs(v) : 0
                    }else {
                        value = 0
                    }
                }else {
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }
            if self.isShowProgressBar || self.appendSecondThreshold || self.refreshSecondThreshold {
                return value >= 0 ? value : 0
            }
            return value
        }
    }
    
    private func getProgressBarOffsetX(_ outsideProxy:GeometryProxy) -> CGFloat{
        if self.isShowProgressBar { return 0 }
        if self.progressBarAxes == .horizontal {
            if self.axes == .horizontal {
                if self.afterValue > 0 {
                    let v = getHorizontalDifferenceValue(outsideProxy)
                    if v > 0 {
                        return -self.thresholdValue
                    }
                    return -self.thresholdValue + abs(v)
                }
                return  -self.thresholdValue + abs(self.afterValue)
            }else{
                if self.afterValue > 0 {
                    let v = self.getVerticalDifferenceValue(outsideProxy)
                    if v > 0 {
                        return -self.thresholdValue
                    }
                    return -self.thresholdValue + abs(v)
                }
                return  -self.thresholdValue + abs(self.afterValue)
            }
        }else{
            return 0
        }
    }
    
    private func getProgressBarOffsetY(_ outsideProxy:GeometryProxy) -> CGFloat{
        if self.isShowProgressBar { return 0 }
        if self.progressBarAxes == .horizontal {
            return 0
        } else {
            if self.axes == .horizontal {
                if self.afterValue >= 0 {
                    let v = getHorizontalDifferenceValue(outsideProxy)
                    if  v < 0 {
                        return -self.thresholdValue + abs(v)
                    }
                    return -self.thresholdValue
                }
                return -self.thresholdValue + abs(self.afterValue)
            }else{
                if self.afterValue >= 0 {
                    let v = self.getVerticalDifferenceValue(outsideProxy)
                    if  v < 0 {
                        return -self.thresholdValue + abs(v)
                    }
                    return -self.thresholdValue
                }
                return -self.thresholdValue + abs(self.afterValue)
            }
        }
    }
    
    private func getVerticalDifferenceValue(_ outsideProxy:GeometryProxy) -> CGFloat{
        self.insideHeight - outsideProxy.size.height - self.afterValue
    }
    
    private func getHorizontalDifferenceValue(_ outsideProxy:GeometryProxy) -> CGFloat{
        self.insideWidth - outsideProxy.size.width - self.afterValue
    }
}
