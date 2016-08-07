//
//  MCalendarDayCell.swift
//  Pods
//
//  Created by Ridvan Kucuk on 5/25/16.
//
//
import UIKit

struct DayCellData {
    var today: Bool
    var selected: Bool
    var eventCount: Int
    var dayNumber: String
    var shouldHideCell:Bool
    var todayColor: UIColor
    var cornerRadius: CGFloat

    init(dayNumber:String = "",
         eventCount:Int = 0,
         selected:Bool = false,
         today:Bool = false,
         shouldHideCell:Bool = false,
         todayColor: UIColor = .greenColor(),
         cornerRadius: CGFloat = 0.0) {
        self.today = today
        self.selected = selected
        self.eventCount = eventCount
        self.dayNumber = dayNumber
        self.todayColor = todayColor
        self.shouldHideCell = shouldHideCell
        self.cornerRadius = cornerRadius
    }
}

class MCalendarDayCell: UICollectionViewCell {

    private var cellData: DayCellData!
    private enum CellConstants {
        static let borderColor = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.8)
    }
    var eventsCount = 0 {
        didSet {
            for sview in self.dotsView.subviews {
                sview.removeFromSuperview()
            }

            let stride = self.dotsView.frame.size.width / CGFloat(eventsCount+1)
            let viewHeight = self.dotsView.frame.size.height
            let halfViewHeight = viewHeight / 2.0

            for _ in 0..<eventsCount {
                let frm = CGRect(x: (stride+1.0) - halfViewHeight, y: 0.0, width: viewHeight, height: viewHeight)
                let circle = UIView(frame: frm)
                circle.layer.cornerRadius = halfViewHeight
                circle.backgroundColor = CellConstants.borderColor
                self.dotsView.addSubview(circle)
            }
        }
    }
    func setCellData(data:DayCellData) {
        cellData = data
        if data.selected {
            self.backgroundView?.backgroundColor = UIColor.redColor()
        } else {
            if data.today {
                self.backgroundView?.backgroundColor = data.todayColor
            } else {
                self.backgroundView?.backgroundColor = UIColor.blueColor()
            }
        }
        self.hidden = data.shouldHideCell
        textLabel.text = data.dayNumber
        eventsCount = data.eventCount
        self.layer.cornerRadius = data.cornerRadius
    }

    override var selected: Bool {

        didSet {
            if let data = self.cellData {
                self.cellData?.selected = selected
                if selected {
                    self.backgroundView?.backgroundColor = UIColor.redColor()
                }
                else {
                    if self.cellData!.today {
                        self.backgroundView?.backgroundColor = self.cellData?.todayColor
                    } else {
                        self.backgroundView?.backgroundColor = UIColor.blueColor()
                    }
                }
            }
        }
    }

    lazy var textLabel : UILabel = {

        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = .darkGrayColor()

        return label

    }()

    lazy var dotsView : UIView = {

        let frame = CGRect(x: 8.0, y: self.frame.size.width - 10.0 - 4.0, width: self.frame.size.width - 16.0, height: 8.0)
        let dv = UIView(frame: frame)

        return dv

    }()

    override init(frame: CGRect) {

        super.init(frame: frame)

        self.backgroundView = UIView(frame:self.frame)
        self.cellData = DayCellData()
        
        self.textLabel.frame = self.bounds
        self.addSubview(self.textLabel)

        self.addSubview(dotsView)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
