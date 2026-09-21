/**
 * MagicTouch Website — Main Application Script
 * Handles dynamic GitHub Releases data, copy-to-clipboard, and responsive navigation.
 */

document.addEventListener('DOMContentLoaded', () => {
  initReleaseData();
  initClipboard();
  initMobileMenu();
  initSimulatorControls();
});

/**
 * Fallback values in case of network unavailability or GitHub API rate limiting (HTTP 403)
 */
const DEFAULT_VERSION = 'v0.1.1';
const DEFAULT_DMG_URL = 'https://github.com/namikemen/magictouch/releases/latest/download/MagicTouch.dmg';
const GITHUB_REPO = 'namikemen/magictouch';

/**
 * Asynchronously query the GitHub Releases API to update version numbers and asset sizes.
 */
async function initReleaseData() {
  const versionBadge = document.getElementById('badge-version-text');
  const downloadSubtext = document.getElementById('download-subtext');
  const downloadBtn = document.getElementById('primary-download-btn');

  try {
    const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases/latest`, {
      headers: { 'Accept': 'application/vnd.github.v3+json' }
    });

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.status}`);
    }

    const data = await response.json();
    const tagName = data.tag_name || DEFAULT_VERSION;
    
    // Find DMG asset for size computation
    let sizeText = 'DMG';
    let dmgAssetUrl = DEFAULT_DMG_URL;

    if (data.assets && Array.isArray(data.assets)) {
      const dmgAsset = data.assets.find(a => a.name && a.name.endsWith('.dmg'));
      if (dmgAsset) {
        if (dmgAsset.browser_download_url) {
          dmgAssetUrl = dmgAsset.browser_download_url;
        }
        if (dmgAsset.size) {
          const mb = (dmgAsset.size / (1024 * 1024)).toFixed(1);
          sizeText = `${mb} MB DMG`;
        }
      }
    }

    // Update DOM elements if present
    if (versionBadge) {
      versionBadge.textContent = `${tagName} Released`;
    }
    if (downloadSubtext) {
      downloadSubtext.textContent = `${tagName} Universal • ${sizeText}`;
    }
    if (downloadBtn) {
      downloadBtn.href = dmgAssetUrl;
    }
  } catch (err) {
    // Graceful fallback to static defaults
    console.warn('Notice: Using default release metadata:', err.message);
    if (versionBadge) {
      versionBadge.textContent = `${DEFAULT_VERSION} Released`;
    }
    if (downloadSubtext) {
      downloadSubtext.textContent = `${DEFAULT_VERSION} Universal • DMG`;
    }
  }
}

/**
 * Handle one-click copy to clipboard for developer terminal commands.
 */
function initClipboard() {
  const copyBtn = document.getElementById('copy-command-btn');
  const commandText = document.getElementById('terminal-command-text');
  const copyIcon = document.getElementById('copy-icon');
  const copyFeedback = document.getElementById('copy-feedback');

  if (!copyBtn || !commandText) return;

  copyBtn.addEventListener('click', async () => {
    const textToCopy = commandText.textContent.trim();
    try {
      await navigator.clipboard.writeText(textToCopy);

      // Show copied feedback
      if (copyIcon) copyIcon.classList.add('hidden');
      if (copyFeedback) copyFeedback.classList.remove('hidden');

      setTimeout(() => {
        if (copyFeedback) copyFeedback.classList.add('hidden');
        if (copyIcon) copyIcon.classList.remove('hidden');
      }, 2400);
    } catch (e) {
      console.error('Failed to copy text: ', e);
    }
  });
}

/**
 * Handle mobile slide-down drawer open/close and link clicks.
 */
function initMobileMenu() {
  const menuBtn = document.getElementById('mobile-menu-btn');
  const mobileMenu = document.getElementById('mobile-menu');

  if (!menuBtn || !mobileMenu) return;

  menuBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    mobileMenu.classList.toggle('hidden');
  });

  // Close menu when clicking a link inside it
  const mobileNavLinks = mobileMenu.querySelectorAll('.mobile-nav-link');
  mobileNavLinks.forEach(link => {
    link.addEventListener('click', () => {
      mobileMenu.classList.add('hidden');
    });
  });

  // Close menu when clicking outside
  document.addEventListener('click', (e) => {
    if (!mobileMenu.contains(e.target) && !menuBtn.contains(e.target)) {
      mobileMenu.classList.add('hidden');
    }
  });
}

/**
 * Wire up interactive controls for the Magic Mouse simulator, preset bar, and audio toggle.
 */
function initSimulatorControls() {
  // Preset buttons
  const presetButtons = document.querySelectorAll('.preset-btn');
  presetButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const gesture = btn.getAttribute('data-gesture');
      if (window.simulator && gesture) {
        window.simulator.stopAutoTour();
        window.simulator.playGesture(gesture, true);
      }
    });
  });

  // Auto-tour button
  const autoTourBtn = document.getElementById('auto-tour-btn');
  if (autoTourBtn) {
    autoTourBtn.addEventListener('click', () => {
      if (window.simulator) {
        window.simulator.toggleAutoTour();
      }
    });
  }

  // Sound haptic toggle button
  const soundBtn = document.getElementById('sound-toggle-btn');
  const soundIcon = document.getElementById('sound-icon');
  const soundLabel = document.getElementById('sound-label');

  if (soundBtn && window.hapticAudio) {
    window.hapticAudio.onMuteChange((isMuted) => {
      if (soundIcon) soundIcon.textContent = isMuted ? '🔇' : '🔊';
      if (soundLabel) soundLabel.textContent = isMuted ? 'Audio: Off' : 'Audio: On';
      if (isMuted) {
        soundBtn.classList.remove('border-blue-500/50', 'text-blue-400', 'bg-blue-500/10');
      } else {
        soundBtn.classList.add('border-blue-500/50', 'text-blue-400', 'bg-blue-500/10');
      }
    });

    soundBtn.addEventListener('click', () => {
      window.hapticAudio.toggleMute();
    });
  }
}

