//
//  ViewController.swift
//  MCalendarKit
//
//  Created by Ridvan Kucuk on 08/01/2016.
//  Copyright (c) 2016 Ridvan Kucuk. All rights reserved.
//

import UIKit
import MCalendarKit
import EventKit

class ViewController: UIViewController, CalendarViewDataSource, CalendarViewDelegate {
    
    var viewCalendar: MCalendarView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var params = [Parameters : AnyObject]()
        params[.CalendarBackgroundColor] = UIColor.brownColor()
        params[.AllowMultipleSelection] = true
        params[.SelectedCellBackgroundColor] = UIColor.cyanColor()
        params[.DeselectedCellBackgroundColor] = UIColor.lightGrayColor()
        params[.TodayDeSelectedBackgroundColor] = UIColor.redColor()
        params[.Circular] = false
        
        viewCalendar = MCalendarView()
        viewCalendar?.direction = .Horizontal
        viewCalendar?.parameters = params
        viewCalendar?.translatesAutoresizingMaskIntoConstraints = false
        viewCalendar?.delegate = self
        viewCalendar?.dataSource = self
        view.addSubview(self.viewCalendar!)
        
        
        let views = ["view_calendar" : viewCalendar!]
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view_calendar]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view_calendar(300)]", options: [], metrics: nil, views: views))
        
        let dateComponents = NSDateComponents()
        dateComponents.day = 0
        
        let today = NSDate()
        
        if let date = self.viewCalendar!.calendar.dateByAddingComponents(dateComponents, toDate: today, options: NSCalendarOptions()) {
            self.viewCalendar?.selectDate(date)
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        let width = view.frame.size.width - 16.0 * 2
        let height = width + 30.0
        viewCalendar?.frame = CGRect(x: 16.0, y: 32.0, width: width, height: height)
        
        
    }
    
    //MARK: RKCalendarViewDataSource
    func startDate() -> NSDate? {
        return NSDate()
    }
    
    func endDate() -> NSDate? {
        
        let dateComponents = NSDateComponents()
        
        dateComponents.year = 2;
        let today = NSDate()
        
        let twoYearsFromNow = self.viewCalendar!.calendar.dateByAddingComponents(dateComponents, toDate: today, options: NSCalendarOptions())
        
        return twoYearsFromNow
    }
    
    //MARK: RKCalendarViewDelegate
    func calendar(calendar: MCalendarView, didSelectDate date: NSDate, withEvents events: [EKEvent]) {
        print(date)
    }
    
    func calendar(calendar: MCalendarView, didScrollToMonth date: NSDate) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

