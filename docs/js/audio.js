/**
 * MagicTouch — Procedural Web Audio Haptics Engine
 * Generates tactile Apple Taptic Engine mechanical clicks and fingertip taps
 * using pure Web Audio API synthesis without external audio files.
 */

class HapticAudio {
  constructor() {
    this.audioCtx = null;
    this.isMuted = true; // Default to muted for browser autoplay policy compliance
    this.listeners = [];
  }

  /**
   * Initializes or resumes the AudioContext on user interaction
   */
  initContext() {
    if (!this.audioCtx) {
      const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
      if (AudioCtxClass) {
        this.audioCtx = new AudioCtxClass();
      }
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
  }

  /**
   * Toggles audio mute state
   * @returns {boolean} New mute state (true if muted, false if active)
   */
  toggleMute() {
    this.isMuted = !this.isMuted;
    if (!this.isMuted) {
      this.initContext();
      this.playClick(); // Auditory confirmation of unmuting
    }
    this.notifyListeners();
    return this.isMuted;
  }

  /**
   * Subscribes to mute state changes
   */
  onMuteChange(callback) {
    if (typeof callback === 'function') {
      this.listeners.push(callback);
    }
  }

  notifyListeners() {
    this.listeners.forEach(cb => {
      try { cb(this.isMuted); } catch (e) { console.error(e); }
    });
  }

  /**
   * Synthesizes an Apple Magic Mouse tactile mechanical click
   * (swept sine oscillator + high-pass filtered micro-noise burst)
   */
  playClick() {
    if (this.isMuted) return;
    this.initContext();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    // 1. Primary Low-Frequency Mechanical Body (260Hz -> 50Hz)
    const osc = ctx.createOscillator();
    const oscGain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(260, now);
    osc.frequency.exponentialRampToValueAtTime(50, now + 0.038);

    oscGain.gain.setValueAtTime(0.7, now);
    oscGain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);

    osc.connect(oscGain);
    oscGain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.045);

    // 2. High-Frequency Tactile Micro-Transient (Noise burst)
    const bufferSize = Math.floor(ctx.sampleRate * 0.015); // 15ms buffer
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.3));
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'highpass';
    filter.frequency.setValueAtTime(1400, now);

    const noiseGain = ctx.createGain();
    noiseGain.gain.setValueAtTime(0.4, now);
    noiseGain.gain.exponentialRampToValueAtTime(0.001, now + 0.015);

    noise.connect(filter);
    filter.connect(noiseGain);
    noiseGain.connect(ctx.destination);

    noise.start(now);
  }

  /**
   * Synthesizes a light capacitive fingertip tap
   */
  playTap() {
    if (this.isMuted) return;
    this.initContext();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(420, now);
    osc.frequency.exponentialRampToValueAtTime(120, now + 0.022);

    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.025);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.028);
  }

  /**
   * Synthesizes a fluid swipe motion sound
   */
  playSwipe() {
    if (this.isMuted) return;
    this.initContext();
    if (!this.audioCtx) return;

    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    const bufferSize = Math.floor(ctx.sampleRate * 0.07); // 70ms buffer
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1);
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.Q.setValueAtTime(3.0, now);
    filter.frequency.setValueAtTime(900, now);
    filter.frequency.exponentialRampToValueAtTime(350, now + 0.07);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.18, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);

    noise.start(now);
  }

  /**
   * Synthesizes a rapid dual micro-click for pinch gestures
   */
  playPinch() {
    if (this.isMuted) return;
    this.playTap();
    setTimeout(() => {
      this.playTap();
    }, 28);
  }

  /**
   * Plays corresponding haptic sound for a gesture
   */
  playHaptic(gestureType) {
    switch (gestureType) {
      case 'click':
      case 'middle-click':
      case 'four-tap':
        this.playClick();
        break;
      case 'tip-tap':
        this.playTap();
        break;
      case 'swipe':
        this.playSwipe();
        break;
      case 'pinch':
        this.playPinch();
        break;
      default:
        this.playTap();
    }
  }
}

// Export singleton instance
window.hapticAudio = new HapticAudio();
