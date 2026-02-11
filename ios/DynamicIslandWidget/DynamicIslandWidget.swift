import ActivityKit
import WidgetKit
import SwiftUI
// import live_activities_extension

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {
        public var appGroupId: String
        
        public init(appGroupId: String) {
            self.appGroupId = appGroupId
        }
    }
    
    var id = UUID()
    
    public init(id: UUID = UUID()) {
        self.id = id
    }
}

struct AppLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { (context) in
            LockScreenView(context: context)
        } dynamicIsland: { (context) in
            DynamicIsland {
                // EXPANDED VIEW - Premium Design
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(getPrimaryColor(context).opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: getIcon(context))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [getPrimaryColor(context), getPrimaryColor(context).opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text((getData(context, "eventType") ?? "EVENTO").uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            Text(getData(context, "status") ?? "")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(getPrimaryColor(context))
                        }
                    }
                    .padding(.leading, 12)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(getPrimaryColor(context).opacity(0.7))
                            
                            Text(getData(context, "eventDate") ?? "--:--")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [getPrimaryColor(context), getPrimaryColor(context).opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                    .padding(.trailing, 12)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        // Title with gradient
                        Text(getData(context, "eventName") ?? "Novo Evento")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        // Description
                        if let description = getData(context, "eventDescription") {
                            Text(description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        
                        // Decorative divider
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        getPrimaryColor(context).opacity(0.3),
                                        getPrimaryColor(context).opacity(0.6),
                                        getPrimaryColor(context).opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
            } compactLeading: {
                // COMPACT LEADING - Premium Icon
                ZStack {
                    Circle()
                        .fill(getPrimaryColor(context).opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: getIcon(context))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(getPrimaryColor(context))
                }
                
            } compactTrailing: {
                // COMPACT TRAILING - Time with style
                Text(getData(context, "eventDate") ?? "--:--")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [getPrimaryColor(context), getPrimaryColor(context).opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
            } minimal: {
                // MINIMAL - Just the icon with glow
                Image(systemName: getIcon(context))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(getPrimaryColor(context))
                    .shadow(color: getPrimaryColor(context).opacity(0.5), radius: 4)
            }
        }
    }
    
    func getData(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>, _ key: String) -> String? {
        let appGroupId = context.state.appGroupId
        if let defaults = UserDefaults(suiteName: appGroupId) {
            let prefix = context.attributes.id.description
            return defaults.string(forKey: "\(prefix)_\(key)")
        }
        return nil
    }

    func getPrimaryColor(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>) -> Color {
        let type = getData(context, "eventType") ?? ""
        
        // Premium colors for different types
        if type == "IMPORTANTE" {
            return Color(red: 0.95, green: 0.26, blue: 0.21) // Modern red
        }
        if type == "AVISO" {
            return Color(red: 1.0, green: 0.58, blue: 0.0) // Vibrant orange
        }
        
        if let hex = getData(context, "primaryColor") {
            return Color(hex: hex)
        }
        
        return Color(red: 0.4, green: 0.2, blue: 0.6) // Deep purple fallback
    }

    func getIcon(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>) -> String {
        let type = getData(context, "eventType") ?? ""
        if type == "IMPORTANTE" { return "exclamationmark.triangle.fill" }
        if type == "AVISO" { return "megaphone.fill" }
        return "calendar.badge.clock"
    }
}

// MARK: - Lock Screen View (Premium Design)
struct LockScreenView: View {
    let context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    getPrimaryColor(context).opacity(0.08),
                    getPrimaryColor(context).opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left side - Icon + Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(getPrimaryColor(context).opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: getIcon(context))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(getPrimaryColor(context))
                        }
                        
                        Text((getData(context, "eventType") ?? "EVENTO").uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                    }
                    
                    Text(getData(context, "eventName") ?? "Novo Evento")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let description = getData(context, "eventDescription") {
                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Right side - Time + Status
                VStack(alignment: .trailing, spacing: 8) {
                    Text(getData(context, "eventDate") ?? "--:--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [getPrimaryColor(context), getPrimaryColor(context).opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text(getData(context, "status") ?? "")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(getPrimaryColor(context).opacity(0.15))
                        )
                        .foregroundColor(getPrimaryColor(context))
                }
            }
            .padding(16)
        }
        .activityBackgroundTint(Color.clear)
        .activitySystemActionForegroundColor(getPrimaryColor(context))
    }
    
    func getData(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>, _ key: String) -> String? {
        let appGroupId = context.state.appGroupId
        if let defaults = UserDefaults(suiteName: appGroupId) {
            let prefix = context.attributes.id.description
            return defaults.string(forKey: "\(prefix)_\(key)")
        }
        return nil
    }

    func getPrimaryColor(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>) -> Color {
        let type = getData(context, "eventType") ?? ""
        
        if type == "IMPORTANTE" {
            return Color(red: 0.95, green: 0.26, blue: 0.21)
        }
        if type == "AVISO" {
            return Color(red: 1.0, green: 0.58, blue: 0.0)
        }
        
        if let hex = getData(context, "primaryColor") {
            return Color(hex: hex)
        }
        
        return Color(red: 0.4, green: 0.2, blue: 0.6)
    }

    func getIcon(_ context: ActivityViewContext<LiveActivitiesPlugin.LiveActivitiesAppAttributes>) -> String {
        let type = getData(context, "eventType") ?? ""
        if type == "IMPORTANTE" { return "exclamationmark.triangle.fill" }
        if type == "AVISO" { return "megaphone.fill" }
        return "calendar.badge.clock"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
