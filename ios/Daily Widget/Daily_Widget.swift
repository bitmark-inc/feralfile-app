//
//  Daily_Widget.swift
//  Daily Widget
//
//  Created by Anh Nguyen on 10/31/24.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.bitmark.autonomywallet.storage"
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dailyInfo: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let dailyInfo = getStoredDailyInfo();
        let entry = SimpleEntry(
              date: Date(),
              dailyInfo: dailyInfo
        )
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { (entry) in
              let timeline = Timeline(entries: [entry], policy: .atEnd)
              completion(timeline)
            }
    }


    func getStoredDailyInfo() -> DailyInfo {
        let widgetData = UserDefaults.init(suiteName: widgetGroupId)
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current

        let currentDateKey = formatter.string(from: currentDate) // Format the date to string

        // Retrieve JSON string for the current date
        if let jsonString = widgetData?.string(forKey: currentDateKey) {
            do {
                if let jsonData = jsonString.data(using: .utf8),
                   let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    let title = jsonObject["title"] as? String ?? nil
                    let artistName = jsonObject["artistName"] as? String ?? nil
                    let base64MediumIcon = jsonObject["base64MediumIcon"] as? String ?? nil
                    let base64ImageData = jsonObject["base64ImageData"] as? String ?? nil
                    
                    return DailyInfo(
                        title: title,
                        artistName: artistName,
                        base64ImageData: base64ImageData,
                        base64MediumIcon: base64MediumIcon
                    )
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
        
        return DailyInfo(
            title: nil,
            artistName: nil,
            base64ImageData: nil,
            base64MediumIcon: nil
        )
    }
}

struct DailyInfo {
    let title: String?
    let artistName: String?
    let base64ImageData: String?
    let base64MediumIcon: String?
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let dailyInfo: DailyInfo?
}

struct Daily_WidgetEntryView : View {
    var entry: Provider.Entry
    @State var infoViewHeight : CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family
    
    private var heightReader: some View {
        GeometryReader { reader in
            Color.clear
            .onAppear() {
                infoViewHeight = reader.size.height
            }
            .onChange(of: reader.size.height) { val in
                infoViewHeight = val
            }
        }
    }
    
    private func imageFromBase64(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: imageData)
    }

    var body: some View {
        
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack {
                    if let artworkThumbnail = imageFromBase64(entry.dailyInfo?.base64ImageData ?? "") {
                        Image(uiImage: artworkThumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height - infoViewHeight)
                            .clipped()
                    } else {
                        colorScheme == .dark ? Color("#1C1C1E").edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)
                    }

                    
                    if let mediumIcon = imageFromBase64(entry.dailyInfo?.base64MediumIcon ?? "") {
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
                        if let artistName = entry.dailyInfo?.artistName {
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
                        
                        if let artworkTitle = entry.dailyInfo?.title {
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

struct Daily_Widget_Previews: PreviewProvider {
  static var previews: some View {
      Daily_WidgetEntryView(
        entry: SimpleEntry(date: .now, dailyInfo: nil)
    )
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
