import SwiftUI

/// Lets the user log a new bodyweight measurement and see a simple trend
/// of past entries. Logging a new weight recalibrates the active plan
/// (see `PlanViewModel.logWeight`).
struct WeightProgressView: View {
    var viewModel: PlanViewModel
    let theme = Theme.shared
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var date: Date = .now
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    trendCard
                    logCard
                    historyCard
                }
                .padding(20)
            }
            .background(theme.background)
            .navigationTitle(t("progress.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("common.close")) { dismiss() }
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .onAppear {
            weightText = viewModel.profile.map { String(format: "%.1f", $0.weightKg) } ?? ""
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("progress.trend"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            if viewModel.weightHistory.count < 2 {
                Text(t("progress.trend.empty"))
                    .font(.footnote)
                    .foregroundStyle(theme.textFaint)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                WeightSparkline(entries: viewModel.weightHistory)
                    .frame(height: 120)

                HStack {
                    if let first = viewModel.weightHistory.first {
                        Text(String(format: "%.1f kg", first.weightKg))
                            .font(.caption)
                            .foregroundStyle(theme.textFaint)
                    }
                    Spacer()
                    if let last = viewModel.weightHistory.last {
                        Text(String(format: "%.1f kg", last.weightKg))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
            }
        }
        .padding(16)
        .panelBackground()
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("progress.log"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            DatePicker(t("progress.date"), selection: $date, in: ...Date.now, displayedComponents: .date)
                .tint(theme.accent)
                .foregroundStyle(theme.text)

            HStack {
                Text(t("onboarding.weight"))
                    .foregroundStyle(theme.text)
                Spacer()
                TextField("kg", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(theme.accent)
                    .frame(width: 90)
            }
            .padding(14)
            .background(theme.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if showError {
                Text(t("onboarding.error.range"))
                    .font(.footnote)
                    .foregroundStyle(theme.danger)
            }

            Button {
                logWeight()
            } label: {
                Text(t("progress.save"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.black)
                    .background(theme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .panelBackground()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("progress.history"))
                .font(.subheadline)
                .foregroundStyle(theme.textDim)

            if viewModel.weightHistory.isEmpty {
                Text(t("progress.history.empty"))
                    .font(.footnote)
                    .foregroundStyle(theme.textFaint)
            } else {
                let ordered = Array(viewModel.weightHistory.reversed())
                VStack(spacing: 0) {
                    ForEach(Array(ordered.enumerated()), id: \.element.persistentModelID) { index, entry in
                        HStack {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(theme.textDim)
                            Spacer()
                            Text(String(format: "%.1f kg", entry.weightKg))
                                .foregroundStyle(theme.text)
                                .fontWeight(.semibold)
                            Button {
                                withAnimation(theme.springAnimation) {
                                    viewModel.deleteWeightEntry(entry)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(theme.danger)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 12)
                            .accessibilityLabel(t("common.delete"))
                        }
                        .padding(.vertical, 10)
                        if index != ordered.count - 1 {
                            Divider().overlay(theme.textFaint.opacity(0.2))
                        }
                    }
                }
            }
        }
        .padding(16)
        .panelBackground()
    }

    private func logWeight() {
        guard let weight = Double(weightText.replacingOccurrences(of: ",", with: ".")),
              (30...250).contains(weight) else {
            withAnimation(theme.springAnimation) { showError = true }
            return
        }
        showError = false
        withAnimation(theme.springAnimation) {
            viewModel.logWeight(weight, on: date)
        }
        dismiss()
    }
}

/// Minimal hand-drawn line chart of weight entries, matching the
/// exercise-demo drawing style rather than pulling in a charting library.
private struct WeightSparkline: View {
    let entries: [WeightEntry]
    let theme = Theme.shared

    var body: some View {
        Canvas { context, size in
            guard entries.count > 1 else { return }
            let weights = entries.map(\.weightKg)
            let minW = (weights.min() ?? 0) - 1
            let maxW = (weights.max() ?? 1) + 1
            let range = max(maxW - minW, 1)

            func point(_ index: Int) -> CGPoint {
                let x = size.width * CGFloat(index) / CGFloat(entries.count - 1)
                let normalized = (entries[index].weightKg - minW) / range
                let y = size.height * (1 - CGFloat(normalized))
                return CGPoint(x: x, y: y)
            }

            var line = Path()
            line.move(to: point(0))
            for i in 1..<entries.count { line.addLine(to: point(i)) }

            var fill = line
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .linearGradient(
                Gradient(colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.0)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
            ))

            context.stroke(line, with: .color(theme.accent), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            for i in entries.indices {
                let p = point(i)
                let dot = Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
                context.fill(dot, with: .color(i == entries.count - 1 ? theme.accentLight : theme.accent))
            }
        }
    }
}
