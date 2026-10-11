# Edit Sathi 🎬✨

> **Privacy-First, On-Device AI Video Editor for Android and iOS.**
> Zero Cloud Subscriptions • 100% Local Processing • No User Media Uploaded

Edit Sathi is a production-grade mobile video editor built with Flutter. Designed with an unwavering commitment to creator privacy, all editing workflows, video decoding, color grading, audio analysis, and AI assistance run strictly on the user's device.

---

## 🛡️ Privacy & Non-Negotiable Rules

1. **Zero Cloud Inference**: Videos, audio, transcripts, and images never leave your phone.
2. **Zero Subscriptions or Paid APIs**: No hidden server bills or per-use API fees. Everything is free and on-device.
3. **No Biometric Profiling**: Facial data is used solely for framing/composition heuristics, never for identifying persons, inferring emotions, age, or sensitive traits.
4. **Reversible & Non-Destructive**: All AI recommendations (cuts, captions, highlights, volume normalization) require user review and confirmation with full undo/redo support.
5. **Supply-Chain Integrity**: Complete model and code license transparency documented in [AI_COMPONENTS.md](file:///home/livelihood/Documents/website/video%20editing%20app/AI_COMPONENTS.md).

---

## ⚡ Tier 1 On-Device AI Features

### 1. Offline Speech-to-Text Captions
- Transcribe audio on-device into editable subtitle segments with millisecond timestamps.
- Multi-language support: Hinglish, Hindi (हिन्दी), English, Spanish (Español).
- Custom caption styles: *Modern Slate Pill, Karaoke Highlight, Cinematic Outline, Minimal Clean*.
- Export subtitles directly to industry-standard `.srt` files.

### 2. Speech-Aware Silence & Jump-Cuts
- Analyzes audio waveforms locally to identify dead air and pauses (>0.4s).
- Displays total time saved (e.g. *"Save ~5.8s of pauses"*).
- Interactive review sheet with checkboxes per silence interval.
- 1-tap jump-cut application that non-destructively trims timeline clips with full undo support.

### 3. Scene & Highlight Assistance
- Evaluates visual pacing and audio energy peaks on-device.
- Recommends key moments: *High-Energy Hook (first 5s)*, *Dynamic Action Climax*, and *Condensed 15s Story Reel*.
- 1-tap jump to recommended timeline segments.

### 4. Thumbnail Studio & Frame Ranker
- Samples candidate frames across the video.
- Heuristic scoring engine evaluates sharpness (high-frequency variance) and contrast/luminance.
- Allows customizing headline typography and exports high-resolution thumbnail images to disk.

### 5. Audio Doctor (Diagnostics & Normalization)
- Local digital signal processing evaluates peak level (dBFS), estimated broadcast loudness (LUFS), and clipping.
- Warns against digital distortion (> -0.1 dBFS).
- 1-tap master normalization to -16 LUFS with safe headroom.

---

## 📊 AI Compatibility Matrix

| Feature | Android (API 26+) | iOS (iOS 15+) | Execution Mode | Network Needed |
| :--- | :--- | :--- | :--- | :--- |
| **Video Import & Sandbox Persistence** | ✅ Supported | ✅ Supported | Local IO Stream | ❌ Offline |
| **Hardware Video Player Preview** | ✅ Supported (Media3) | ✅ Supported (AVFoundation) | Local Surface | ❌ Offline |
| **Offline Captions (Multi-lingual)** | ✅ Supported | ✅ Supported | On-Device Lexical | ❌ Offline |
| **Silence & Jump-Cut Detector** | ✅ Supported | ✅ Supported | Local Audio Analysis | ❌ Offline |
| **Scene & Highlight Suggestions** | ✅ Supported | ✅ Supported | Local Heuristics | ❌ Offline |
| **Thumbnail Frame Ranking** | ✅ Supported | ✅ Supported | Local Image Scorer | ❌ Offline |
| **Audio Diagnostics & Normalizer** | ✅ Supported | ✅ Supported | Local DSP | ❌ Offline |
| **SRT Subtitle Export** | ✅ Supported | ✅ Supported | Local File Writer | ❌ Offline |
| **Multi-Resolution Video Export** | ✅ Supported (720p/1080p/4K) | ✅ Supported | Local Media Pipeline | ❌ Offline |

---

## 🏛️ Architecture & Project Structure

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
│   ├── media_picker_service.dart # Sandbox streaming, content URI resolver, metadata probe
│   ├── ai_service.dart       # Tier 1 On-Device AI Suite (Captions, Cuts, Highlights, Doctor)
│   └── template_service.dart # Curated social templates generator
├── theme/
│   ├── app_colors.dart       # Gradients, track colors, and dark/light palettes
│   └── app_theme.dart        # Material 3 dark editor theme
└── views/
    ├── home/home_screen.dart      # Brand header, hero action, quick tools, recent projects
    ├── projects/projects_screen.dart # Search, aspect ratio filter, project management
    ├── templates/templates_screen.dart # Catalog of social templates
    ├── profile/profile_screen.dart   # Privacy, storage clean, licenses, AI settings
    ├── export/export_dialog.dart     # Resolution, FPS, progress, and share dialog
    └── editor/
        ├── editor_screen.dart        # Editor view shell
        └── widgets/
            ├── editor_top_bar.dart        # Back, title rename, resolution pill, undo/redo, export
            ├── video_preview_canvas.dart  # Hardware video player, live color matrix, text overlays
            ├── timeline_ruler.dart        # Horizontal time markings & hash ticks
            ├── multi_track_timeline.dart  # Video strip, text pill, waveform audio track
            ├── editor_bottom_toolbar.dart # Trim, Text, Audio, Effects, Captions, AI Tools, More
            └── sheets/                    # Text, filter, speed, AI captions, AI tools sheets
```

---

## 🚀 Running & Building

### Prerequisites
- Flutter 3.24+ (Stable channel)
- JDK 17
- Android SDK (Platform 35/36, Build-Tools 36.0.0)

### Analyze & Test
```bash
# Verify static code health
flutter analyze

# Run unit and widget test suite
flutter test
```

### Build Android Release APK
```bash
# Build standalone release APK
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`
