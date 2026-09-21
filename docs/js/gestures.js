/**
 * MagicTouch — Gesture Matrix & Live Filter Engine
 * Handles real-time category filtering, instant keyword search, and dynamic card rendering.
 */

class GestureMatrix {
  constructor() {
    this.grid = document.getElementById('gesture-grid');
    this.countBadge = document.getElementById('gesture-count-badge');
    this.searchInput = document.getElementById('gesture-search-input');
    this.clearSearchBtn = document.getElementById('clear-search-btn');
    this.filterButtons = document.querySelectorAll('.matrix-filter-btn');

    this.activeFilter = 'all';
    this.searchQuery = '';

    if (!this.grid || !window.GESTURES_DATA) return;

    this.init();
  }

  init() {
    this.bindFilters();
    this.bindSearch();
    this.render();
  }

  bindFilters() {
    this.filterButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        this.filterButtons.forEach(b => b.classList.remove('active', 'border-blue-500/60', 'text-blue-400'));
        btn.classList.add('active', 'border-blue-500/60', 'text-blue-400');
        this.activeFilter = btn.getAttribute('data-filter') || 'all';
        this.render();
      });
    });
  }

  bindSearch() {
    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => {
        this.searchQuery = e.target.value.toLowerCase().trim();
        if (this.clearSearchBtn) {
          if (this.searchQuery.length > 0) {
            this.clearSearchBtn.classList.remove('hidden');
          } else {
            this.clearSearchBtn.classList.add('hidden');
          }
        }
        this.render();
      });
    }

    if (this.clearSearchBtn) {
      this.clearSearchBtn.addEventListener('click', () => {
        if (this.searchInput) this.searchInput.value = '';
        this.searchQuery = '';
        this.clearSearchBtn.classList.add('hidden');
        this.render();
      });
    }
  }

  filterData() {
    return window.GESTURES_DATA.filter(item => {
      // 1. Category / Finger filter
      let matchesFilter = true;
      if (this.activeFilter === '1-finger') {
        matchesFilter = item.fingerCount === 1;
      } else if (this.activeFilter === '2-finger') {
        matchesFilter = item.fingerCount === 2;
      } else if (this.activeFilter === '3-finger') {
        matchesFilter = item.fingerCount === 3;
      } else if (this.activeFilter === '4-finger') {
        matchesFilter = item.fingerCount === 4;
      } else if (this.activeFilter === 'tap') {
        matchesFilter = item.category === 'tap' || item.category === 'tip-tap';
      } else if (this.activeFilter === 'swipe') {
        matchesFilter = item.category === 'swipe';
      } else if (this.activeFilter === 'pinch') {
        matchesFilter = item.category === 'pinch';
      }

      if (!matchesFilter) return false;

      // 2. Keyword search
      if (!this.searchQuery) return true;

      return (
        item.name.toLowerCase().includes(this.searchQuery) ||
        item.description.toLowerCase().includes(this.searchQuery) ||
        item.defaultAction.toLowerCase().includes(this.searchQuery) ||
        item.category.toLowerCase().includes(this.searchQuery) ||
        `${item.fingerCount} finger`.includes(this.searchQuery)
      );
    });
  }

  render() {
    const filtered = this.filterData();
    const total = window.GESTURES_DATA.length;

    // Update counter badge
    if (this.countBadge) {
      this.countBadge.textContent = `Showing ${filtered.length} of ${total} Gestures`;
    }

    // Empty state
    if (filtered.length === 0) {
      this.grid.innerHTML = `
        <div class="col-span-full py-16 text-center">
          <div class="text-3xl mb-3">🔍</div>
          <div class="text-lg font-semibold text-white mb-1">No matching gestures found</div>
          <div class="text-sm text-[#86868b]">Try clearing your search query or selecting a different filter.</div>
        </div>
      `;
      return;
    }

    // Generate Cards
    const html = filtered.map(item => {
      const actionBadgeColor = this.getActionBadgeColor(item.actionType);
      const actionTypeLabel = this.getActionTypeLabel(item.actionType);

      return `
        <div class="glass-panel rounded-xl p-4 sm:p-5 flex flex-col justify-between hover:border-white/20 transition-all group">
          <div>
            <div class="flex items-center justify-between mb-3">
              <span class="text-xl p-2 rounded-lg bg-white/5 border border-white/10 group-hover:scale-110 transition-transform">
                ${item.icon}
              </span>
              <span class="px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-white/5 text-[#98989f] border border-white/10">
                ${item.fingerCount} ${item.fingerCount === 1 ? 'Finger' : 'Fingers'}
              </span>
            </div>

            <h3 class="text-base font-bold text-white mb-1 group-hover:text-blue-400 transition-colors">
              ${item.name}
            </h3>

            <p class="text-xs text-[#86868b] leading-relaxed mb-4">
              ${item.description}
            </p>
          </div>

          <div class="pt-3 border-t border-white/5 flex items-center justify-between gap-2">
            <div class="flex items-center space-x-1.5 min-w-0">
              <span class="w-1.5 h-1.5 rounded-full ${actionBadgeColor.dot}"></span>
              <span class="text-xs font-semibold text-white/90 truncate" title="${item.defaultAction}">
                ${item.defaultAction}
              </span>
            </div>
            <span class="px-2 py-0.5 rounded text-[10px] font-mono shrink-0 ${actionBadgeColor.pill}">
              ${actionTypeLabel}
            </span>
          </div>
        </div>
      `;
    }).join('');

    this.grid.innerHTML = html;
  }

  getActionBadgeColor(type) {
    switch (type) {
      case 'mouse':
        return { dot: 'bg-blue-400', pill: 'bg-blue-500/10 text-blue-300 border border-blue-500/20' };
      case 'hotkey':
        return { dot: 'bg-purple-400', pill: 'bg-purple-500/10 text-purple-300 border border-purple-500/20' };
      case 'system':
        return { dot: 'bg-cyan-400', pill: 'bg-cyan-500/10 text-cyan-300 border border-cyan-500/20' };
      case 'script':
        return { dot: 'bg-amber-400', pill: 'bg-amber-500/10 text-amber-300 border border-amber-500/20' };
      default:
        return { dot: 'bg-blue-400', pill: 'bg-blue-500/10 text-blue-300 border border-blue-500/20' };
    }
  }

  getActionTypeLabel(type) {
    switch (type) {
      case 'mouse': return 'MOUSE';
      case 'hotkey': return 'HOTKEY';
      case 'system': return 'SYSTEM';
      case 'script': return 'SCRIPT';
      default: return 'ACTION';
    }
  }
}

// Instantiate on DOM load
document.addEventListener('DOMContentLoaded', () => {
  window.gestureMatrix = new GestureMatrix();
});
