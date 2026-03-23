import SwiftUI
import SwiftData

// MARK: - Filter & Sort Types

enum HistorySortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case longestFirst = "Longest First"
    case shortestFirst = "Shortest First"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .newestFirst: "arrow.down.circle"
        case .oldestFirst: "arrow.up.circle"
        case .longestFirst: "timer"
        case .shortestFirst: "clock"
        }
    }
}

enum CompletionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Completed"
    case cancelled = "Ended Early"
    
    var id: String { rawValue }
}

enum DateGrouping: String, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { rawValue }
}

// MARK: - HistoryView

/// Full-featured history with search, filter, sort, grouping, export, and detail navigation.
/// Free: last 7 fasts. Premium: unlimited + streak.
struct HistoryView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startDate, order: .reverse)
    private var sessions: [FastingSession]
    
    @State private var showPaywall = false
    @State private var showSoftPaywall = false
    @State private var searchText = ""
    @State private var sortOption: HistorySortOption = .newestFirst
    @State private var completionFilter: CompletionFilter = .all
    @State private var planFilter: FastingPlan?
    @State private var dateGrouping: DateGrouping = .none
    @State private var showFilterSheet = false
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var deleteTarget: FastingSession?
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    
    private let freeLimit = 7
    
    // MARK: - Computed Properties
    
    private var completedCount: Int {
        sessions.filter(\.isCompleted).count
    }
    
    private var accessibleSessions: [FastingSession] {
        if subscriptionManager.isSubscribed { return sessions }
        return Array(sessions.prefix(freeLimit))
    }
    
    private var hasLockedSessions: Bool {
        !subscriptionManager.isSubscribed && sessions.count > freeLimit
    }
    
    /// Apply search + filters + sort to accessible sessions
    private var filteredSessions: [FastingSession] {
        var result = accessibleSessions
        
        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { session in
                session.plan.rawValue.lowercased().contains(query)
                || session.stage.rawValue.lowercased().contains(query)
                || (session.note?.lowercased().contains(query) ?? false)
                || (session.mood?.contains(query) ?? false)
                || session.startDate.formatted(.dateTime.month(.wide).day().year()).lowercased().contains(query)
            }
        }
        
        // Completion filter
        switch completionFilter {
        case .all: break
        case .completed: result = result.filter(\.isCompleted)
        case .cancelled: result = result.filter { !$0.isCompleted }
        }
        
        // Plan filter
        if let planFilter {
            result = result.filter { $0.planType == planFilter.rawValue }
        }
        
        // Sort
        switch sortOption {
        case .newestFirst: result.sort { $0.startDate > $1.startDate }
        case .oldestFirst: result.sort { $0.startDate < $1.startDate }
        case .longestFirst: result.sort { $0.actualDuration > $1.actualDuration }
        case .shortestFirst: result.sort { $0.actualDuration < $1.actualDuration }
        }
        
        return result
    }
    
    /// Group sessions by date period for section headers
    private var groupedSessions: [(key: String, sessions: [FastingSession])] {
        guard dateGrouping != .none else {
            return [("", filteredSessions)]
        }
        
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session -> String in
            groupKey(for: session, calendar: calendar)
        }
        
        return grouped.map { (key: $0.key, sessions: $0.value) }
            .sorted { lhs, rhs in
                guard let d1 = lhs.sessions.first?.startDate,
                      let d2 = rhs.sessions.first?.startDate else { return false }
                return d1 > d2
            }
    }
    
    private func groupKey(for session: FastingSession, calendar: Calendar) -> String {
        switch dateGrouping {
        case .daily:
            return session.startDate.formatted(.dateTime.month(.wide).day().year())
        case .weekly:
            let weekOfYear = calendar.component(.weekOfYear, from: session.startDate)
            let year = calendar.component(.yearForWeekOfYear, from: session.startDate)
            let comps = DateComponents(weekOfYear: weekOfYear, yearForWeekOfYear: year)
            let startOfWeek = calendar.date(from: comps) ?? session.startDate
            return "Week of \(startOfWeek.formatted(.dateTime.month(.abbreviated).day()))"
        case .monthly:
            return session.startDate.formatted(.dateTime.month(.wide).year())
        case .none:
            return ""
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if completionFilter != .all { count += 1 }
        if planFilter != nil { count += 1 }
        if dateGrouping != .none { count += 1 }
        if sortOption != .newestFirst { count += 1 }
        return count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    historyEmptyState
                } else {
                    sessionListContent
                }
            }
            .navigationTitle("History")
            .toolbar { historyToolbar }
            .searchable(text: $searchText, prompt: "Search fasts...")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showSoftPaywall) {
                SoftPaywallView(reason: .historyLimit)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showFilterSheet) {
                HistoryFilterSheet(
                    sortOption: $sortOption,
                    completionFilter: $completionFilter,
                    planFilter: $planFilter,
                    dateGrouping: $dateGrouping,
                    onDismiss: { showFilterSheet = false }
                )
            }
            .sheet(isPresented: $showExportSheet) {
                HistoryShareSheet(items: [exportText])
            }
            .alert("Delete Fast?", isPresented: $showDeleteConfirmation) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Something went wrong. Please try again.")
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var historyToolbar: some ToolbarContent {
        if !sessions.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                completedBadge
            }
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                exportMenuButton
            }
        }
    }
    
    // MARK: - Completed Badge
    
    private var completedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.green)
            Text("\(completedCount)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.green.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("\(completedCount) completed fasts")
    }
    
    // MARK: - Filter Button
    
    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .symbolVariant(activeFilterCount > 0 ? .fill : .none)
                
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(.red))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .accessibilityLabel("Filters\(activeFilterCount > 0 ? ", \(activeFilterCount) active" : "")")
    }
    
    // MARK: - Export Menu
    
    private var exportMenuButton: some View {
        Menu {
            Button {
                exportText = FastDetailExporter.fullHistoryText(accessibleSessions)
                showExportSheet = true
            } label: {
                Label("Share as Text", systemImage: "doc.text")
            }
            
            Button {
                if let url = FastingDataExporter.exportToFile(sessions: accessibleSessions) {
                    exportText = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                    showExportSheet = true
                }
            } label: {
                Label("Export CSV", systemImage: "tablecells")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Export history")
    }
    
    // MARK: - Delete Alert
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Delete", role: .destructive) {
            if let target = deleteTarget {
                HapticManager.shared.heavyTap()
                withAnimation(.smoothSpring) {
                    modelContext.delete(target)
                    let success = DataController.shared.save(modelContext, operation: "delete fasting session")
                    if !success {
                        errorMessage = "Couldn't delete the fasting session. Please try again."
                        showError = true
                    }
                }
                deleteTarget = nil
            }
        }
        Button("Cancel", role: .cancel) {
            deleteTarget = nil
        }
    }
    
    @ViewBuilder
    private var deleteAlertMessage: some View {
        if let target = deleteTarget {
            let dateStr = target.startDate.formatted(.dateTime.month(.abbreviated).day())
            Text("This will permanently delete your \(target.plan.rawValue) fast from \(dateStr).")
        }
    }
    
    // MARK: - Empty State
    
    private var historyEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.12), Color.yellow.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)
                
                Circle()
                    .fill(Color.orange.opacity(0.06))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)
            
            VStack(spacing: 10) {
                Text("Your Fasting Journey\nStarts Here")
                    .font(.system(.title3, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Start your first fast to see your\nhistory, streaks, and progress.")
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // CTA button navigating to Timer tab
            NavigationLink {
                // This is a visual CTA — in a TabView app, switching tabs is handled by parent.
                // Using a label that signals the action.
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Start Your First Fast")
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.orange.gradient)
                )
                .shadow(color: .orange.opacity(0.3), radius: 10, y: 4)
            }
            .buttonStyle(.bounce)
            .padding(.top, 4)
            
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                Text("All data stays on your device")
                    .font(.system(.caption))
            }
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .entranceAnimation()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your fasting journey starts here. Start your first fast to see your history, streaks, and progress.")
    }
    
    // MARK: - Session List
    
    private var sessionListContent: some View {
        List {
            statsSection
            
            if activeFilterCount > 0 {
                activeFiltersSection
            }
            
            if filteredSessions.isEmpty {
                noResultsSection
            } else {
                sessionGroupSections
            }
            
            if hasLockedSessions {
                lockedSection
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            isRefreshing = true
            try? await Task.sleep(for: .milliseconds(600))
            isRefreshing = false
        }
    }
    
    // MARK: - Session Group Sections
    
    private var sessionGroupSections: some View {
        ForEach(groupedSessions, id: \.key) { group in
            Section {
                ForEach(Array(group.sessions.enumerated()), id: \.element.id) { index, session in
                    sessionRow(session: session, index: index)
                }
            } header: {
                if !group.key.isEmpty {
                    Text(group.key)
                }
            }
        }
    }
    
    private func sessionRow(session: FastingSession, index: Int) -> some View {
        NavigationLink {
            FastDetailView(session: session)
        } label: {
            FastingSessionRow(session: session)
                .staggeredAppear(index: index)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteTarget = session
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                exportText = FastDetailExporter.singleFastText(session)
                showExportSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
        }
    }
    
    // MARK: - No Results
    
    private var noResultsSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundStyle(.tertiary)
                
                Text("No matching fasts")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text("Try adjusting your search or filters")
                    .font(.system(.caption))
                    .foregroundStyle(.tertiary)
                
                if activeFilterCount > 0 {
                    Button("Clear Filters") {
                        withAnimation(.smoothSpring) { resetFilters() }
                    }
                    .font(.system(.caption, weight: .medium))
                    .buttonStyle(.bounce)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Active Filters
    
    private var activeFiltersSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if completionFilter != .all {
                        HistoryFilterPill(text: completionFilter.rawValue) {
                            withAnimation(.smoothSpring) { completionFilter = .all }
                        }
                    }
                    if let plan = planFilter {
                        HistoryFilterPill(text: plan.rawValue) {
                            withAnimation(.smoothSpring) { planFilter = nil }
                        }
                    }
                    if dateGrouping != .none {
                        HistoryFilterPill(text: "Grouped: \(dateGrouping.rawValue)") {
                            withAnimation(.smoothSpring) { dateGrouping = .none }
                        }
                    }
                    if sortOption != .newestFirst {
                        HistoryFilterPill(text: sortOption.rawValue) {
                            withAnimation(.smoothSpring) { sortOption = .newestFirst }
                        }
                    }
                    Button("Clear All") {
                        withAnimation(.smoothSpring) { resetFilters() }
                    }
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(.red)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                HistoryStatCard(
                    title: "Total Fasts",
                    value: "\(sessions.count)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                if subscriptionManager.isSubscribed {
                    HistoryStatCard(
                        title: "Current Streak",
                        value: "\(currentStreak)",
                        icon: "bolt.fill",
                        color: .yellow
                    )
                } else {
                    HistoryLockedStatCard(
                        title: "Streak",
                        icon: "bolt.fill",
                        color: .yellow
                    ) {
                        showPaywall = true
                    }
                }
                
                HistoryStatCard(
                    title: "Avg Duration",
                    value: formatHours(averageDuration),
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Locked Section
    
    private var lockedSection: some View {
        Section {
            Button {
                HapticManager.shared.lightTap()
                showSoftPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(.body))
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock Full History")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("\(sessions.count - freeLimit) more fasts · Upgrade to Premium")
                            .font(.system(.footnote))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityLabel("Unlock full history. \(sessions.count - freeLimit) more fasts available with Premium.")
            .accessibilityHint("Double tap to see upgrade options")
        }
    }
    
    // MARK: - Helpers
    
    private func resetFilters() {
        sortOption = .newestFirst
        completionFilter = .all
        planFilter = nil
        dateGrouping = .none
        searchText = ""
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)
        
        let completedDays = Set(
            sessions
                .filter { $0.isCompleted }
                .map { calendar.startOfDay(for: $0.startDate) }
        )
        .sorted(by: >)
        
        for day in completedDays {
            if day == checkDate {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else if let prev = calendar.date(byAdding: .day, value: -1, to: checkDate), day == prev {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }
    
    private var averageDuration: TimeInterval {
        let completed = sessions.filter(\.isCompleted)
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0.0) { $0 + $1.actualDuration }
        return total / Double(completed.count)
    }
    
    private func formatHours(_ duration: TimeInterval) -> String {
        let hours = duration / 3600
        if hours < 1 {
            return "\(Int(duration / 60))m"
        }
        return String(format: "%.1fh", hours)
    }
}

// MARK: - Filter Pill

private struct HistoryFilterPill: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(.caption, weight: .medium))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())
    }
}

// MARK: - Stat Card

private struct HistoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            Text(title)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Locked Stat Card

private struct HistoryLockedStatCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(.body))
                    .foregroundStyle(color.opacity(0.4))
                
                Image(systemName: "lock.fill")
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.system(.caption))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bounce)
        .accessibilityLabel("\(title): Premium feature, locked")
        .accessibilityHint("Double tap to upgrade to Premium")
    }
}

// MARK: - Filter Sheet (separate struct to reduce type-checking)

struct HistoryFilterSheet: View {
    @Binding var sortOption: HistorySortOption
    @Binding var completionFilter: CompletionFilter
    @Binding var planFilter: FastingPlan?
    @Binding var dateGrouping: DateGrouping
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                sortSection
                statusSection
                planSection
                groupSection
                resetSection
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var sortSection: some View {
        Section("Sort By") {
            ForEach(HistorySortOption.allCases) { option in
                filterRow(title: option.rawValue, icon: option.icon, isSelected: sortOption == option) {
                    sortOption = option
                }
            }
        }
    }
    
    private var statusSection: some View {
        Section("Status") {
            ForEach(CompletionFilter.allCases) { filter in
                filterRow(title: filter.rawValue, isSelected: completionFilter == filter) {
                    completionFilter = filter
                }
            }
        }
    }
    
    private var planSection: some View {
        Section("Plan Type") {
            filterRow(title: "All Plans", isSelected: planFilter == nil) {
                planFilter = nil
            }
            ForEach(FastingPlan.allCases) { plan in
                filterRow(title: plan.rawValue, isSelected: planFilter == plan) {
                    planFilter = plan
                }
            }
        }
    }
    
    private var groupSection: some View {
        Section("Group By") {
            ForEach(DateGrouping.allCases) { grouping in
                filterRow(title: grouping.rawValue, isSelected: dateGrouping == grouping) {
                    dateGrouping = grouping
                }
            }
        }
    }
    
    private var resetSection: some View {
        Section {
            Button("Reset All Filters", role: .destructive) {
                sortOption = .newestFirst
                completionFilter = .all
                planFilter = nil
                dateGrouping = .none
            }
        }
    }
    
    private func filterRow(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon {
                    Label(title, systemImage: icon)
                        .foregroundStyle(.primary)
                } else {
                    Text(title)
                        .foregroundStyle(.primary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.system(.body, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: FastingSession.self, inMemory: true)
        .environment(SubscriptionManager())
        .environment(ThemeManager())
}
