//
//  HSKLineNew.swift
//  HSStockChartDemo
//
//  Created by Hanson on 2017/2/16.
//  Copyright © 2017年 hanson. All rights reserved.
//

import UIKit

public enum Element {
    case axis
    case overlay
}

public enum ChartType {
    case timeLine
    case candlesticks
}

public struct Bounds {
    public var min: CGFloat
    public var max: CGFloat
    
    var difference: CGFloat {
        return max - min
    }
    
    public init(min: CGFloat, max: CGFloat) {
        self.min = min
        self.max = max
    }
}

public struct GraphBounds {
    public var price: Bounds
    public var volume: Bounds
    public var range: CountableClosedRange<Int>
    
    public init(price: Bounds, volume: Bounds, range: CountableClosedRange<Int>) {
        self.price = price
        self.volume = volume
        self.range = range
    }
    
    public init() {
        self.init(price: Bounds(min: 0, max: 0), volume: Bounds(min: 0, max: 0), range: 0...0)
    }
}

struct Candle {
    public var open: CGFloat = 0
    public var close: CGFloat = 0
    public var high: CGFloat = 0
    public var low: CGFloat = 0
    
    var isRising: Bool {
        return close >= open
    }
}

protocol CandlesticksViewDataSource {
    func numberOfCandles() -> Int
    func numberOfLines() -> Int
    func candle(atIndex index: Int) -> Candle
    func label(atIndex index: Int) -> String
    func volume(atIndex index: Int) -> CGFloat
    func values(forLineAtIndex lineIndex: Int) -> [CGFloat]
    func color(forLineAtIndex lineIndex: Int) -> CGColor
}

class CandlesticsView: UIView, DrawLayer {
    
    private var kLineViewTotalWidth: CGFloat = 0
    private var showContentWidth: CGFloat = 0
    private var selectedIndex: Int = 0
    
    // Layers
    private var candleChartLayer = CAShapeLayer()
    private var volumeLayer = CAShapeLayer()
    private var linesLayer = CAShapeLayer()
    
    private var candlesChartHeight: CGFloat {
        return theme.upperChartHeightScale * self.frame.height
    }
    
    private var volumesChartHeight: CGFloat {
        return self.frame.height * (1 - theme.upperChartHeightScale) - theme.xAxisHeight
    }
    
    var priceUnit: CGFloat {
        return (candlesChartHeight - 2 * theme.viewMinYGap) / graphBounds.price.difference
    }
    
    var volumeUnit: CGFloat {
        return (volumesChartHeight - theme.volumeGap) / graphBounds.volume.max
    }
    
    var theme = ChartTheme()
    var dataSource: CandlesticksViewDataSource?
    var visibleRange: CountableClosedRange<Int> = 0...0
    var graphBounds = GraphBounds()
    
    // MARK: - Initialize
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing Function
    
    func reloadData() {
        clearLayer()
        drawCandleChartLayer()
        drawVolumeLayer()
        drawLinesLayer()
    }
    
    func drawCandleChartLayer() {
        guard let dataSource = self.dataSource else { return }
        candleChartLayer.sublayers?.removeAll()
        
        for index in visibleRange {
            let coordinate = candleCoordinate(atIndex: index, for: dataSource)
            let candleLayer = getCandleLayer(coordinate: coordinate)
            candleChartLayer.addSublayer(candleLayer)
        }
        
        self.layer.addSublayer(candleChartLayer)
    }
    
    private func drawVolumeLayer() {
        guard let dataSource = self.dataSource else { return }
        volumeLayer.sublayers?.removeAll()
        
        for index in visibleRange {
            let coordinates = self.volumeCoordinate(atIndex: index, for: dataSource)
            let volLayer = drawLine(lineWidth: theme.candleWidth, startPoint: coordinates.highPoint, endPoint: coordinates.lowPoint, strokeColor: coordinates.fillColor, fillColor: coordinates.fillColor)
            volumeLayer.addSublayer(volLayer)
        }
        
        self.layer.addSublayer(volumeLayer)
    }
    
    private func drawLinesLayer() {
        guard let dataSource = self.dataSource else { return }
        linesLayer.sublayers?.removeAll()
        
        let numberOfLines = dataSource.numberOfLines()
        
        for lineIndex in 0..<numberOfLines {
            guard let coordinates = lineCoordinates(forLineIndex: lineIndex, for: dataSource) else { break }
            let lineLayer = createLineLayer(for: coordinates.points, color: coordinates.color)
            linesLayer.addSublayer(lineLayer)
        }
        
        self.layer.addSublayer(linesLayer)
    }
    
    private func createLineLayer(for coordinates: [CGPoint], color: CGColor) -> CAShapeLayer {
        let linePath = UIBezierPath()
        
        for index in 1 ..< coordinates.count {
            let previousPoint = coordinates[index - 1]
            let point = coordinates[index]
            linePath.move(to: previousPoint)
            linePath.addLine(to: point)
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = color
        lineLayer.fillColor = UIColor.clear.cgColor
        return lineLayer
    }
    
    private func clearLayer() {
        candleChartLayer.sublayers?.removeAll()
        candleChartLayer.removeFromSuperlayer()
        volumeLayer.sublayers?.removeAll()
        volumeLayer.removeFromSuperlayer()
        linesLayer.sublayers?.removeAll()
        linesLayer.removeFromSuperlayer()
    }
    
    private func getCandleLayer(coordinate: CandleCoordinate) -> CAShapeLayer {
        let linePath = UIBezierPath(rect: coordinate.frame)
        linePath.move(to: coordinate.lowPoint)
        linePath.addLine(to: coordinate.highPoint)
        
        let klayer = CAShapeLayer()
        klayer.path = linePath.cgPath
        klayer.strokeColor = coordinate.fillColor
        klayer.fillColor = coordinate.fillColor
        
        return klayer
    }
    
    func lineCoordinates(forLineIndex lineIndex: Int, for dataSource: CandlesticksViewDataSource) -> LineCoordinates? {
        // Create lines
        let values = dataSource.values(forLineAtIndex: lineIndex)
        let color = dataSource.color(forLineAtIndex: lineIndex)
        
        guard values.count > 0 else { return nil }
        let visibleRange = self.visibleRange
        let startIndex = visibleRange.lowerBound
        let endIndex = max(startIndex, min((values.count - 1), visibleRange.upperBound))
        var lineCoordinates = LineCoordinates(points: [], color: color)
        let gap = theme.viewMinYGap
        let bounds = self.graphBounds
        
        for index in startIndex...endIndex {
            let value = values[index]
            let lineXPosition = self.lineXPosition(forIndex: index)
            let point = CGPoint(x: lineXPosition, y: (bounds.price.max - value) * priceUnit + gap)
            lineCoordinates.points.append(point)
        }
        
        return lineCoordinates
    }
    
    func candleCoordinate(atIndex index: Int, for dataSource: CandlesticksViewDataSource) -> CandleCoordinate {
        // Get some data
        let bounds = self.graphBounds
        let candle = dataSource.candle(atIndex: index)
        let gap = theme.viewMinYGap
        let candleXPosition = self.candleXPosition(forIndex: index)
        let lineXPosition = self.lineXPosition(forIndex: index)
        
        // Price
        let highPoint = CGPoint(x: lineXPosition, y: (bounds.price.max - candle.high) * priceUnit + gap)
        let lowPoint = CGPoint(x: lineXPosition, y: (bounds.price.max - candle.low) * priceUnit + gap)
        let openPoint = CGPoint(x: lineXPosition, y: (bounds.price.max - candle.open) * priceUnit + gap)
        let closePoint = CGPoint(x: lineXPosition, y: (bounds.price.max - candle.close) * priceUnit + gap)
        
        let height = max(abs(openPoint.y - closePoint.y), theme.candleMinHeight)
        let candleRect = CGRect(x: candleXPosition, y: min(closePoint.y, openPoint.y), width: theme.candleWidth, height: height)
        
        // Create the model
        var candleCoordinate = CandleCoordinate()
        candleCoordinate.closePoint = closePoint
        candleCoordinate.openPoint = openPoint
        candleCoordinate.highPoint = highPoint
        candleCoordinate.lowPoint = lowPoint
        candleCoordinate.frame = candleRect
        candleCoordinate.isDrawAxis = false
        
        if candle.isRising {
            candleCoordinate.fillColor = theme.riseColor.cgColor
        } else {
            candleCoordinate.fillColor = theme.fallColor.cgColor
        }
        
        return candleCoordinate
    }
    
    func volumeCoordinate(atIndex index: Int, for dataSource: CandlesticksViewDataSource) -> VolumeCoordinate {
        // Get some data
        let volume = dataSource.volume(atIndex: index)
        let candle = dataSource.candle(atIndex: index)
        let lineXPosition = self.lineXPosition(forIndex: index)
        
        // Volume
        let units = volume * volumeUnit
        let highPoint = CGPoint(x: lineXPosition, y: self.frame.height - units)
        let lowPoint = CGPoint(x: lineXPosition, y: self.frame.height)
        
        // Create the model
        var volumeCoordinate = VolumeCoordinate()
        volumeCoordinate.highPoint = highPoint
        volumeCoordinate.lowPoint = lowPoint
        
        if candle.isRising {
            volumeCoordinate.fillColor = theme.riseColor.cgColor
        } else {
            volumeCoordinate.fillColor = theme.fallColor.cgColor
        }
        
        return volumeCoordinate
    }
    
    func candleXPosition(forIndex index: Int) -> CGFloat {
        return CGFloat(index) * (theme.candleWidth + theme.candleGap)
    }
    
    func lineXPosition(forIndex index: Int) -> CGFloat {
        let leftPosition = candleXPosition(forIndex: index)
        return leftPosition + theme.candleWidth / 2.0
    }
}