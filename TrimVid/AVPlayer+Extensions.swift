//
//  AVPlayer+Extensions.swift
//  TrimVid
//
//  Created by Azhar Anwar on 04/10/22.
//

import AVFoundation

extension AVPlayer {
  var isPlaying: Bool {
    return self.rate != 0 && self.error == nil
  }
}
