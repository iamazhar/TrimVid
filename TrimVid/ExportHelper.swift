//
//  ExportHelper.swift
//  TrimVid
//
//  Created by Azhar Anwar on 05/10/22.
//

import Foundation
import AVFoundation
import Photos

public final class ExportHelper {
  public static func export(
    _ asset: AVAsset,
    startTime: CMTime,
    endTime: CMTime,
    _ completion: @escaping (Bool, Error?) -> Void
  ) {
      guard asset.isExportable else { return }
      
      /// 1. Create URL with file name
      let tempFileURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
      )[0].appendingPathComponent("temp_video_data.mp4", isDirectory: false)
      
      /// 2. Create a mutable composition using asset and start and end times
      let composition = AVMutableComposition()
      
      let compositionVideoTrack = composition.addMutableTrack(
        withMediaType: AVMediaType.video,
        preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)
      )
      
      let compositionAudioTrack = composition.addMutableTrack(
        withMediaType: AVMediaType.audio,
        preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid)
      )
      
      guard let sourceVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first, 
              let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
      
      do {
        try compositionVideoTrack?.insertTimeRange(
          CMTimeRangeMake(start: startTime, duration: CMTimeSubtract(endTime, startTime)),
          of: sourceVideoTrack,
          at: CMTime.zero
        )
        
        try compositionAudioTrack?.insertTimeRange(
          CMTimeRangeMake(start: startTime, duration: CMTimeSubtract(endTime, startTime)),
          of: sourceAudioTrack,
          at: CMTime.zero
        )
      } catch(_) {
        print("Failed to compose new video from source video")
        return
      }
      
      /// 3. Create an asset export session with a passthrough preset that will match the quality preset of
      /// source asset
      guard
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough),
        exportSession.supportedFileTypes.contains(.mp4) else {
        return
      }
      
      exportSession.outputURL = tempFileURL
      exportSession.outputFileType = .mp4
      let startTime = CMTimeMake(value: 0, timescale: 1)
      let timeRange = CMTimeRangeMake(start: startTime, duration: CMTimeSubtract(endTime, startTime))
      exportSession.timeRange = timeRange
      
      /// 4. Export composed video to the temp location
      exportSession.exportAsynchronously {
        
        /// 5. Export file from temp location to the photo gallery
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempFileURL)
        }) { saved, error in
          if saved {
            /// 6. Delete existing temporary file
            do {
              try FileManager.default.removeItem(at: tempFileURL)
              print("Deleted existing temporary file")
            } catch {
              print("Could not remove file \(error.localizedDescription)")
            }
          }
          /// 7. Call completion on main thread for UI to proceed
          DispatchQueue.main.async {
            completion(saved, error)
          }
        }
      }
    }
}
