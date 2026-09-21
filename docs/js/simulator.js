/**
 * MagicTouch — Interactive Magic Mouse Canvas Simulator
 * Renders a Retina-scaled Apple Magic Mouse surface with live capacitive touch tracking,
 * particle glow effects, gesture tour animations, and real-time HUD telemetry.
 */

class MagicMouseSimulator {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');

    // Display & DPI scaling
    this.dpr = window.devicePixelRatio || 1;
    this.width = 0;
    this.height = 0;

    // Mouse surface boundary in canvas space
    this.mouseBounds = { x: 0, y: 0, w: 0, h: 0, r: 0 };

    // Active touch points: [{ id, normX, normY, size, alpha, vx, vy, isSimulated }]
    this.touches = [];
    this.particles = [];

    // Interaction states
    this.isMouseDown = false;
    this.currentGesture = null;

    // Tour animation state
    this.animatingTour = false;
    this.autoTourActive = false;
    this.autoTourIndex = 0;
    this.autoTourTimer = null;
    this.animationStartTime = 0;
    this.currentTourId = null;

    // Preset Tour Definitions
    this.presets = {
      'middle-click': {
        name: 'Middle Click (3-Finger)',
        icon: '🖱️',
        desc: '3 simultaneous contacts in upper active sensing zone',
        action: 'Mouse Button 3 (Open Link in Background Tab / Close Tab)',
        haptic: 'middle-click',
        duration: 1200
      },
      'tip-tap': {
        name: 'Tip-Tap Right',
        icon: '👆',
        desc: 'Index finger remains anchored while middle finger taps down',
        action: 'Switch to Next Browser Tab / Forward Navigation',
        haptic: 'tip-tap',
        duration: 1300
      },
      'pinch': {
        name: '2-Finger Pinch In/Out',
        icon: '🤏',
        desc: 'Symmetrical two-finger inward/outward capacitive convergence',
        action: 'Smart Zoom 2x / Mac Quick Look Preview',
        haptic: 'pinch',
        duration: 1500
      },
      'swipe': {
        name: '2-Finger Spaces Swipe',
        icon: '↔️',
        desc: 'Two parallel fingers gliding horizontally across surface',
        action: 'Move Left/Right a Space (Virtual Desktop Switching)',
        haptic: 'swipe',
        duration: 1400
      },
      'four-tap': {
        name: '4-Finger Tap',
        icon: '🖐️',
        desc: 'Four fingers touching simultaneously across upper surface',
        action: 'Mission Control & App Windows Exposé',
        haptic: 'four-tap',
        duration: 1200
      }
    };

    // Cache telemetry DOM references
    this.dom = {
      gestureIcon: document.getElementById('hud-gesture-icon'),
      gestureName: document.getElementById('hud-gesture-name'),
      gestureDesc: document.getElementById('hud-gesture-desc'),
      actionDesc: document.getElementById('hud-action-desc'),
      telemetryContacts: document.getElementById('telemetry-contacts'),
      telemetryPhase: document.getElementById('telemetry-phase'),
      telemetryCoords: document.getElementById('telemetry-coords'),
      telemetryForce: document.getElementById('telemetry-force'),
      recognitionHud: document.getElementById('recognition-hud'),
      autoTourBtn: document.getElementById('auto-tour-btn'),
      autoTourText: document.getElementById('auto-tour-text')
    };

    this.init();
  }

  init() {
    this.setupResize();
    this.bindEvents();
    this.startRenderLoop();

    // Default to Middle Click preview
    this.playGesture('middle-click', false);
  }

  setupResize() {
    const handleResize = () => {
      const rect = this.canvas.parentElement.getBoundingClientRect();
      this.width = rect.width;
      this.height = rect.height;

      this.canvas.width = this.width * this.dpr;
      this.canvas.height = this.height * this.dpr;
      this.ctx.resetTransform();
      this.ctx.scale(this.dpr, this.dpr);

      // Compute Magic Mouse proportions (approx 1 : 1.9 ratio)
      const mouseW = Math.min(this.width * 0.62, 220);
      const mouseH = mouseW * 1.9;
      this.mouseBounds = {
        x: (this.width - mouseW) / 2,
        y: (this.height - mouseH) / 2,
        w: mouseW,
        h: mouseH,
        r: mouseW * 0.44 // Smooth top/bottom pill curvature
      };
    };

    window.addEventListener('resize', handleResize);
    handleResize();
  }

  bindEvents() {
    // Mouse interaction
    this.canvas.addEventListener('mousedown', (e) => {
      this.stopAutoTour();
      this.animatingTour = false;
      this.isMouseDown = true;
      this.handlePointerDown(e.clientX, e.clientY);
    });

    window.addEventListener('mousemove', (e) => {
      if (this.isMouseDown) {
        const rect = this.canvas.getBoundingClientRect();
        this.handlePointerMove(e.clientX, e.clientY, rect);
      }
    });

    window.addEventListener('mouseup', () => {
      if (this.isMouseDown) {
        this.isMouseDown = false;
        this.handlePointerUp();
      }
    });

    // Touch interaction
    this.canvas.addEventListener('touchstart', (e) => {
      this.stopAutoTour();
      this.animatingTour = false;
      e.preventDefault();
      const rect = this.canvas.getBoundingClientRect();
      this.touches = [];
      for (let i = 0; i < e.touches.length; i++) {
        const t = e.touches[i];
        const norm = this.screenToNormalized(t.clientX - rect.left, t.clientY - rect.top);
        if (norm) {
          this.touches.push({
            id: t.identifier,
            normX: norm.x,
            normY: norm.y,
            size: 20,
            alpha: 0.9,
            pulse: 0
          });
        }
      }
      this.updateInteractiveTelemetry('Began');
      if (window.hapticAudio) window.hapticAudio.playTap();
    }, { passive: false });

    this.canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      const rect = this.canvas.getBoundingClientRect();
      this.touches = [];
      for (let i = 0; i < e.touches.length; i++) {
        const t = e.touches[i];
        const norm = this.screenToNormalized(t.clientX - rect.left, t.clientY - rect.top);
        if (norm) {
          this.touches.push({
            id: t.identifier,
            normX: norm.x,
            normY: norm.y,
            size: 20,
            alpha: 0.9,
            pulse: 0
          });
          this.spawnParticles(norm.x, norm.y);
        }
      }
      this.updateInteractiveTelemetry('Moved');
    }, { passive: false });

    this.canvas.addEventListener('touchend', (e) => {
      e.preventDefault();
      if (e.touches.length === 0) {
        this.touches = [];
        this.updateInteractiveTelemetry('Ended');
      }
    }, { passive: false });
  }

  screenToNormalized(canvasX, canvasY) {
    const b = this.mouseBounds;
    // Check if inside mouse bounding box
    if (canvasX < b.x || canvasX > b.x + b.w || canvasY < b.y || canvasY > b.y + b.h) {
      return null;
    }
    // Normalized: X: 0..1 (left to right), Y: 0..1 (bottom to top, macOS Multitouch spec)
    const normX = Math.max(0, Math.min(1, (canvasX - b.x) / b.w));
    const normY = Math.max(0, Math.min(1, 1 - (canvasY - b.y) / b.h));
    return { x: normX, y: normY };
  }

  normalizedToCanvas(normX, normY) {
    const b = this.mouseBounds;
    const canvasX = b.x + normX * b.w;
    const canvasY = b.y + (1 - normY) * b.h;
    return { x: canvasX, y: canvasY };
  }

  handlePointerDown(clientX, clientY) {
    const rect = this.canvas.getBoundingClientRect();
    const norm = this.screenToNormalized(clientX - rect.left, clientY - rect.top);
    if (norm) {
      this.touches = [{
        id: 'mouse-primary',
        normX: norm.x,
        normY: norm.y,
        size: 22,
        alpha: 0.95,
        pulse: 0
      }];
      this.updateInteractiveTelemetry('Began');
      if (window.hapticAudio) window.hapticAudio.playClick();
      this.triggerHudPulse();
    }
  }

  handlePointerMove(clientX, clientY, rect) {
    const norm = this.screenToNormalized(clientX - rect.left, clientY - rect.top);
    if (norm && this.touches.length > 0) {
      this.touches[0].normX = norm.x;
      this.touches[0].normY = norm.y;
      this.spawnParticles(norm.x, norm.y);
      this.updateInteractiveTelemetry('Moved');
    }
  }

  handlePointerUp() {
    this.touches = [];
    this.updateInteractiveTelemetry('Ended');
  }

  spawnParticles(normX, normY) {
    const pt = this.normalizedToCanvas(normX, normY);
    for (let i = 0; i < 2; i++) {
      this.particles.push({
        x: pt.x + (Math.random() - 0.5) * 10,
        y: pt.y + (Math.random() - 0.5) * 10,
        vx: (Math.random() - 0.5) * 1.5,
        vy: (Math.random() - 0.5) * 1.5,
        alpha: 0.8,
        size: Math.random() * 3 + 2
      });
    }
  }

  updateInteractiveTelemetry(phase) {
    const count = this.touches.length;
    if (this.dom.telemetryContacts) {
      this.dom.telemetryContacts.textContent = `${count} ${count === 1 ? 'contact' : 'contacts'}`;
    }
    if (this.dom.telemetryPhase) {
      this.dom.telemetryPhase.textContent = phase;
    }
    if (count > 0 && this.dom.telemetryCoords) {
      const t = this.touches[0];
      this.dom.telemetryCoords.textContent = `${t.normX.toFixed(2)}, ${t.normY.toFixed(2)}`;
    }
    if (this.dom.telemetryForce) {
      this.dom.telemetryForce.textContent = count > 0 ? `${(16.5 + count * 2.3).toFixed(1)} pt²` : '0.0 pt²';
    }

    // Dynamic gesture detection for manual interactive touches
    if (count === 1) {
      this.setHudBadge('1-Finger Direct Point', '🖱️', 'Tracking single capacitive contact', 'Cursor Navigation / Precision Track');
    } else if (count === 2) {
      this.setHudBadge('2-Finger Contact', '✌️', 'Dual capacitive contact detected', 'Scroll / Dual-Finger Action Target');
    } else if (count >= 3) {
      this.setHudBadge(`${count}-Finger Contact`, '🖐️', 'Multi-touch cluster active', 'Trigger Configured Multi-finger Action');
    }
  }

  setHudBadge(name, icon, desc, action) {
    if (this.dom.gestureName) this.dom.gestureName.textContent = name;
    if (this.dom.gestureIcon) this.dom.gestureIcon.textContent = icon;
    if (this.dom.gestureDesc) this.dom.gestureDesc.textContent = desc;
    if (this.dom.actionDesc) this.dom.actionDesc.textContent = action;
  }

  triggerHudPulse() {
    if (this.dom.recognitionHud) {
      this.dom.recognitionHud.classList.remove('hud-trigger-pulse');
      // Trigger reflow
      void this.dom.recognitionHud.offsetWidth;
      this.dom.recognitionHud.classList.add('hud-trigger-pulse');
    }
  }

  /**
   * Plays automated gesture trajectory for a given preset
   */
  playGesture(gestureId, triggerAudio = true) {
    const preset = this.presets[gestureId];
    if (!preset) return;

    this.currentTourId = gestureId;
    this.animatingTour = true;
    this.animationStartTime = performance.now();

    // Update HUD
    this.setHudBadge(preset.name, preset.icon, preset.desc, preset.action);
    this.triggerHudPulse();

    // Update active state in preset buttons
    document.querySelectorAll('.preset-btn').forEach(btn => {
      if (btn.getAttribute('data-gesture') === gestureId) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    if (triggerAudio && window.hapticAudio) {
      window.hapticAudio.playHaptic(preset.haptic);
    }
  }

  /**
   * Toggles the automated gesture showcase loop
   */
  toggleAutoTour() {
    if (this.autoTourActive) {
      this.stopAutoTour();
    } else {
      this.startAutoTour();
    }
  }

  startAutoTour() {
    this.autoTourActive = true;
    if (this.dom.autoTourText) this.dom.autoTourText.textContent = 'Pause Tour';
    if (this.dom.autoTourBtn) this.dom.autoTourBtn.classList.add('ring-2', 'ring-cyan-400');

    const keys = Object.keys(this.presets);
    const runNext = () => {
      if (!this.autoTourActive) return;
      const key = keys[this.autoTourIndex % keys.length];
      this.playGesture(key, true);
      this.autoTourIndex++;
      this.autoTourTimer = setTimeout(runNext, 2600);
    };

    runNext();
  }

  stopAutoTour() {
    this.autoTourActive = false;
    if (this.autoTourTimer) {
      clearTimeout(this.autoTourTimer);
      this.autoTourTimer = null;
    }
    if (this.dom.autoTourText) this.dom.autoTourText.textContent = 'Auto-Tour';
    if (this.dom.autoTourBtn) this.dom.autoTourBtn.classList.remove('ring-2', 'ring-cyan-400');
  }

  /**
   * Main 60fps Canvas render loop
   */
  startRenderLoop() {
    const render = (time) => {
      this.ctx.clearRect(0, 0, this.width, this.height);

      // 1. Draw photorealistic Apple Magic Mouse Body
      this.drawMouseBody();

      // 2. Update tour animation if running
      if (this.animatingTour && this.currentTourId) {
        this.updateTourAnimation(time);
      }

      // 3. Draw trailing particle effects
      this.drawParticles();

      // 4. Draw active capacitive touch points
      this.drawTouchPoints(time);

      requestAnimationFrame(render);
    };

    requestAnimationFrame(render);
  }

  /**
   * Draws photorealistic Magic Mouse acrylic glass surface with specular highlights
   */
  drawMouseBody() {
    const ctx = this.ctx;
    const b = this.mouseBounds;

    ctx.save();

    // Subtle outer drop shadow
    ctx.shadowColor = 'rgba(0, 0, 0, 0.7)';
    ctx.shadowBlur = 35;
    ctx.shadowOffsetY = 15;

    // Outer Aluminum Frame / Bevel
    ctx.beginPath();
    ctx.roundRect(b.x, b.y, b.w, b.h, b.r);
    const aluminumGrad = ctx.createLinearGradient(b.x, b.y, b.x + b.w, b.y + b.h);
    aluminumGrad.addColorStop(0, '#52525b');
    aluminumGrad.addColorStop(0.5, '#71717a');
    aluminumGrad.addColorStop(1, '#3f3f46');
    ctx.fillStyle = aluminumGrad;
    ctx.fill();

    ctx.shadowColor = 'transparent';

    // White Acrylic Glass Top Surface (inset 2.5px)
    const inset = 2.5;
    ctx.beginPath();
    ctx.roundRect(b.x + inset, b.y + inset, b.w - inset * 2, b.h - inset * 2, b.r - inset);
    const glassGrad = ctx.createLinearGradient(b.x, b.y, b.x, b.y + b.h);
    glassGrad.addColorStop(0, '#ffffff');
    glassGrad.addColorStop(0.2, '#f8f8fb');
    glassGrad.addColorStop(0.7, '#f1f1f5');
    glassGrad.addColorStop(1, '#e4e4e9');
    ctx.fillStyle = glassGrad;
    ctx.fill();

    // Specular Reflection Curve along the top half
    const specGrad = ctx.createLinearGradient(b.x, b.y, b.x + b.w, b.y + b.h * 0.4);
    specGrad.addColorStop(0, 'rgba(255, 255, 255, 0.9)');
    specGrad.addColorStop(0.35, 'rgba(255, 255, 255, 0.4)');
    specGrad.addColorStop(0.8, 'rgba(255, 255, 255, 0.0)');
    ctx.fillStyle = specGrad;
    ctx.fill();

    // Subtle Top-half Active Sensing Zone guideline
    ctx.beginPath();
    ctx.setLineDash([4, 6]);
    ctx.strokeStyle = 'rgba(0, 113, 227, 0.15)';
    ctx.lineWidth = 1;
    ctx.moveTo(b.x + 20, b.y + b.h * 0.55);
    ctx.lineTo(b.x + b.w - 20, b.y + b.h * 0.55);
    ctx.stroke();
    ctx.setLineDash([]);

    // Subdued Apple Logo in lower third
    this.drawAppleLogo(b.x + b.w / 2, b.y + b.h * 0.76, b.w * 0.08);

    // Subtle coordinate markings (normalized 0.0 to 1.0)
    ctx.fillStyle = 'rgba(120, 120, 130, 0.45)';
    ctx.font = '9px -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('ACTIVE MULTITOUCH SURFACE', b.x + b.w / 2, b.y + 24);

    ctx.restore();
  }

  drawAppleLogo(cx, cy, size) {
    const ctx = this.ctx;
    ctx.save();
    ctx.fillStyle = 'rgba(0, 0, 0, 0.16)';

    // Minimalist Apple logo silhouette
    ctx.beginPath();
    ctx.arc(cx - size * 0.22, cy, size * 0.42, 0, Math.PI * 2);
    ctx.arc(cx + size * 0.22, cy, size * 0.42, 0, Math.PI * 2);
    ctx.fill();

    // Leaf
    ctx.beginPath();
    ctx.ellipse(cx + size * 0.08, cy - size * 0.55, size * 0.14, size * 0.24, Math.PI / 4, 0, Math.PI * 2);
    ctx.fill();

    ctx.restore();
  }

  /**
   * Updates keyframe animations for simulated gesture playback
   */
  updateTourAnimation(time) {
    const elapsed = time - this.animationStartTime;
    const preset = this.presets[this.currentTourId];
    if (!preset) return;

    const progress = Math.min(1, elapsed / preset.duration);

    // Calculate fingertip positions based on gesture type
    switch (this.currentTourId) {
      case 'middle-click': {
        // 3 fingers in upper center, pressing down and releasing
        const press = Math.sin(progress * Math.PI);
        this.touches = [
          { normX: 0.32, normY: 0.72, size: 18 + press * 6, alpha: 0.85 + press * 0.15 },
          { normX: 0.50, normY: 0.75, size: 19 + press * 6, alpha: 0.9 + press * 0.1 },
          { normX: 0.68, normY: 0.72, size: 18 + press * 6, alpha: 0.85 + press * 0.15 }
        ];
        break;
      }
      case 'tip-tap': {
        // Left finger rests, right finger taps down
        const tap = Math.sin(progress * Math.PI);
        this.touches = [
          { normX: 0.38, normY: 0.72, size: 18, alpha: 0.75 },
          { normX: 0.62, normY: 0.72 - tap * 0.04, size: 14 + tap * 9, alpha: 0.3 + tap * 0.7 }
        ];
        break;
      }
      case 'pinch': {
        // 2 fingers moving inward then outward
        const factor = Math.sin(progress * Math.PI);
        const gap = 0.28 - factor * 0.14;
        this.touches = [
          { normX: 0.50 - gap, normY: 0.70, size: 18, alpha: 0.9 },
          { normX: 0.50 + gap, normY: 0.70, size: 18, alpha: 0.9 }
        ];
        break;
      }
      case 'swipe': {
        // 2 fingers gliding horizontally
        const offset = (Math.sin(progress * Math.PI * 2 - Math.PI / 2) + 1) / 2 * 0.26 - 0.13;
        this.touches = [
          { normX: 0.44 + offset, normY: 0.72, size: 18, alpha: 0.9 },
          { normX: 0.56 + offset, normY: 0.72, size: 18, alpha: 0.9 }
        ];
        break;
      }
      case 'four-tap': {
        // 4 fingers tapping simultaneously
        const tap = Math.sin(progress * Math.PI);
        this.touches = [
          { normX: 0.22, normY: 0.68, size: 16 + tap * 5, alpha: 0.8 + tap * 0.2 },
          { normX: 0.40, normY: 0.74, size: 18 + tap * 5, alpha: 0.9 + tap * 0.1 },
          { normX: 0.60, normY: 0.74, size: 18 + tap * 5, alpha: 0.9 + tap * 0.1 },
          { normX: 0.78, normY: 0.68, size: 16 + tap * 5, alpha: 0.8 + tap * 0.2 }
        ];
        break;
      }
    }

    // Telemetry updates during tour
    if (this.dom.telemetryContacts) {
      this.dom.telemetryContacts.textContent = `${this.touches.length} fingers`;
    }
    if (this.dom.telemetryPhase) {
      this.dom.telemetryPhase.textContent = progress < 0.8 ? 'Recognizing' : 'Triggered';
    }
    if (this.touches.length > 0 && this.dom.telemetryCoords) {
      this.dom.telemetryCoords.textContent = `${this.touches[0].normX.toFixed(2)}, ${this.touches[0].normY.toFixed(2)}`;
    }
    if (this.dom.telemetryForce) {
      this.dom.telemetryForce.textContent = `${(18.2 + Math.sin(progress * Math.PI) * 4).toFixed(1)} pt²`;
    }

    // Restart gesture animation loop if in single preview mode
    if (progress >= 1 && !this.autoTourActive) {
      this.animationStartTime = time;
    }
  }

  drawParticles() {
    const ctx = this.ctx;
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.alpha -= 0.025;
      p.size *= 0.96;

      if (p.alpha <= 0) {
        this.particles.splice(i, 1);
        continue;
      }

      ctx.save();
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(56, 189, 248, ${p.alpha * 0.6})`;
      ctx.fill();
      ctx.restore();
    }
  }

  /**
   * Draws glowing capacitive touch contact circles matching TouchPoint model
   */
  drawTouchPoints(time) {
    const ctx = this.ctx;

    this.touches.forEach((t, idx) => {
      const pt = this.normalizedToCanvas(t.normX, t.normY);
      const radius = t.size || 20;

      ctx.save();

      // 1. Pulsing Outer Capacitive Field Glow
      const pulse = Math.sin(time * 0.008 + idx) * 4;
      const glowGrad = ctx.createRadialGradient(pt.x, pt.y, radius * 0.2, pt.x, pt.y, radius * 2.2 + pulse);
      glowGrad.addColorStop(0, 'rgba(56, 189, 248, 0.45)');
      glowGrad.addColorStop(0.5, 'rgba(0, 113, 227, 0.25)');
      glowGrad.addColorStop(1, 'rgba(0, 113, 227, 0)');

      ctx.beginPath();
      ctx.arc(pt.x, pt.y, radius * 2.2 + pulse, 0, Math.PI * 2);
      ctx.fillStyle = glowGrad;
      ctx.fill();

      // 2. Concentric Capacitive Sensing Ring
      ctx.beginPath();
      ctx.arc(pt.x, pt.y, radius + 2, 0, Math.PI * 2);
      ctx.strokeStyle = 'rgba(56, 189, 248, 0.85)';
      ctx.lineWidth = 1.5;
      ctx.stroke();

      // 3. Core Contact Point
      const coreGrad = ctx.createRadialGradient(pt.x - 2, pt.y - 2, 1, pt.x, pt.y, radius);
      coreGrad.addColorStop(0, '#ffffff');
      coreGrad.addColorStop(0.4, '#38bdf8');
      coreGrad.addColorStop(1, '#0071e3');

      ctx.beginPath();
      ctx.arc(pt.x, pt.y, radius, 0, Math.PI * 2);
      ctx.fillStyle = coreGrad;
      ctx.fill();

      // 4. Normalized Coordinate Tooltip
      ctx.font = '10px -apple-system, BlinkMacSystemFont, "SF Mono", monospace';
      ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
      ctx.textAlign = 'center';
      ctx.fillText(`${t.normX.toFixed(2)}, ${t.normY.toFixed(2)}`, pt.x, pt.y + 3);

      ctx.restore();
    });
  }
}

// Instantiate simulator once DOM is loaded
window.addEventListener('DOMContentLoaded', () => {
  window.simulator = new MagicMouseSimulator('mouse-canvas');
});
