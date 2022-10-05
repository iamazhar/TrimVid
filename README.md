# TrimVid

<img src="https://github.com/iamazhar/TrimVid/blob/main/preview-img.jpeg" width="300">

## Baseline features checklist
- ✅ The video player can be started and stopped
- ✅ Trimmer should always be visible in the same screen as the video player
- ✅ Trimmer should have two drag handles on the left and right side to change the start and end point of the video respectively
- ✅ There should be some sort of indicator of the changed time while dragging either drag handle

## Bonus features checklist
- 🚧 Fill the background of the trimmer with thumbnails of the relative time in the video
- ✅ Change the playback of the video so that it starts at the selected start point and finished at the selected endpoint
- ✅ Add a way to export the trimmed video

## Things to improve
- Larger hit area for the trim handles without increases the size of the handles themselves
- Show an activity indicator when a video is
    - Being loaded
    - Exported
- Reduce Auto Layout boilerplate via one of two options:
    - Write an extension on UIView or a helper class
    - SnapKit
- Add video timeline thumbnails
