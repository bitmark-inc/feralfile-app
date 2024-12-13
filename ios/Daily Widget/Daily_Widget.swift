//
//  Daily_Widget.swift
//  Daily Widget
//
//  Created by Nguyen Phuoc Sang on 6/12/24.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.bitmark.autonomywallet.storage"
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), dailyInfo: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let dailyInfo = fetchDailyInfo();
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
    
    func fetchDailyInfo() -> DailyInfo {
        guard
            let widgetData = UserDefaults(suiteName: widgetGroupId),
            let dailyDataString = widgetData.string(forKey: "dailyData"),
            let dailyData = dailyDataString.data(using: .utf8),
            let dailyObject = try? JSONSerialization.jsonObject(with: dailyData, options: []) as? [String: Any]
        else {
            return DailyInfo.empty
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        let currentDateKey = formatter.string(from: Date())

        guard
            let todayDailyString = dailyObject[currentDateKey] as? String,
            let todayDailyData = todayDailyString.data(using: .utf8),
            let todayDailyObject = try? JSONSerialization.jsonObject(with: todayDailyData, options: []) as? [String: Any]
        else {
            return DailyInfo.empty
        }

        return DailyInfo(
            title: todayDailyObject["title"] as? String,
            artistName: todayDailyObject["artistName"] as? String,
            base64ImageData: todayDailyObject["base64ImageData"] as? String,
            base64SmallImageData: todayDailyObject["base64SmallImageData"] as? String,
            displayMediumIcon: (todayDailyObject["displayMediumIcon"] as? Bool) ?? false
        )
    }
}

struct DailyInfo {
    let title: String?
    let artistName: String?
    let base64ImageData: String?
    let base64SmallImageData: String?
    let displayMediumIcon: Bool
    
    static let empty = DailyInfo(title: nil, artistName: nil, base64ImageData: nil, base64SmallImageData: nil, displayMediumIcon: false)
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
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color("#1C1C1E") : .white
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
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
                imageSection(geo.size)
                infoSection
            }
            .frame(maxWidth: geo.size.width, maxHeight: .infinity)
        }
        .widgetURL(URL(string: "home-widget://message?message=dailyWidgetClicked&widget=daily&homeWidget"))
    }
    
    @ViewBuilder
    private func imageSection(_ size: CGSize) -> some View {
        ZStack {
            if let artworkThumbnail = imageFromBase64(
                (family == .systemSmall ? entry.dailyInfo?.base64SmallImageData : entry.dailyInfo?.base64ImageData) ?? ""
            ) {
                Image(uiImage: artworkThumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: size.width, maxHeight: size.height - infoViewHeight)
                    .clipped()
            } else {
                backgroundColor.edgesIgnoringSafeArea(.all)
            }
            
            if (entry.dailyInfo != nil && entry.dailyInfo!.displayMediumIcon) {
                Image("MediumIcon")
                    .resizable()
                    .frame(width: 60, height: 58, alignment: .center)
            }
        }
        .frame(
            maxWidth: size.width,
            maxHeight: size.height - infoViewHeight
        )
    }
    
    private var infoSection: some View {
        HStack(spacing: family == .systemSmall ? 10 : 20) {
            VStack(alignment: .leading, spacing: -2) {
                Text(entry.dailyInfo?.artistName ?? "Daily artwork")
                    .font(.footnote)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(entry.dailyInfo?.title ?? "Daily artwork is not available")
                    .font(.footnote.bold().italic())
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Image(colorScheme == .dark ? "FFDarkIcon" : "FFLightIcon")
                .frame(width: 30, height: 20)
        }
        .padding(.all, 15)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .background { heightReader }
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
