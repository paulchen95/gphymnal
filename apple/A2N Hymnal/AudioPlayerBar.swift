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

    private var isPlaying: Bool { player.state == PlayerState.Playing }
    private var progress: Double {
        player.duration > 0 ? player.currentTime / player.duration : 0
    }

    var body: some View {
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
                        Text(PlayerTime.format(player.currentTime) + " / " + PlayerTime.format(player.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows playback controls")

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
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            // Spotify-style hairline progress along the bottom edge of the mini player.
            GeometryReader { geometry in
                Capsule()
                    .fill(Color.brandAccent)
                    .frame(width: geometry.size.width * progress, height: 2)
            }
            .frame(height: 2)
            .padding(.horizontal, 14)
            .padding(.bottom, 3)
            .animation(.linear(duration: 0.25), value: progress)
        }
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
        .task(id: hymn.filename) { duration = Mp3Player.duration(of: hymn.filename) }
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

    var body: some View {
        VStack(spacing: 0) {
            HymnCover(hymn: hymn, style: .full)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 360)
                .padding(.top, 36)
                .scaleEffect(player.state == PlayerState.Playing ? 1 : 0.92)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: player.state)

            Spacer(minLength: 20)

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

            HStack(spacing: 48) {
                Button {
                    player.skip(by: -15)
                } label: {
                    Label("Back 15 Seconds", systemImage: "gobackward.15")
                }
                PlayPauseButton(player: player, size: 72)
                Button {
                    player.skip(by: 15)
                } label: {
                    Label("Forward 15 Seconds", systemImage: "goforward.15")
                }
            }
            .labelStyle(.iconOnly)
            .font(.title)
            .foregroundColor(.primary)
            .padding(.top, 12)

            Spacer(minLength: 20)

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

                Spacer()

                Button(action: onShowLyrics) {
                    Label("View Lyrics", systemImage: "text.quote")
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 28)
        .background(
            // A soft wash of the cover's gold behind everything.
            LinearGradient(colors: [Color.brandAccent.opacity(0.18), Color.paper],
                           startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
    }
}

/// The timeline under the title, in the style of Apple Music: tap anywhere on it to jump
/// there, or drag to scrub. The track thickens while it's being touched. A plain Slider only
/// moves when you drag its thumb.
private struct PlaybackTimeline: View {
    let position: TimeInterval
    let duration: TimeInterval
    let onScrub: (TimeInterval) -> Void
    let onCommit: (TimeInterval) -> Void
    let onStep: (TimeInterval) -> Void

    @State private var isTouching = false

    private var fraction: Double {
        duration > 0 ? min(max(position / duration, 0), 1) : 0
    }

    var body: some View {
        GeometryReader { geometry in
            let height: CGFloat = isTouching ? 12 : 6
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.15))
                Capsule().fill(Color.brandAccent.opacity(isTouching ? 1 : 0.85))
                    .frame(width: geometry.size.width * fraction)
            }
            .frame(height: height)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isTouching = true
                        onScrub(time(at: value.location.x, width: geometry.size.width))
                    }
                    .onEnded { value in
                        isTouching = false
                        onCommit(time(at: value.location.x, width: geometry.size.width))
                    }
            )
            .animation(.easeOut(duration: 0.15), value: isTouching)
        }
        // A tall touch area around a thin track, so it's easy to hit with a finger.
        .frame(height: 32)
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
