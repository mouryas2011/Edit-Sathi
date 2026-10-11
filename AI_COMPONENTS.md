# Edit Sathi — AI Components & Model Supply-Chain Registry

This document maintains a complete, auditable registry of all on-device AI algorithms, heuristic engines, and planned neural models in Edit Sathi, in strict adherence to the **Edit Sathi Free, On-Device AI Master Requirements**.

---

## 🛡️ Non-Negotiable Privacy & Cost Principles

1. **100% On-Device / Zero Cloud Inference**: No video, audio, image, transcript, or facial data ever leaves the user's device. No cloud servers or remote APIs are required.
2. **Zero Paid APIs & Subscriptions**: Edit Sathi has zero recurring cloud API bills. Features are 100% free and client-side.
3. **No Hidden Data Consumption**: No background model downloads over cellular data without explicit user confirmation.
4. **Non-Destructive & Reversible**: AI suggestions never alter, trim, or overwrite user footage without explicit user review and confirmation. All operations support undo/redo.
5. **No Biometric Profiling**: Facial data is solely evaluated for framing/composition heuristics, never for identifying people, inferring emotion, age, or sensitive traits.

---

## 📋 Supply-Chain & Licensing Matrix

| Feature | Code / Library & Version | Model Name / Version & Source URL | Code License | Model / Weights License | Attribution / NOTICE Requirement | Commercial & Redistribution Status | Download Size & Platform Support | Training Data / Usage Restrictions | Validation Date & Source |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Offline Speech-to-Text Captions** | Native Dart Lexical & Timestamp Engine (`v1.0.0`) | Built-in Multi-lingual Lexical Transcriber (En, Hi, Hi-En, Es) | MIT / Permissive | MIT / BSD-3 | Edit Sathi notices in app licenses screen | Allowed for commercial use & redistribution | **0 MB** (bundled algorithms) • Android & iOS | None; runs entirely on-device | 2026-10-11 • Local Implementation |
| **Speech-Aware Silence & Jump-Cuts** | Local Audio Peak & Energy Analyzer (`v1.0.0`) | Client-side RMS Energy & Pause Heuristic Engine | MIT | MIT / Permissive | Standard package attribution | Allowed | **0 MB** • Android & iOS | None | 2026-10-11 • Local Implementation |
| **Scene & Highlight Assistance** | Heuristic Visual Pacing & Peak Detector (`v1.0.0`) | Deterministic Compositional Pacing Engine | MIT | MIT / Permissive | Standard package attribution | Allowed | **0 MB** • Android & iOS | None | 2026-10-11 • Local Implementation |
| **Thumbnail Frame Ranking** | Local Frame Sharpness & Contrast Analyzer (`v1.0.0`) | High-frequency Laplacian Variance & Luminance Scorer | MIT | MIT / Permissive | Standard package attribution | Allowed | **0 MB** • Android & iOS | None | 2026-10-11 • Local Implementation |
| **Audio Diagnostics ("Audio Doctor")** | Signal Analysis & Normalization DSP (`v1.0.0`) | Local ITU-R BS.1770-4 LUFS & True Peak Calculator | MIT | MIT / Permissive | Standard package attribution | Allowed | **0 MB** • Android & iOS | None | 2026-10-11 • Local Implementation |
| *Planned Tier 1 Optional Model* | `whisper.cpp` / `sherpa-onnx` | OpenAI Whisper Tiny / Sherpa Onnx Q8 | MIT / Apache 2.0 | MIT / Apache 2.0 | OpenAI & Sherpa-ONNX notices required | Allowed (Requires user opt-in & Wi-Fi download) | ~39 MB - 75 MB • Android ARM64, iOS | Non-surveillance only | Evaluation in Progress |

---

## 🔍 Verification & Air-Gap Testing

- **Network Isolation Test**: All Tier 1 features have been validated in Airplane Mode with Wi-Fi and Cellular data turned off.
- **Storage Sandbox**: All processed frames and exported `.srt` files remain within the app's sandboxed `getApplicationDocumentsDirectory()`.
- **Transparency**: Edit Sathi explicitly distinguishes ordinary digital signal processing (DSP) and heuristic analysis from neural networks. No feature is falsely marketed as cloud AI.
