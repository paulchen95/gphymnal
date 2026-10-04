//
//  AudioPlayerBar.swift
//  A2N Hymnal
//
//  Playback UI. A mini player floats at the bottom of the app while a hymn is loaded, so
//  you can keep listening while you browse other hymns (see `NowPlaying`). Tapping it opens
//  Now Playing: a generated cover card (there's no album art), the full controls, and a
//  shortcut back to the playing hymn's lyrics.
//

import SwiftUI

struct AudioPlayerBar: View {
    @ObservedObject var player: Mp3Player
    let hymn: Hymn
    let onShowLyrics: () -> Void
    let onClose: () -> Void

    @State private var showNowPlaying = false
    /// Where the timeline is being dragged to; nil otherwise.
    @State private var scrubTime: TimeInterval?

    private var isPlaying: Bool { player.state == PlayerState.Playing }
    private var position: TimeInterval { scrubTime ?? player.currentTime }

    var body: some View {
        VStack(spacing: 0) {
        HStack(spacing: 12) {
            Button {
                showNowPlaying = true
            } label: {
                HStack(spacing: 12) {
                    HymnCover(hymn: hymn, style: .thumbnail)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hymn.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(PlayerTime.format(position) + " / " + PlayerTime.format(player.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows playback controls")

            #if targetEnvironment(macCatalyst)
            // Spotify-style volume; ⌘↑ and ⌘↓ move the same slider.
            VolumeControl(player: player)
                .frame(width: 140)
            #endif

            PlayPauseButton(player: player, size: 32)

            // Once paused, the mini player can be put away.
            if !isPlaying {
                Button(action: onClose) {
                    Label("Close Player", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .padding(.top, 10)

        // A slim timeline along the bottom: tap or drag it to move through the hymn without
        // leaving the lyrics.
        PlaybackTimeline(
            position: position,
            duration: player.duration,
            onScrub: { scrubTime = $0 },
            onCommit: { time in
                player.seek(to: time)
                scrubTime = nil
            },
            onStep: { player.skip(by: $0) },
            compact: true
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 2)
        }
        .buttonStyle(.borderless)
        .miniPlayerBackground()
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .animation(.easeOut(duration: 0.2), value: isPlaying)
        .sheet(isPresented: $showNowPlaying) {
            NowPlayingView(player: player, hymn: hymn) {
                showNowPlaying = false
                onShowLyrics()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

/// The player bar on a hymn page when nothing is loaded: the same shape as the mini
/// player, showing this hymn ready to play. Tapping anywhere on it plays.
struct ReadyToPlayBar: View {
    let hymn: Hymn
    let play: () -> Void

    @State private var duration: TimeInterval = 0

    var body: some View {
        Button(action: play) {
            HStack(spacing: 12) {
                HymnCover(hymn: hymn, style: .thumbnail)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hymn.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(duration > 0 ? PlayerTime.format(duration) : " ")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.brandAccent)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .miniPlayerBackground()
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .accessibilityLabel("Play " + hymn.name)
        .help("Play this hymn (Space or Return)")
        // Read off the main thread: opening the mp3 there stalled the app just long enough,
        // right as a hymn opened, to miss the second click of a double-click on the Mac.
        .task(id: hymn.filename) {
            let name = hymn.filename
            duration = await Task.detached(priority: .userInitiated) { Mp3Player.duration(of: name) }.value
        }
    }
}

/// Shown above the mini player when you're looking at a hymn other than the one loaded.
struct PlayInsteadButton: View {
    let hymn: Hymn
    let play: () -> Void

    var body: some View {
        Button(action: play) {
            Label("Play “" + hymn.name + "” instead", systemImage: "play.fill")
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundColor(.brandAccent)
        .help("Play this hymn instead (Return)")
        .miniPlayerBackground(cornerRadius: 100)
        .padding(.horizontal, 24)
    }
}

/// Stands in for album art: the hymn's title and opening line set on a warm Acts2 gold
/// gradient, so every hymn gets its own card.
struct HymnCover: View {
    enum Style { case thumbnail, full }

    let hymn: Hymn
    let style: Style

    var body: some View {
        let radius: CGFloat = style == .full ? 24 : 8
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(red: 0.87, green: 0.60, blue: 0.10), Color(red: 0.55, green: 0.29, blue: 0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // A large, faint note as texture in the corner.
            Image(systemName: "music.note")
                .font(.system(size: style == .full ? 220 : 30, weight: .bold))
                .foregroundColor(.white.opacity(style == .full ? 0.10 : 0.9))
                .rotationEffect(.degrees(style == .full ? -12 : 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: style == .full ? .topTrailing : .center)
                .offset(x: style == .full ? 30 : 0, y: style == .full ? -20 : 0)

            if style == .full {
                VStack(alignment: .leading, spacing: 10) {
                    Text("“" + hymn.firstLine + "”")
                        .font(.system(.title3, design: .serif).italic())
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                    Text(hymn.name)
                        .font(.brandTitle(size: 30, relativeTo: .title))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                }
                .padding(24)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .shadow(color: .black.opacity(style == .full ? 0.25 : 0), radius: 24, y: 12)
        .accessibilityHidden(true)
    }
}

/// Full-screen player: cover card, title and author, timeline, transport controls, and
/// the Start Over, Repeat and View Lyrics actions.
struct NowPlayingView: View {
    @ObservedObject var player: Mp3Player
    let hymn: Hymn
    let onShowLyrics: () -> Void

    /// Where the scrubber is while it's being dragged; nil otherwise.
    @State private var scrubTime: TimeInterval?

    private var position: TimeInterval { scrubTime ?? player.currentTime }

    /// Compact on a phone in landscape: too short to stack the cover over the controls.
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                // Cover beside the controls, as in Apple Music, so nothing is cut off.
                HStack(spacing: 32) {
                    cover
                        .padding(.vertical, 24)
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        titleAndAuthor
                        timeline
                        transport
                        Spacer(minLength: 12)
                        footer
                    }
                }
            } else {
                VStack(spacing: 0) {
                    cover
                        .padding(.top, 36)

                    Spacer(minLength: 20)

                    titleAndAuthor
                    timeline
                    transport

                    #if targetEnvironment(macCatalyst)
                    VolumeControl(player: player)
                        .frame(maxWidth: 320)
                        .padding(.top, 20)
                    #endif

                    Spacer(minLength: 20)

                    footer
                }
            }
        }
        .padding(.horizontal, 28)
        // Bare icons and text, no bezels: the Mac otherwise puts a light box behind each.
        .buttonStyle(.borderless)
        .background(
            // A soft wash of the cover's gold behind everything.
            LinearGradient(colors: [Color.brandAccent.opacity(0.18), Color.paper],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
    }

    private var cover: some View {
        HymnCover(hymn: hymn, style: .full)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 360)
            .scaleEffect(player.state == PlayerState.Playing ? 1 : 0.92)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: player.state)
    }

    private var titleAndAuthor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hymn.name)
                .font(.brandTitle(size: 24, relativeTo: .title2))
                .lineLimit(2)
            if !hymn.author.isEmpty {
                Text(hymn.author)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeline: some View {
        VStack(spacing: 4) {
            PlaybackTimeline(
                position: position,
                duration: player.duration,
                onScrub: { scrubTime = $0 },
                onCommit: { time in
                    player.seek(to: time)
                    scrubTime = nil
                },
                onStep: { player.skip(by: $0) }
            )

            HStack {
                Text(PlayerTime.format(position))
                Spacer()
                Text("-" + PlayerTime.format(player.duration - position))
            }
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .accessibilityHidden(true)
        }
        .padding(.top, 16)
    }

    private var transport: some View {
        HStack(spacing: 48) {
            Button {
                player.skip(by: -15)
            } label: {
                Label("Back 15 Seconds", systemImage: "gobackward.15")
            }
            .help("Back 15 seconds")
            PlayPauseButton(player: player, size: 72)
            Button {
                player.skip(by: 15)
            } label: {
                Label("Forward 15 Seconds", systemImage: "goforward.15")
            }
            .help("Forward 15 seconds")
        }
        .labelStyle(.iconOnly)
        .font(.title)
        .foregroundColor(.primary)
        .padding(.top, 12)
    }

    /// Start Over, Repeat and View Lyrics along the bottom.
    private var footer: some View {
        HStack {
            Button {
                _ = player.restart()
            } label: {
                Label("Start Over", systemImage: "arrow.counterclockwise")
            }
            .disabled(player.state == PlayerState.Stopped)

            Spacer()

            Button {
                player.repeats.toggle()
            } label: {
                Label("Repeat", systemImage: "repeat.1")
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .foregroundColor(player.repeats ? .onAccent : .secondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(player.repeats ? Color.brandAccent : Color.clear))
            }
            .accessibilityValue(player.repeats ? "On" : "Off")
            .help(player.repeats ? "Repeat is on (⌥⌘R)" : "Repeat (⌥⌘R)")

            Spacer()

            Button(action: onShowLyrics) {
                Label("View Lyrics", systemImage: "text.quote")
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.bottom, 12)
    }
}

/// The timeline under the title, in the style of Apple Music: tap anywhere on it to jump
/// there, or drag to scrub. A plain Slider only moves when you drag its thumb.
///
/// It previews where you'd land the way Spotify's desktop player does. With a pointer over
/// it (Mac, or an iPad with a trackpad or mouse) the track thickens and brightens, a knob
/// marks the playback position, a lighter band runs from there to the pointer, and a bubble
/// above the pointer shows the time a click would jump to. A finger gets the knob and the
/// bubble while it's down.
private struct PlaybackTimeline: View {
    let position: TimeInterval
    let duration: TimeInterval
    let onScrub: (TimeInterval) -> Void
    let onCommit: (TimeInterval) -> Void
    let onStep: (TimeInterval) -> Void
    /// The slim version in the mini player.
    var compact = false

    /// Where a finger or a pressed pointer is, along the track; nil otherwise.
    @State private var dragX: CGFloat?
    /// Where a hovering pointer is, along the track; nil otherwise.
    @State private var hoverX: CGFloat?

    private var fraction: Double {
        duration > 0 ? min(max(position / duration, 0), 1) : 0
    }

    private var isTouching: Bool { dragX != nil }
    private var isActive: Bool { dragX != nil || hoverX != nil }
    /// A tall touch area around a thin track, so it's easy to hit with a finger.
    private var frameHeight: CGFloat { compact ? 22 : 32 }

    private var trackHeight: CGFloat {
        if compact { return isTouching ? 8 : (hoverX != nil ? 5 : 3) }
        return isTouching ? 12 : (hoverX != nil ? 8 : 6)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progressX = width * fraction
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(isActive ? 0.22 : 0.15))
                    .frame(height: trackHeight)
                // The stretch a click would skip over: ahead of the playback position it
                // fills in lightly; behind it, it lightens the gold.
                if let hoverX, dragX == nil {
                    let x = min(max(hoverX, 0), width)
                    let ahead = x >= progressX
                    Capsule().fill(Color.brandAccent.opacity(0.35))
                        .frame(width: ahead ? x : 0, height: trackHeight)
                    Capsule().fill(Color.brandAccent.opacity(isActive ? 1 : 0.85))
                        .frame(width: progressX, height: trackHeight)
                    if !ahead {
                        Rectangle().fill(Color.white.opacity(0.45))
                            .frame(width: progressX - x, height: trackHeight)
                            .offset(x: x)
                    }
                } else {
                    Capsule().fill(Color.brandAccent.opacity(isActive ? 1 : 0.85))
                        .frame(width: progressX, height: trackHeight)
                }
            }
            .frame(height: trackHeight)
            .clipShape(Capsule())
            .frame(maxHeight: .infinity)
            .overlay(alignment: .leading) {
                if isActive {
                    let knob: CGFloat = compact ? 12 : 16
                    Circle().fill(Color.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .frame(width: knob, height: knob)
                        .offset(x: progressX - knob / 2)
                }
            }
            .overlay {
                if let x = dragX ?? hoverX {
                    let pointerX = min(max(x, 0), width)
                    // Clear of the knob for a pointer; well clear of the fingertip for touch.
                    let gap: CGFloat = hoverX != nil ? 6 : 26
                    BubblePlacement(x: pointerX, bottom: frameHeight / 2 - trackHeight / 2 - gap) {
                        TimeBubble(time: time(at: pointerX, width: width))
                    }
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location): hoverX = location.x
                case .ended: hoverX = nil
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragX = value.location.x
                        onScrub(time(at: value.location.x, width: width))
                    }
                    .onEnded { value in
                        dragX = nil
                        onCommit(time(at: value.location.x, width: width))
                    }
            )
            .animation(.easeOut(duration: 0.15), value: isTouching)
            .animation(.easeOut(duration: 0.15), value: hoverX != nil)
        }
        .frame(height: frameHeight)
        .accessibilityElement()
        .accessibilityLabel("Playback Position")
        .accessibilityValue(PlayerTime.format(position))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onStep(15)
            case .decrement: onStep(-15)
            @unknown default: break
            }
        }
    }

    private func time(at x: CGFloat, width: CGFloat) -> TimeInterval {
        guard width > 0 else { return 0 }
        return Double(min(max(x / width, 0), 1)) * duration
    }
}

/// Places the time bubble with its bottom edge at `bottom` and centred on `x`, but kept
/// within the timeline's ends. It may stick out above the timeline; nothing clips it.
private struct BubblePlacement: Layout {
    let x: CGFloat
    let bottom: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let left = min(max(x - size.width / 2, 0), max(bounds.width - size.width, 0))
            subview.place(at: CGPoint(x: bounds.minX + left, y: bounds.minY + bottom - size.height),
                          proposal: ProposedViewSize(size))
        }
    }
}

/// The small dark label over the timeline showing the time you'd jump to. Dark in light and
/// dark mode alike, with a faint edge so it still reads against a dark background.
private struct TimeBubble: View {
    let time: TimeInterval

    var body: some View {
        Text(PlayerTime.format(time))
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(white: 0.16))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12)))
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            )
            .fixedSize()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct PlayPauseButton: View {
    @ObservedObject var player: Mp3Player
    let size: CGFloat

    private var isPlaying: Bool { player.state == PlayerState.Playing }

    var body: some View {
        Button {
            _ = isPlaying ? player.paused() : player.play()
        } label: {
            Label(isPlaying ? "Pause" : "Play",
                  systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: size))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.brandAccent)
        }
        // No bezel: the Mac otherwise draws a grey square behind the circle.
        .buttonStyle(.borderless)
        .help(isPlaying ? "Pause (Space)" : "Play (Space)")
    }
}

private enum PlayerTime {
    static func format(_ time: TimeInterval) -> String {
        let seconds = max(Int(time.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private extension View {
    /// Liquid Glass on iOS 26, where the mini player floats like the system's own controls;
    /// a material card with a soft shadow before that.
    @ViewBuilder
    func miniPlayerBackground(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
    }
}

/// The app's playback volume, on the Mac where there are no volume buttons: a speaker that
/// mutes and unmutes, and a slider. It's the same volume the Playback menu's Volume Up and
/// Down (⌘↑ ⌘↓) change.
struct VolumeControl: View {
    @ObservedObject var player: Mp3Player
    /// The volume to go back to when unmuting.
    @State private var volumeBeforeMute: Float = 1

    private var icon: String {
        switch player.volume {
        case 0: return "speaker.slash.fill"
        case ..<0.34: return "speaker.wave.1.fill"
        case ..<0.67: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if player.volume > 0 {
                    volumeBeforeMute = player.volume
                    player.volume = 0
                } else {
                    player.volume = volumeBeforeMute > 0 ? volumeBeforeMute : 1
                }
            } label: {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    // Fixed width, so the slider doesn't shift as the waves change.
                    .frame(width: 22, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.volume > 0 ? "Mute" : "Unmute")
            .help(player.volume > 0 ? "Mute" : "Unmute")

            Slider(value: Binding(get: { Double(player.volume) }, set: { player.volume = Float($0) }), in: 0...1)
                .tint(.brandAccent)
                .accessibilityLabel("Volume")
                .help("Volume (⌘↑ ⌘↓)")
        }
    }
}
