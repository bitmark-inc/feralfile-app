//
//  Daily_Widget.swift
//  Daily Widget
//
//  Created by Nguyen Phuoc Sang on 6/12/24.
//

import WidgetKit
import SwiftUI
import Foundation
import os

private let widgetGroupId = "group.com.bitmark.autonomywallet.storage"

// Constant for the 5-minute update interval
private let updateInterval: TimeInterval = 300

let logger = Logger(subsystem: "Feral File", category: "daily widget")


// Provider that handles fetching and providing data for the widget
struct Provider: TimelineProvider {
    
    // Placeholder for widget, shown when the data is loading
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dailyInfoList: [])
    }

    // Snapshot function for the widget, provides data to be shown immediately
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Fetch the stored daily info (this could be artwork data)
        let dailyInfoList = fetchStoredDailyInfo()
        // Create a timeline entry with the current date and fetched data
        let entry = SimpleEntry(date: Date(), dailyInfoList: dailyInfoList)
        // Return the entry to be shown immediately
        completion(entry)
    }

    // Get the timeline for the widget, determines the update schedule
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate the snapshot entry first
        getSnapshot(in: context) { (entry) in
            // Get the current date and schedule the next update after 5 minutes
            let currentDate = Date()
            let timeline = Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(updateInterval)))
            // Return the timeline to the widget system
            completion(timeline)
        }
    }

    // Fetch the stored daily artwork info from UserDefaults
    private func fetchStoredDailyInfo() -> [DailyInfo] {
        logger.info("fetchStoredDailyInfo starting")
        guard let widgetData = UserDefaults(suiteName: widgetGroupId) else {
            logger.info("fetchStoredDailyInfo: unable to retrieve UserDefaults")
            return []
        }
        
        let currentDateKey = formattedDateKey(for: Date())
        
        // Retrieve the JSON string associated with the current date
        if let jsonString = widgetData.string(forKey: currentDateKey) {
            logger.info("fetchStoredDailyInfo: retrieved JSON string for \(currentDateKey)")
            return parseDailyInfo(from: jsonString)
        }
        
        return [DailyInfo(
            title: nil,
            artistName: nil,
            base64ImageData: nil,
            base64SmallImageData: nil,
            base64MediumIcon: nil
        )]
    }

    // Format the date key to be used in UserDefaults
    private func formattedDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // Parse the JSON string into an array of DailyInfo objects
    private func parseDailyInfo(from jsonString: String) -> [DailyInfo] {
        logger.info("parseDailyInfo: \(jsonString)\n")
        guard let jsonData = jsonString.data(using: .utf8) else { return [] }
        
        do {
                // Parse the outer array
                if let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [String] {
                    var dailyInfoList: [DailyInfo] = []
                    
                    for jsonStringElement in jsonArray {
                        // Parse each string element as JSON
                        if let elementData = jsonStringElement.data(using: .utf8),
                           let jsonDict = try JSONSerialization.jsonObject(with: elementData) as? [String: Any] {
                            
                            // Map to DailyInfo
                            let dailyInfo = DailyInfo(
                                title: jsonDict["title"] as? String,
                                artistName: jsonDict["artistName"] as? String,
                                base64ImageData: jsonDict["base64ImageData"] as? String,
                                base64SmallImageData: jsonDict["base64SmallImageData"] as? String,
                                base64MediumIcon: jsonDict["base64MediumIcon"] as? String
                            )
                                dailyInfoList.append(dailyInfo)
                            
                        }
                    }
                    
                    return dailyInfoList
                }
            } catch {
                logger.info("Error parsing JSON: \(error.localizedDescription)")
            }
        
        return []
    }
}

// Define the structure of daily artwork data
struct DailyInfo {
    let title: String?
    let artistName: String?
    let base64ImageData: String?
    let base64SmallImageData: String?
    let base64MediumIcon: String?
}

// Entry used for the widget
struct SimpleEntry: TimelineEntry {
    let date: Date
    let dailyInfoList: [DailyInfo]
}

// View that renders the daily widget
struct Daily_WidgetEntryView: View {
    var entry: Provider.Entry
    @State var infoViewHeight: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family
    
    private var heightReader: some View {
        GeometryReader { reader in
            Color.clear
                .onAppear() {
                    logger.info("Appreating")
                    print("Appearing")
                    infoViewHeight = reader.size.height
                }
                .onChange(of: reader.size.height) { val in
                    infoViewHeight = val
                }
        }
    }
    
    private func imageFromBase64(_ base64String: String) -> UIImage? {
        logger.info("Base64 string: \(base64String)")
        guard let imageData = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: imageData)
    }
    
    private func getStartDailyTime() -> Date {
        // Get the current date and time
        let now = Date()
        
        // Use Calendar to calculate the start of the day in the current timezone
        let calendar = Calendar.current
        
        // Get the start of the day (midnight) for the current day
        return calendar.startOfDay(for: now)
    }

    private func getCurrentIndex(dailyInfoList: [DailyInfo]) -> Int {
        // Ensure the dailyInfoList is not empty
        guard !dailyInfoList.isEmpty else {
            fatalError("Slide list must not be empty")
        }

        // Get the current date and time
        let now = Date()
        
        // Calculate the start of the day (midnight)
        let startOfDay = getStartDailyTime()

        // Time elapsed since the start of the day in seconds
        let secondsSinceStart = Int(now.timeIntervalSince(startOfDay))
        
        
        // Calculate the current index based on elapsed time
        let index = (secondsSinceStart / 30) % dailyInfoList.count
        
        return index
    }


    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                let dailyInfo = entry.dailyInfoList.isEmpty ? nil : entry.dailyInfoList[getCurrentIndex(dailyInfoList: entry.dailyInfoList)]
                ZStack {
                    if let artworkThumbnail = imageFromBase64(
                        (family == .systemSmall ? dailyInfo?.base64SmallImageData : dailyInfo?.base64ImageData) ?? "") {
                        Image(uiImage: artworkThumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height - infoViewHeight)
                            .clipped()
                    } else {
                        colorScheme == .dark ? Color("#1C1C1E").edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)
                    }

                    if let mediumIcon = imageFromBase64(dailyInfo?.base64MediumIcon ?? "") {
                        Image(uiImage: mediumIcon)
                            .resizable()
                            .frame(width: 60, height: 58, alignment: .center)
                    }
                }
                .frame(
                    maxWidth: geo.size.width,
                    maxHeight: geo.size.height - infoViewHeight
                )
                
                HStack(spacing: family == .systemSmall ? 10 : 20) {
                    VStack(alignment: .leading, spacing: -2) {
                        if let artistName = dailyInfo?.artistName {
                            Text("\(artistName),")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } else {
                            Text("Daily artwork")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.footnote.bold())
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        if let artworkTitle = dailyInfo?.title {
                            Text(artworkTitle)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.footnote.bold().italic())
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } else {
                            Text("Daily artwork is not available")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                    
                    Image(colorScheme == .dark ? "FFDarkIcon" : "FFLightIcon").frame(width: 30, height: 20)

                }
                .padding(.all, 15)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? Color("#1C1C1E") : Color.white)
                .background { heightReader }
            }
            .frame(maxWidth: geo.size.width, maxHeight: .infinity)
        }.widgetURL(URL(string: "home-widget://message?message=dailyWidgetClicked&widget=daily&homeWidget"))
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

// Widget configuration
struct Daily_Widget: Widget {
    let kind: String = "Daily_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                Daily_WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                Daily_WidgetEntryView(entry: entry)
            }
        }
        .disableContentMarginsIfNeeded()
    }
}

// Preview for the widget in the widget gallery
struct Daily_Widget_Previews: PreviewProvider {
    static var previews: some View {
        Daily_WidgetEntryView(entry: SimpleEntry(date: Date(), dailyInfoList: []))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

