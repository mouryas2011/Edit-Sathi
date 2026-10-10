# Edit Sathi 🎬✨

> **Beginner-friendly, feature-rich on-device video editing app for Android and iOS.**

Edit Sathi is a production-grade, approachable mobile video editor built with Flutter. Creators can edit videos, add animated text overlays, mix background audio with waveform visualizers, trim/split clips, apply cinematic color grading presets, and export high-definition videos with 100% on-device privacy.

---

## ✨ Features

- **Intuitive Studio UI**:
  - Direct 1-to-1 match with the design system: vibrant gradient hero action, pastel quick tool cards, recent projects carousel with duration badges, and template presets.
- **Multi-Track Timeline Editor**:
  - **Video Track**: Filmstrip thumbnails, trim handles, split clip at playhead, playback speed ramping (0.5x to 2.0x), mute/unmute, and "+" clip import from gallery.
  - **Text Track**: Draggable purple overlay pills (e.g. *"A Beautiful Day ✨"*), live styling with customizable font sizes, colors, pill backgrounds, and animations (*PopIn, Fade, SlideUp, Typewriter*).
  - **Audio Track**: Teal waveform pill visualizer, background music library, custom audio file importer, and volume slider.
  - **Secondary / Transition Track**: Ambient and B-roll layering.
- **Real-Time Video Preview Canvas**:
  - Live aspect ratio container (*9:16 Reels/TikTok, 16:9 YouTube, 1:1 Instagram, 4:5 Portrait, 21:9 Cinematic*).
  - Real-time compositing of active video frame, filters, and animated text overlays at the current playhead timestamp.
  - Interactive playback controls with live timecode indicator (`00:08 / 00:28`).
- **Full Undo / Redo History Stack**:
  - Comprehensive snapshot state stack allowing instant undo and redo of any title change, clip split, text edit, or track modification.
- **On-Device AI Magic Tools**:
  - **Auto Smart Cut**: Detects silent pauses and trims dead air automatically.
  - **Auto Captions Generator**: Synthesizes synchronized subtitle overlay pills from audio pacing.
  - **Beat Sync Reel Maker**: Aligns video clips with musical beats.
- **Real Video Rendering & Export Pipeline**:
  - Resolution options (*720p, 1080p, 4K*) and FPS selections (*24, 30, 60 fps*).
  - Real multi-stage rendering progress stream with cancel support.
  - Social sharing via `share_plus` directly to Instagram, WhatsApp, YouTube, and TikTok.
- **100% On-Device Privacy**:
  - Zero cloud uploads. Your videos, audio, and projects remain strictly on your device.

---

## 🏛️ Architecture

```
lib/
├── models/
│   ├── project.dart          # ProjectModel, AspectRatioPreset, ResolutionPreset
│   ├── video_clip.dart       # VideoClipModel, VideoFilterPreset, TransitionType
│   ├── text_overlay.dart     # TextOverlayModel, TextAnimationType
│   ├── audio_track.dart      # AudioTrackModel, AudioTrackType
│   └── template.dart         # VideoTemplateModel
├── providers/
│   ├── project_provider.dart # State management, undo/redo, clip CRUD & splitting
│   └── timeline_provider.dart# Playhead position, zoom scale, playback loop
├── services/
│   ├── storage_service.dart  # Project persistence & default seed data
│   ├── export_service.dart   # Multi-stage rendering, progress stream, sharing
│   ├── ai_service.dart       # On-device Auto-Cut, Auto-Captions, Beat-Sync
│   └── template_service.dart # Curated social templates generator
├── theme/
│   ├── app_colors.dart       # Gradients, track colors, and dark/light palettes
│   └── app_theme.dart        # Material 3 light mode & dark editor mode
└── views/
    ├── main_navigation_shell.dart # Bottom navigation (Home, Projects, Templates, Profile)
    ├── home/home_screen.dart      # Brand header, hero banner, quick tools, recent projects
    ├── projects/projects_screen.dart # Search, aspect ratio filter, project management
    ├── templates/templates_screen.dart # Catalog of social templates
    ├── profile/profile_screen.dart   # Privacy, storage clean, licenses, AI settings
    ├── export/export_dialog.dart     # Resolution, FPS, progress, and share dialog
    └── editor/
        ├── editor_screen.dart        # Editor view shell
        └── widgets/
            ├── editor_top_bar.dart        # Back, title rename, resolution pill, undo/redo, export
            ├── video_preview_canvas.dart  # Active clip frame, live text overlay, timecode
            ├── timeline_ruler.dart        # Horizontal time markings & hash ticks
            ├── multi_track_timeline.dart  # Video strip, text pill, waveform audio track
            ├── editor_bottom_toolbar.dart # Trim, Text, Audio, Effects, Captions, More
            └── sheets/                    # Text, filter, aspect ratio, speed, and audio sheets
```

---

## 🚀 Running Locally

### 1. Prerequisites
- Flutter SDK (3.24+ recommended)
- Android Studio / Android SDK (API 34+) or Xcode (for macOS/iOS)

### 2. Verify Environment
```bash
flutter doctor
```

### 3. Analyze & Test Codebase
```bash
# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test
```

### 4. Run on Android Device / Emulator
```bash
# List available devices
flutter devices

# Run on connected Android device or emulator
flutter run -d android
```

### 5. Run on iOS (Mac required)
```bash
# Open iOS simulator or connect iPhone
flutter run -d ios
```
*Note: iOS development requires a macOS host machine with Xcode installed. Permissions (`NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `NSAppleMusicUsageDescription`) are already configured in `ios/Runner/Info.plist`.*

### 6. Run on Web / Chrome
```bash
flutter run -d chrome
```

---

## 📱 Testing Checklist

- [x] **Project Creation**: Tap "+ New Project" to instantiate or import a new edit.
- [x] **Pre-Seeded Projects**: Open "Cafe Vlog", "Travel Edit", or "Reels 2024" to inspect timeline and overlays.
- [x] **Playback & Scrubbing**: Tap play/pause or drag horizontally across the timeline ruler.
- [x] **Split Clip**: Move playhead inside a clip and tap `Trim -> Split Here`.
- [x] **Text Overlays**: Add or tap purple text pills to customize text, font size, colors, and animations.
- [x] **Audio & Waveform**: Add royalty-free or device audio tracks with waveform rendering.
- [x] **Color Grading**: Tap `Effects` to apply Warm Sunset, Cinematic, Cool Blue, Retro, Noir B&W, or Vivid Pop.
- [x] **Undo / Redo**: Tap undo (`↶`) and redo (`↷`) in top bar to revert edits.
- [x] **On-Device AI**: Run `AI Tools -> Auto Smart Cut`, `Auto Captions`, or `Beat Sync`.
- [x] **Export Pipeline**: Tap purple `Export` button, select resolution/FPS, and export with social sharing.
