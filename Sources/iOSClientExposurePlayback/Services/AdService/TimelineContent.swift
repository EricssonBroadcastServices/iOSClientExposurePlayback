import Foundation
import AVKit

struct TimelineContent: Equatable {
    let contentType: String?
    let contentTitle: String?
    let contentStartTime: Double
    let contentEndTime: Double
    var isWatched: Bool
    let timeRange: CMTimeRange
    
    init(
        contentType: String? = nil,
        contentTitle: String? = nil ,
        contentStartTime: Double,
        contentEndTime: Double,
        isWatched: Bool = false,
        timeRange: CMTimeRange
    ) {
        self.contentType = contentType
        self.contentTitle = contentTitle
        self.contentStartTime = contentStartTime
        self.contentEndTime = contentEndTime
        self.isWatched = isWatched
        self.timeRange = timeRange
    }
}
