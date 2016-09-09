//
//  TimeLineDataSet.swift
//  MyStockChartDemo
//
//  Created by Hanson on 16/8/16.
//  Copyright © 2016年 hanson. All rights reserved.
//

import UIKit

//包含画图需要的数据以及样式

class TimeLineDataSet {
    
    var days : [String]?  //五日图的日期
    var data : [TimeLineEntity]?
    var highlightLineWidth : CGFloat = 0
    var highlightLineColor = UIColor.blueColor()
    var lineWidth : CGFloat = 1
    var priceLineCorlor = UIColor(rgba: "#0095ff")
    var avgLineCorlor = UIColor.yellowColor()
    var volumeRiseColor = UIColor.redColor()
    var volumeFallColor = UIColor.greenColor()
    var volumeTieColor = UIColor.grayColor()
    var drawFilledEnabled = false
    var fillStartColor = UIColor.orangeColor()
    var fillStopColor = UIColor.blackColor()
    var fillAlpha:CGFloat = 0.5
}

