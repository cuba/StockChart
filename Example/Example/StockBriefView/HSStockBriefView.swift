//
//  HSStockBriefView.swift
//  StockChartExample
//
//  Created by Hanson on 16/9/7.
//  Copyright © 2016年 hanson. All rights reserved.
//

import UIKit
import StockChart

class HSStockBriefView: UIView {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var ratioLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    
    weak var view: UIView!
    
    override func layoutSubviews() {
        view.frame = bounds
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    func setupSubviews() {
        view = instanceViewFromNib()
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
    }
    
    func instanceViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
//    func configureView(_ timeLineEntity: HSTimeLineModel) {
//        
//        var labelColor: UIColor
//        if timeLineEntity.rate < 0 {
//            labelColor = UIColor(hexString: "#1DBF60")!
//        } else if timeLineEntity.rate > 0 {
//            labelColor = UIColor.red
//        } else {
//            labelColor = UIColor.gray
//        }
//        priceLabel.labelColor = labelColor
//        ratioLabel.labelColor = labelColor
//        
//        priceLabel.text = timeLineEntity.price.toString(withFormat: ".8")
//        ratioLabel.text = (timeLineEntity.rate * 100).toPercentString(withFormat: ".2")
//        timeLabel.text = timeLineEntity.time.toString(withFormat: "HH:mm")
//        volumeLabel.text = timeLineEntity.volume.toString(withFormat: ".2")
//    }

}
