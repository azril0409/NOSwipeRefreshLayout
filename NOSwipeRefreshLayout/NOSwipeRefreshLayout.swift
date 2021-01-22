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
    private let progressBarAxes: ProgressBarAlignment
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
    @State private var outsideHeight:CGFloat = CGFloat(0)
    @State private var outsideWidth:CGFloat = CGFloat(0)
    @State private var outsideGlobalX:CGFloat = CGFloat(0)
    @State private var outsideGlobalY:CGFloat = UIScreen.main.bounds.height
    @State private var insideHeight:CGFloat = UIScreen.main.bounds.height
    @State private var insideWidth:CGFloat = UIScreen.main.bounds.width
    @State private var beforeProgressBarStatus = false
    
    public init(axes: Axis.Set = .vertical,
                showsIndicators:Bool = true,
                progressBarView: AnyView = AnyView(ZStack{ProgressBarView().frame(maxWidth: 48, maxHeight: 48)}),
                progressBarAxes: ProgressBarAlignment = .vertical,
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
        ScrollView(self.axes, showsIndicators: self.showsIndicators){
                self.content().background(self.contentBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(self.progressBarLayout)
        .background(layoutBackground)
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
    
    private var progressBarLayout: some View {
        ZStack{
            if self.progressBarAxes == .vertical || self.progressBarAxes == .top {
                VStack{
                    self.progressBarView.frame(width:self.getProgressBarWidth(CGSize(width: self.outsideWidth,
                                                                                     height: self.outsideHeight)),
                                               height: self.getProgressBarHeight(CGSize(width: self.outsideWidth,
                                                                                        height: self.outsideHeight))).clipped()
                    Spacer()
                }
            }else if self.progressBarAxes == .bottom {
                VStack{
                    Spacer()
                    self.progressBarView.frame(width:self.getProgressBarWidth(CGSize(width: self.outsideWidth,
                                                                                     height: self.outsideHeight)),
                                               height: self.getProgressBarHeight(CGSize(width: self.outsideWidth,
                                                                                        height: self.outsideHeight))).clipped()
                }
            }else if self.progressBarAxes == .trailing{
                HStack{
                    Spacer()
                    self.progressBarView.frame(width:self.getProgressBarWidth(CGSize(width: self.outsideWidth,
                                                                                     height: self.outsideHeight)),
                                               height: self.getProgressBarHeight(CGSize(width: self.outsideWidth,
                                                                                        height: self.outsideHeight))).clipped()
                    
                }
            }else {
                HStack{
                    self.progressBarView.frame(width:self.getProgressBarWidth(CGSize(width: self.outsideWidth,
                                                                                     height: self.outsideHeight)),
                                               height: self.getProgressBarHeight(CGSize(width: self.outsideWidth,
                                                                                        height: self.outsideHeight))).clipped()
                    Spacer()
                }
            }
        }
    }
    
    private var layoutBackground: some View{
        GeometryReader { outsideProxy in
            Spacer().preference(key: SizePreferenceKey.self, value: [outsideProxy.frame(in: .local).width,
                                                                     outsideProxy.frame(in: .local).height,
                                                                     outsideProxy.frame(in: .global).minX,
                                                                     outsideProxy.frame(in: .global).maxY,
                                                                     outsideProxy.frame(in: .local).maxY,
                                                                     outsideProxy.frame(in: .local).minY])
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: { value in
            self.outsideWidth = value[0] > 0 ? value[0] : UIScreen.main.bounds.width
            self.outsideHeight = value[1] > 0 ? value[1] :  UIScreen.main.bounds.height
            self.outsideGlobalX = value[2]
            self.outsideGlobalY = value[3]
        })
    }
    
    private var contentBackground: some View{
        GeometryReader { insideProxy in
            Spacer().onAppear{
                self.isShowProgressBar = false
            }
            .preference(key: ScrollOffsetPreferenceKey.self, value: self.calculateContentOffset(insideProxy))
            .preference(key: SizePreferenceKey.self, value: self.getInsideSize(insideProxy))
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self){ value in
            self.onScrollOffsetChange(value: value)
            self.oncalculateScrollCallback(value: value)
        }.onPreferenceChange(SizePreferenceKey.self){ size in
            self.insideWidth = size[0]
            self.insideHeight = size[1]
        }
    }
    
    private func onScrollOffsetChange(value:CGFloat){
        self.afterValue = value
        if !self.isShowProgressBar {
            var v :CGFloat
            if self.axes == .vertical {
                v = (self.insideHeight - self.outsideHeight - value)
            } else {
                v = (self.insideWidth - self.outsideWidth - value)
            }
            if self.enableRefresh && value < 0{
                if self.refreshFirstThreshold && self.refreshSecondThreshold && abs(value) <= self.thresholdValue {
                    self.refreshFirstThreshold = false
                    self.refreshSecondThreshold = false
                    if !self.isShowProgressBar {
                        self.isShowProgressBar = true
                        self.onRefresh()
                    }
                }else if self.refreshFirstThreshold && self.afterValue > self.beforeValue{
                    self.refreshSecondThreshold = true
                }else if abs(self.afterValue) > self.thresholdValue {
                    self.refreshFirstThreshold = true
                }
            }else if self.enableAppend && v < 0 {
                if self.appendFirstThreshold && self.appendSecondThreshold && abs(v) <= self.thresholdValue {
                    self.appendFirstThreshold = false
                    self.appendSecondThreshold = false
                    if !self.isShowProgressBar {
                        self.isShowProgressBar = true
                        self.onAppend()
                    }
                }else if self.appendFirstThreshold && self.beforeValue > self.afterValue {
                    self.appendSecondThreshold = true
                }else if abs(v) > self.thresholdValue {
                    self.appendFirstThreshold = true
                }
            }
        }
        self.beforeValue = self.afterValue
    }
    
    private func oncalculateScrollCallback(value:CGFloat){
        if self.axes == .horizontal {
            let y:CGFloat = 0
            let height = outsideHeight
            let x = value
            var width = x + outsideWidth
            if width > insideWidth {
                width = insideWidth
            }
            onScroll(CGRect(x: x, y: y, width: width, height: height))
        }else{
            let x:CGFloat = 0
            let width = outsideWidth
            let y = value
            var height = y + outsideHeight
            if height > insideHeight {
                height = insideHeight
            }
            onScroll(CGRect(x: x, y: y, width: width, height: height))
        }
    }
    
    private func calculateContentOffset(_ insideProxy: GeometryProxy) -> CGFloat {
        if axes == .vertical {
            let outsideGlobal = outsideGlobalY
            let insideGlobal = insideProxy.frame(in: .global).maxY
            let outsideHeight = self.outsideHeight
            let insideHeight = insideProxy.size.height
            return outsideGlobal - insideGlobal + insideHeight - outsideHeight
        } else {
            let outsideGlobal = outsideGlobalX
            let insideGlobal = insideProxy.frame(in: .global).minX
            return outsideGlobal - insideGlobal
        }
    }
    
    private func getInsideSize(_ insideProxy: GeometryProxy) -> [CGFloat]{
        getInsideSize(CGSize(width: outsideWidth, height: outsideHeight), insideProxy.size)
    }
    
    private func getInsideSize(_ outsideSize: CGSize, _ insideSize: CGSize) -> [CGFloat]{
        let w = insideSize.width < outsideSize.width ? outsideSize.width : insideSize.width
        let h = insideSize.height < outsideSize.height ? outsideSize.height : insideSize.height
        return [w,h]
    }
    
    private func getProgressBarWidth(_ outsideCGSize:CGSize) -> CGFloat{
        if self.progressBarAxes == .horizontal ||
            self.progressBarAxes == .leading ||
            self.progressBarAxes == .trailing {
            if self.isShowProgressBar  {
                return self.thresholdValue
            }
            let value:CGFloat
            if self.axes == .horizontal {
                if self.afterValue > 0 {
                    let v = getHorizontalDifferenceValue(outsideCGSize)
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
                    let v = self.getVerticalDifferenceValue(outsideCGSize)
                    if v > 0 {
                        value = 0
                    }else{
                        value = self.enableAppend ? abs(v) : 0
                    }
                }else{
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }
            return value
        }else{
            return outsideCGSize.width
        }
    }
    
    private func getProgressBarHeight(_ outsideCGSize:CGSize) -> CGFloat{
        if self.progressBarAxes == .horizontal ||
            self.progressBarAxes == .leading ||
            self.progressBarAxes == .trailing {
            return outsideCGSize.height
        } else {
            if self.isShowProgressBar  {
                return self.thresholdValue
            }
            let value:CGFloat
            if self.axes == .horizontal {
                if self.afterValue >= 0 {
                    let v = getHorizontalDifferenceValue(outsideCGSize)
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
                    let v = self.getVerticalDifferenceValue(outsideCGSize)
                    if  v < 0 {
                        value = self.enableAppend ? abs(v) : 0
                    }else {
                        value = 0
                    }
                }else {
                    value = self.enableRefresh ? abs(self.afterValue) : 0
                }
            }
            return value
        }
    }
    
    private func getVerticalDifferenceValue(_ outsideCGSize:CGSize) -> CGFloat{
        if self.insideHeight < outsideCGSize.height {
            return self.afterValue
        }
        return self.insideHeight - outsideCGSize.height - self.afterValue
    }
    
    private func getHorizontalDifferenceValue(_ outsideCGSize:CGSize) -> CGFloat{
        if self.insideWidth < outsideCGSize.width {
            return self.afterValue
        }
        return self.insideWidth - outsideCGSize.width - self.afterValue
    }
}
