# 🎙️ Google AI Edge Eloquent (Prototype)
> **Turn Spoken Thoughts into Well-Crafted Text using Google Gemma**

Inspired by Google's announcement of **Google AI Edge Eloquent**, this prototype provides an on-device/edge speech dictation & polishing solution built with **Flutter Web** and **Python FastAPI**.

---

## ✨ Features Implemented

1. **Live Microphone Dictation (Web Speech API)**:
   - Zero-latency browser speech recognition with real-time text feedback.
   - Animated glowing mic button and live audio waveform visualizer.
2. **Instant Preset Voice Samples**:
   - Ready-to-test audio presets (*Messy Team Sync*, *Voice Note Idea Pitch*, *Production Bug Report*, *Quarterly Executive Update*) so anyone can test the app with 1 click without needing a microphone.
3. **Google Gemma Speech Polishing**:
   - Strips out filler words (`um`, `uh`, `like`, `you know`, `basically`, stuttering, repeated words).
   - Fixes grammar, punctuation, and sentence flow while preserving original speaker intent.
4. **Multiple Output Modes**:
   - 📝 **Sentences**: Natural, fluent, eloquent paragraph.
   - 📌 **Bullet Points**: Clean, distinct takeaway list.
   - 📋 **Meeting Notes**: Discussion points + Action items checkbox list.
   - ✉️ **Draft Email**: Ready-to-send email with subject line and greetings.
   - 📱 **Social Post**: Engaging LinkedIn/Twitter format with hashtags.
   - ⚡ **TL;DR Brief**: Crisp 2-sentence executive summary.
5. **Tone Customization**:
   - Professional, Casual, Executive, Direct.
6. **Polishing Metrics**:
   - Dynamic *Clarity Boost %* indicator.
   - *Fillers Stripped* counter.
7. **Action Tools**:
   - One-click *Copy to Clipboard*.
   - *Listen (Text-to-Speech)* to hear the polished output.
   - Model configuration dialog (optional Google AI Studio key).

---

## 🚀 Running the App

The server is currently running on port **8000**!

- **On your computer**: Open [http://localhost:8000](http://localhost:8000)
- **On any phone/tablet on your Wi-Fi**: Open `http://192.168.1.156:8000`

### One-Click Scripts
- `run_demo.bat`: Starts the FastAPI server and serves the Flutter Web app.
- `share_link.bat`: Generates a public HTTPS link (via `localtunnel`) so anyone in the world can test it directly on their phone or browser.
