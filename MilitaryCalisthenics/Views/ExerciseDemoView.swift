import SwiftUI

/// Renders a looping stick-figure animation of an exercise's motion, drawn
/// entirely in code (no bundled video/image assets) so it stays offline and
/// lightweight. Used both as a small inline preview in the exercise list
/// and as a larger illustration in the exercise detail sheet.
struct ExerciseDemoView: View {
    let motion: ExerciseMotionKind
    var lineWidth: CGFloat = 4
    var cycleDuration: Double = 1.6
    let theme = Theme.shared

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let phase = (timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: cycleDuration)) / cycleDuration
                let pose = ExerciseMotionPose.pose(for: motion, phase: phase)
                draw(pose: pose, in: &context, size: size)
            }
        }
        .drawingGroup()
    }

    private func draw(pose: StickPose, in context: inout GraphicsContext, size: CGSize) {
        var ctx = context
        // Pose coordinates already encode the correct body axis: floor
        // exercises (push-up, plank, mountain climber, etc.) lay the
        // head/hip/limbs out along the x-axis, standing exercises lay
        // them out along the y-axis. No rotation needed — rotating here
        // used to flip floor poses back onto a vertical axis, which is
        // the opposite of what `horizontal` is meant to signal.

        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * size.width, y: p.y * size.height)
        }

        let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        let limbColor = theme.accent

        var limbs = Path()
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.hip))
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.elbowL)); limbs.addLine(to: point(pose.handL))
        limbs.move(to: point(pose.neck)); limbs.addLine(to: point(pose.elbowR)); limbs.addLine(to: point(pose.handR))
        limbs.move(to: point(pose.hip)); limbs.addLine(to: point(pose.kneeL)); limbs.addLine(to: point(pose.footL))
        limbs.move(to: point(pose.hip)); limbs.addLine(to: point(pose.kneeR)); limbs.addLine(to: point(pose.footR))
        ctx.stroke(limbs, with: .color(limbColor), style: stroke)

        let headRadius = min(size.width, size.height) * 0.075
        let headCenter = point(pose.head)
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius,
                               width: headRadius * 2, height: headRadius * 2)
        ctx.fill(Path(ellipseIn: headRect), with: .color(limbColor))

        let groundY = size.height * (pose.horizontal ? 0.88 : 0.94)
        var ground = Path()
        ground.move(to: CGPoint(x: 0, y: groundY))
        ground.addLine(to: CGPoint(x: size.width, y: groundY))
        ctx.stroke(ground, with: .color(theme.textFaint.opacity(0.25)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
    }
}

/// Small looping thumbnail shown inline in an exercise row.
struct ExerciseDemoThumbnail: View {
    let motion: ExerciseMotionKind
    let theme = Theme.shared

    var body: some View {
        ExerciseDemoView(motion: motion, lineWidth: 2.5)
            .frame(width: 44, height: 44)
            .padding(6)
            .background(theme.panel2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Full-size demo sheet: larger animation, exercise name and a coaching cue.
struct ExerciseDemoSheet: View {
    let exerciseNameKey: String
    let motion: ExerciseMotionKind
    let cueKey: String
    let theme = Theme.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(t(exerciseNameKey))
                    .font(.title3.bold())
                    .foregroundStyle(theme.text)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(theme.textFaint)
                }
            }

            ExerciseDemoView(motion: motion, lineWidth: 5)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(theme.panel2)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(theme.accent)
                Text(t(cueKey))
                    .font(.subheadline)
                    .foregroundStyle(theme.textDim)
                Spacer()
            }
            .padding(16)
            .panelBackground()

            Spacer()
        }
        .padding(20)
        .presentationDetents([.medium])
        .background(theme.background)
    }
}
