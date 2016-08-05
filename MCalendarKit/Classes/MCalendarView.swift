//
//  MCalendarView.swift
//  Pods
//
//  Created by Ridvan Kucuk on 5/25/16.
//
//

import UIKit
import EventKit

extension EKEvent {

    var isOneDay : Bool {
        let components = NSCalendar.currentCalendar().components([.Era, .Year, .Month, .Day], fromDate: self.startDate, toDate: self.endDate, options: NSCalendarOptions())
        return (components.era == 0 && components.year == 0 && components.month == 0 && components.day == 0)
    }
}

@objc public protocol CalendarViewDataSource {

    func startDate() -> NSDate?
    func endDate() -> NSDate?
}

@objc public protocol CalendarViewDelegate {

    func calendar(calendar : MCalendarView, didScrollToMonth date : NSDate)
    func calendar(calendar : MCalendarView, didSelectDate date : NSDate, withEvents events: [EKEvent])
    optional func calendar(calendar : MCalendarView, canSelectDate date : NSDate) -> Bool
    optional func calendar(calendar : MCalendarView, didDeselectDate date : NSDate)
}

public enum Parameters: String {
    
    case CalendarBackgroundColor = "backgroundColor"
    case SelectedCellBackgroundColor = "selectedCellBackgroundColor"
    case DeselectedCellBackgroundColor = "deselectedCellBackgroundColor"
    case AllowMultipleSelection = "allowMultipleSelection"
    case TodayDeSelectedBackgroundColor = "todayDeselectedBackgroundColor"
    case None = "none"
    
    static let values = [CalendarBackgroundColor, SelectedCellBackgroundColor, DeselectedCellBackgroundColor, AllowMultipleSelection, None]
    
    public static func get(status:String) -> Parameters {
        
        for value in Parameters.values {
            if status == value.rawValue {
                return value
            }
        }
        return Parameters.None
    }
}

public class MCalendarView: UIView {

    public var dataSource: CalendarViewDataSource?
    public var delegate: CalendarViewDelegate?
    
    lazy var gregorian: NSCalendar = {
        
        let cal = NSCalendar(identifier: NSCalendarIdentifierGregorian)!
        
        cal.timeZone = NSTimeZone(abbreviation: "UTC")!
        
        return cal
    }()
    
    public var calendar: NSCalendar {
        return gregorian
    }
    
    public var direction: UICollectionViewScrollDirection = .Horizontal {
        didSet {
            if let layout = calendarView.collectionViewLayout as? MCalendarFlowLayout {
                layout.scrollDirection = direction

                calendarView.reloadData()
            }
        }
    }

    public var parameters = [Parameters : AnyObject]() {
        didSet{
            reloadParameters()
        }
    }

    var displayDate: NSDate?
    var monthInfo = [Int:[Int]]()

    lazy var headerView: MCalendarHeaderView = {

        let hv = MCalendarHeaderView(frame:CGRectZero)

        return hv

    }()

    lazy var calendarView: UICollectionView = {

        let layout = MCalendarFlowLayout()
        layout.scrollDirection = self.direction
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        let cv = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.pagingEnabled = true

        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.allowsMultipleSelection = true

        return cv

    }()

    private enum CalendarViewConstants {
        static let cellReuseIdentifier = "CalendarDayCell"
        static let numberOfDaysInWeek = 7
        static let maximumNumberOfRows = 6
        static let headerDefaultHeight: CGFloat = 80.0
        static let firstDayIndex = 0
        static let numberOfDaysIndex = 1
        static let selectedDateIndex = 2
    }
    
    private var startDateCache = NSDate()
    private var endDateCache = NSDate()
    private var startOfMonthCache = NSDate()
    private var todayIndexPath: NSIndexPath?
    private(set) var selectedIndexPaths = [NSIndexPath]()
    private(set) var selectedDates = [NSDate]()
    
    private var eventsByIndexPath = [NSIndexPath:[EKEvent]]()
    private var dateBeingSelectedByUser : NSDate?

    private var deselectedCellBackgroundColor: UIColor? // Default cell background Color
    private var selectedCellBackgroundColor: UIColor? // Selected cell background Color
    private var todayDeselectedBackgroundColor: UIColor?
    
    override public var frame: CGRect {
        didSet {
            let heigh = frame.size.height - CalendarViewConstants.headerDefaultHeight
            let width = frame.size.width
            
            headerView.frame   = CGRect(x:0.0, y:0.0, width: frame.size.width, height:CalendarViewConstants.headerDefaultHeight)
            calendarView.frame = CGRect(x:0.0, y:CalendarViewConstants.headerDefaultHeight, width: width, height: heigh)
            
            if let layout = calendarView.collectionViewLayout as? MCalendarFlowLayout {
                layout.itemSize = CGSizeMake(width / CGFloat(CalendarViewConstants.numberOfDaysInWeek), heigh / CGFloat(CalendarViewConstants.maximumNumberOfRows))
            }
        }
    }

    // Mark: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: CGRectMake(0.0, 0.0, 200.0, 200.0))
        initialSetup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        initialSetup()
    }

    public func selectDate(date : NSDate) {

        guard let indexPath = indexPathForDate(date) else {
            return
        }

        guard calendarView.indexPathsForSelectedItems()?.contains(indexPath) == false else {
            return
        }

        calendarView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)

        selectedIndexPaths.append(indexPath)
        selectedDates.append(date)

    }

    func deselectDate(date : NSDate) {

        guard let indexPath = indexPathForDate(date) else {
            return
        }

        guard calendarView.indexPathsForSelectedItems()?.contains(indexPath) == true else {
            return
        }

        calendarView.deselectItemAtIndexPath(indexPath, animated: false)

        guard let index = selectedIndexPaths.indexOf(indexPath) else {
            return
        }


        selectedIndexPaths.removeAtIndex(index)
        selectedDates.removeAtIndex(index)
    }

    func indexPathForDate(date : NSDate) -> NSIndexPath? {

        let distanceFromStartComponent = gregorian.components( [.Month, .Day], fromDate:startOfMonthCache, toDate: date, options: NSCalendarOptions() )

        guard let currentMonthInfo : [Int] = monthInfo[distanceFromStartComponent.month] else {
            return nil
        }


        let item = distanceFromStartComponent.day + currentMonthInfo[CalendarViewConstants.firstDayIndex]
        let indexPath = NSIndexPath(forItem: item, inSection: distanceFromStartComponent.month)

        return indexPath

    }

    func reloadData() {
        calendarView.reloadData()
    }

    func setDisplayDate(date : NSDate, animated: Bool) {

        if let dispDate = displayDate {

            // skip is we are trying to set the same date
            if  date.compare(dispDate) == NSComparisonResult.OrderedSame {
                return
            }


            // check if the date is within range
            if  date.compare(startDateCache) == NSComparisonResult.OrderedAscending ||
                date.compare(endDateCache) == NSComparisonResult.OrderedDescending   {
                return
            }


            let difference = gregorian.components([NSCalendarUnit.Month], fromDate: startOfMonthCache, toDate: date, options: NSCalendarOptions())
            
            let distance : CGFloat = CGFloat(difference.month) * calendarView.frame.size.width
            
            calendarView.setContentOffset(CGPoint(x: distance, y: 0.0), animated: animated)
        }
    }
    
    // Mark: Private
    
    private func initialSetup() {
        self.clipsToBounds = true
        
        // Register Class
        calendarView.registerClass(MCalendarDayCell.self, forCellWithReuseIdentifier: CalendarViewConstants.cellReuseIdentifier)

        self.addSubview(headerView)
        self.addSubview(calendarView)
    }
    
    private func reloadParameters(){
        
        guard let layout = calendarView.collectionViewLayout as? MCalendarFlowLayout else {
            return
        }
        if let backgroundColor = parameters[.CalendarBackgroundColor] as? UIColor{
            calendarView.backgroundColor = backgroundColor
        }
        
        if let multipleSelection = parameters[.AllowMultipleSelection] as? Bool{
            self.calendarView.allowsMultipleSelection = multipleSelection
        }
        
        if let cellBGColor = parameters[.SelectedCellBackgroundColor] as? UIColor{
            self.selectedCellBackgroundColor = cellBGColor
        }
        
        if let deselectedCellBGColor = parameters[.DeselectedCellBackgroundColor] as? UIColor{
            self.deselectedCellBackgroundColor = deselectedCellBGColor
        }
        
        if let todayDeselectedBGColor = parameters[.TodayDeSelectedBackgroundColor] as? UIColor{
            
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.calendarView.reloadData()
        }
    }
}

extension MCalendarView: UICollectionViewDataSource {
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {

        guard let startDate = dataSource?.startDate(), endDate = dataSource?.endDate() else {
            return 0
        }

        startDateCache = startDate
        endDateCache = endDate

        // check if the dates are in correct order
        if gregorian.compareDate(startDate, toDate: endDate, toUnitGranularity: .Nanosecond) != NSComparisonResult.OrderedAscending {
            return 0
        }


        let firstDayOfStartMonth = gregorian.components( [.Era, .Year, .Month], fromDate: startDateCache)
        firstDayOfStartMonth.day = 1

        guard let dateFromDayOneComponents = gregorian.dateFromComponents(firstDayOfStartMonth) else {
            return 0
        }

        startOfMonthCache = dateFromDayOneComponents


        let today = NSDate()

        if  startOfMonthCache.compare(today) == NSComparisonResult.OrderedAscending &&
            endDateCache.compare(today) == NSComparisonResult.OrderedDescending {

            let differenceFromTodayComponents = gregorian.components([NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: startOfMonthCache, toDate: today, options: NSCalendarOptions())

            todayIndexPath = NSIndexPath(forItem: differenceFromTodayComponents.day, inSection: differenceFromTodayComponents.month)

        }

        let differenceComponents = gregorian.components(NSCalendarUnit.Month, fromDate: startDateCache, toDate: endDateCache, options: NSCalendarOptions())

        return differenceComponents.month + 1

    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        let monthOffsetComponents = NSDateComponents()

        // offset by the number of months
        monthOffsetComponents.month = section;

        guard let correctMonthForSectionDate = gregorian.dateByAddingComponents(monthOffsetComponents, toDate: startOfMonthCache, options: NSCalendarOptions()) else {
            return 0
        }

        let numberOfDaysInMonth = gregorian.rangeOfUnit(.Day, inUnit: .Month, forDate: correctMonthForSectionDate).length

        var firstWeekdayOfMonthIndex = gregorian.component(NSCalendarUnit.Weekday, fromDate: correctMonthForSectionDate)
        firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default

        monthInfo[section] = [firstWeekdayOfMonthIndex, numberOfDaysInMonth]

        return CalendarViewConstants.numberOfDaysInWeek * CalendarViewConstants.maximumNumberOfRows // 7 x 6 = 42
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let dayCell = collectionView.dequeueReusableCellWithReuseIdentifier(CalendarViewConstants.cellReuseIdentifier, forIndexPath: indexPath) as! MCalendarDayCell

        let currentMonthInfo : [Int] = monthInfo[indexPath.section]! // we are guaranteed an array by the fact that we reached this line (so unwrap)

        let fdIndex = currentMonthInfo[CalendarViewConstants.firstDayIndex]
        let nDays = currentMonthInfo[CalendarViewConstants.numberOfDaysIndex]

        let fromStartOfMonthIndexPath = NSIndexPath(forItem: indexPath.item - fdIndex, inSection: indexPath.section) // if the first is wednesday, add 2
        var cellData = DayCellData()
        if indexPath.item >= fdIndex &&
            indexPath.item < fdIndex + nDays {
            cellData.dayNumber = String(fromStartOfMonthIndexPath.item + 1)
            cellData.shouldHideCell = false

        }
        else {
            cellData.shouldHideCell = true
        }

        let isSelected = selectedIndexPaths.contains(indexPath)
        cellData.selected = isSelected
        if indexPath.section == 0 && indexPath.item == 0 {
            scrollViewDidEndDecelerating(collectionView)
        }

        if let idx = todayIndexPath {
            cellData.today = (idx.section == indexPath.section && idx.item + fdIndex == indexPath.item)
        }

        cellData.todayColor = UIColor.greenColor()
        if let eventsForDay = eventsByIndexPath[fromStartOfMonthIndexPath] {
            cellData.eventCount = eventsForDay.count

        } else {
            cellData.eventCount = 0
        }

        dayCell.setCellData(cellData)

        //        if let selectedCellBackgroundColor = self.selectedCellBackgroundColor {
        //            dayCell.selectedBackgroundColor = selectedCellBackgroundColor
        //        }
        //        if let deselectedCellBackgroundColor = self.deselectedCellBackgroundColor {
        //            dayCell.deselectedBackgroundColor = deselectedCellBackgroundColor
        //        }
        //        if let todayDeselectedBackgroundColor = self.todayDeselectedBackgroundColor {
        //            dayCell.todayDeselectedBackgroundColor = todayDeselectedBackgroundColor
        //        }
        
        return dayCell
    }
}

extension MCalendarView: UICollectionViewDelegate {

    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {

        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!
        let firstDayInMonth = currentMonthInfo[CalendarViewConstants.firstDayIndex]

        let offsetComponents = NSDateComponents()
        offsetComponents.month = indexPath.section
        offsetComponents.day = indexPath.item - firstDayInMonth

        if let dateUserSelected = gregorian.dateByAddingComponents(offsetComponents, toDate: startOfMonthCache, options: NSCalendarOptions()) {

            dateBeingSelectedByUser = dateUserSelected

            // Optional protocol method (the delegate can "object")
            if let canSelectFromDelegate = delegate?.calendar?(self, canSelectDate: dateUserSelected) {
                return canSelectFromDelegate
            }

            return true // it can select any date by default
        }

        return false // if date is out of scope
    }

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard let dateBeingSelectedByUser = dateBeingSelectedByUser else {
            return
        }

        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!

        let fromStartOfMonthIndexPath = NSIndexPath(forItem: indexPath.item - currentMonthInfo[CalendarViewConstants.firstDayIndex], inSection: indexPath.section)

        var eventsArray : [EKEvent] = [EKEvent]()

        if let eventsForDay = eventsByIndexPath[fromStartOfMonthIndexPath] {
            eventsArray = eventsForDay;
        }

        delegate?.calendar(self, didSelectDate: dateBeingSelectedByUser, withEvents: eventsArray)

        // Update model
        selectedIndexPaths.append(indexPath)
        selectedDates.append(dateBeingSelectedByUser)
    }

    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        guard let dateBeingSelectedByUser = dateBeingSelectedByUser else {
            return
        }

        guard let index = selectedIndexPaths.indexOf(indexPath) else {
            return
        }

        delegate?.calendar?(self, didDeselectDate: dateBeingSelectedByUser)

        selectedIndexPaths.removeAtIndex(index)
        selectedDates.removeAtIndex(index)
    }
}

extension MCalendarView: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        calculateDateBasedOnScrollViewPosition(scrollView)
    }

    private func calculateDateBasedOnScrollViewPosition(scrollView: UIScrollView) {

        let cvbounds = calendarView.bounds

        var page : Int = Int(floor(calendarView.contentOffset.x / cvbounds.size.width))

        page = page > 0 ? page : 0

        let monthsOffsetComponents = NSDateComponents()
        monthsOffsetComponents.month = page

        guard let delegate = delegate else {
            return
        }

        guard let yearDate = gregorian.dateByAddingComponents(monthsOffsetComponents, toDate: startOfMonthCache, options: NSCalendarOptions()) else {
            return
        }

        let month = gregorian.component(NSCalendarUnit.Month, fromDate: yearDate) // get month

        let monthName = NSDateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array

        let year = gregorian.component(NSCalendarUnit.Year, fromDate: yearDate)

        headerView.monthLabel.text = monthName + " " + String(year)

        displayDate = yearDate

        delegate.calendar(self, didScrollToMonth: yearDate)
    }
}
