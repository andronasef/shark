import Foundation
import CoreServices

/// Immutable per stream and retained by it, so a callback in flight never sees a freed object.
private final class WatchTarget: Sendable {
    let path: String
    let onChange: @Sendable () -> Void
    init(path: String, onChange: @escaping @Sendable () -> Void) {
        self.path = path
        self.onChange = onChange
    }
}

// File-scope so they carry no actor isolation: FSEvents calls them on its own queue.
private let releaseTarget: CFAllocatorReleaseCallBack = { info in
    guard let info else { return }
    Unmanaged<WatchTarget>.fromOpaque(info).release()
}

private let handleEvents: FSEventStreamCallback = { _, info, count, eventPaths, eventFlags, _ in
    guard let info else { return }
    let target = Unmanaged<WatchTarget>.fromOpaque(info).takeUnretainedValue()
    let paths = unsafeBitCast(eventPaths, to: NSArray.self)
    for index in 0..<count {
        let flags = Int(eventFlags[index])
        // Dropped or coalesced events, or the folder itself moved: rescan.
        let mustRescan = flags & (kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagRootChanged) != 0
        guard let changed = paths[index] as? String else { continue }
        // Streams are recursive; only the folder and its direct children affect the listing.
        let normalized = (changed as NSString).standardizingPath
        if mustRescan || normalized == target.path
            || (normalized as NSString).deletingLastPathComponent == target.path {
            target.onChange()
            return
        }
    }
}

/// Watches one folder and calls back when its direct contents change.
/// Owned and driven from the main actor; the callback runs on a private queue.
@MainActor
public final class FSEventsWatcher {
    private var streamRef: FSEventStreamRef?
    private let queue = DispatchQueue(label: "com.shark.fsevents", qos: .utility)

    public init() {}

    isolated deinit {
        stop()
    }

    public func watch(url: URL, onChange: @escaping @Sendable () -> Void) {
        stop()

        let path = (url.resolvingSymlinksInPath().path as NSString).standardizingPath
        let target = WatchTarget(path: path, onChange: onChange)
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passRetained(target).toOpaque(),
            retain: nil,
            release: releaseTarget,
            copyDescription: nil
        )

        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents
                | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagWatchRoot
        )
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            handleEvents,
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.2, // Latency in seconds
            flags
        ) else {
            Unmanaged<WatchTarget>.fromOpaque(context.info!).release()
            return
        }

        streamRef = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    public func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }
}
