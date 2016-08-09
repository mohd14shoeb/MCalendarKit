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
    var circular: Bool

    init(dayNumber:String = "",
         eventCount:Int = 0,
         selected:Bool = false,
         today:Bool = false,
         shouldHideCell:Bool = false,
         todayColor:UIColor = .greenColor(),
         cornerRadius:CGFloat = 0.0,
         circular:Bool = false) {
        
        self.today = today
        self.selected = selected
        self.eventCount = eventCount
        self.dayNumber = dayNumber
        self.todayColor = todayColor
        self.shouldHideCell = shouldHideCell
        self.cornerRadius = cornerRadius
        self.circular = circular
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
            pBackgroundView.backgroundColor = UIColor.redColor()
        } else {
            if data.today {
                pBackgroundView.backgroundColor = data.todayColor
            } else {
                pBackgroundView.backgroundColor = UIColor.blueColor()
            }
        }
        self.hidden = data.shouldHideCell
        textLabel.text = data.dayNumber
        eventsCount = data.eventCount
        if data.cornerRadius > 0 {
            self.layer.cornerRadius = data.cornerRadius
        }
        else if data.circular {
            pBackgroundView.layer.cornerRadius = self.contentView.frame.size.height / 2
        }
    }

    override var selected: Bool {

        didSet {
            if self.cellData != nil {
                self.cellData?.selected = selected
                if selected {
                    pBackgroundView.backgroundColor = UIColor.redColor()
                }
                else {
                    if self.cellData!.today {
                        pBackgroundView.backgroundColor = self.cellData?.todayColor
                    } else {
                        pBackgroundView.backgroundColor = UIColor.blueColor()
                    }
                }
            }
        }
    }

    lazy var textLabel : UILabel = {

        let label = UILabel()
        label.textAlignment = .Center
        label.textColor = .whiteColor()

        return label

    }()

    lazy var dotsView : UIView = {

        let frame = CGRect(x: 8.0, y: self.frame.size.width - 10.0 - 4.0, width: self.frame.size.width - 16.0, height: 8.0)
        let dv = UIView(frame: frame)

        return dv

    }()
    
    lazy var pBackgroundView : UIView = {
        
        var vFrame = CGRectInset(self.frame, 1.0, 1.0)
        
        let view = UIView(frame: vFrame)
        
        view.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        
        return view
    }()
    
    override init(frame: CGRect) {

        super.init(frame: frame)

        self.backgroundView = UIView(frame: CGRectInset(self.frame, 3.0, 3.0))
        self.cellData = DayCellData()
        
        self.addSubview(self.pBackgroundView)
        
        self.textLabel.frame = self.bounds
        self.addSubview(self.textLabel)
        self.addSubview(dotsView)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
