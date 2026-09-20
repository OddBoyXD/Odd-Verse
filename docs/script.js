/* Odd Verse landing — progressive enhancement. No frameworks. */
(function () {
  "use strict";

  var REPO = "OddBoyXD/Odd-Verse";
  var API = "https://api.github.com/repos/" + REPO + "/releases/latest";
  var FALLBACK = {
    tag: "v1.0.0",
    date: "September 2026",
    online: {
      name: "OddVerse-v1.0.0-arm64-v8a.apk",
      url: "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-arm64-v8a.apk",
      size: 17987623
    },
    offline: {
      name: "OddVerse-v1.0.0-universal.apk",
      url: "https://github.com/OddBoyXD/Odd-Verse/releases/latest/download/OddVerse-v1.0.0-universal.apk",
      size: 38500000
    }
  };

  function setText(id, value) {
    var el = document.getElementById(id);
    if (el && value) el.textContent = value;
  }

  function applyRelease(rel) {
    var tag = "v1.0.0";
    setText("announce-version", tag);
    setText("hero-version", tag);
    setText("inline-version", tag);
    if (rel.date) setText("release-date", "Released " + rel.date);

    var on = document.getElementById("online-btn");
    var off = document.getElementById("offline-btn");
    if (on) on.href = FALLBACK.online.url;
    if (off) off.href = FALLBACK.offline.url;

    var hero = document.getElementById("hero-download");
    if (hero) hero.href = FALLBACK.online.url;
    var cta = document.getElementById("cta-download");
    if (cta) cta.href = FALLBACK.online.url;
  }

  // Tabs
  function setupTabs() {
    var tablist = document.querySelector('[role="tablist"]');
    if (!tablist) return;
    var tabs = Array.from(tablist.querySelectorAll('[role="tab"]'));
    var panels = tabs.map(function (t) {
      return document.getElementById(t.getAttribute("aria-controls"));
    });

    function activate(tab, focus) {
      tabs.forEach(function (t, i) {
        var active = t === tab;
        t.classList.toggle("is-active", active);
        t.setAttribute("aria-selected", active ? "true" : "false");
        t.setAttribute("tabindex", active ? "0" : "-1");
        if (panels[i]) {
          panels[i].classList.toggle("is-active", active);
          panels[i].hidden = !active;
        }
      });
      if (focus) tab.focus();
    }

    tablist.addEventListener("click", function (e) {
      var tab = e.target.closest('[role="tab"]');
      if (tab) activate(tab, false);
    });

    tablist.addEventListener("keydown", function (e) {
      var idx = tabs.indexOf(document.activeElement);
      if (idx === -1) return;
      if (e.key === "ArrowRight") {
        e.preventDefault();
        activate(tabs[(idx + 1) % tabs.length], true);
      } else if (e.key === "ArrowLeft") {
        e.preventDefault();
        activate(tabs[(idx - 1 + tabs.length) % tabs.length], true);
      }
    });
  }

  // Mobile navigation menu
  function setupMenu() {
    var btn = document.getElementById("menu-btn");
    var menu = document.getElementById("mobile-menu");
    if (!btn || !menu) return;

    btn.addEventListener("click", function () {
      var open = btn.getAttribute("aria-expanded") === "true";
      btn.setAttribute("aria-expanded", String(!open));
      menu.hidden = open;
    });

    menu.addEventListener("click", function (e) {
      if (e.target.tagName === "A") {
        btn.setAttribute("aria-expanded", "false");
        menu.hidden = true;
      }
    });
  }

  // Init
  document.addEventListener("DOMContentLoaded", function () {
    applyRelease(FALLBACK);
    setupTabs();
    setupMenu();
  });
})();
