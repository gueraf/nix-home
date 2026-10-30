'use strict';

const childProcess = require('child_process');
const fs = require('fs');
const core = require('@angular/core');
const tabbyCore = require('tabby-core');

const WAYLAND_OPEN_SCRIPT = `
import ctypes, os, subprocess, sys
url = sys.argv[1]
try:
    if os.environ.get("WAYLAND_DISPLAY"):
        os.environ["GDK_BACKEND"] = "wayland"
        gdk = ctypes.CDLL("libgdk-3.so.0")
        gio = ctypes.CDLL("libgio-2.0.so.0")
        wl = ctypes.CDLL("libwayland-client.so.0")
        gdk.gdk_init(ctypes.byref(ctypes.c_int(0)), None)
        gdk.gdk_display_get_default.restype = ctypes.c_void_p
        d = gdk.gdk_display_get_default()
        if d:
            ctypes.c_void_p.from_address(d + 0x160).value = 0
            gdk.gdk_display_get_app_launch_context.argtypes = [ctypes.c_void_p]
            gdk.gdk_display_get_app_launch_context.restype = ctypes.c_void_p
            ctx = gdk.gdk_display_get_app_launch_context(d)
            gio.g_app_launch_context_get_startup_notify_id.argtypes = [
                ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p
            ]
            gio.g_app_launch_context_get_startup_notify_id.restype = ctypes.c_char_p
            token_bytes = gio.g_app_launch_context_get_startup_notify_id(ctx, None, None)
            if token_bytes:
                token = token_bytes.decode("utf-8", errors="ignore")
                os.environ["XDG_ACTIVATION_TOKEN"] = token
                os.environ["DESKTOP_STARTUP_ID"] = token
                gdk.gdk_wayland_display_get_wl_display.argtypes = [ctypes.c_void_p]
                gdk.gdk_wayland_display_get_wl_display.restype = ctypes.c_void_p
                wl_d = gdk.gdk_wayland_display_get_wl_display(d)
                if wl_d:
                    wl.wl_display_roundtrip.argtypes = [ctypes.c_void_p]
                    wl.wl_display_roundtrip(wl_d)
except Exception:
    pass
subprocess.Popen(["gio", "open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
`;

class StartupTabsConfigProvider extends tabbyCore.ConfigProvider {
  constructor() {
    super();
    this.defaults = {
      startupProfiles: [],
    };
    this.platformDefaults = {};
  }
}
StartupTabsConfigProvider = core.Injectable()(StartupTabsConfigProvider);

class StartupTabsCLIHandler extends tabbyCore.CLIHandler {
  constructor(app, config, profiles, log) {
    super();
    this.app = app;
    this.config = config;
    this.profiles = profiles;
    this.logger = log.create('startupTabs');
    this.firstMatchOnly = true;
    this.priority = -500;
  }

  async handle(event) {
    if (event.secondInstance) {
      return false;
    }
    const startupProfiles = this.config.store.startupProfiles || [];
    if (!startupProfiles.length) {
      return false;
    }
    this.app.ready$.subscribe(async () => {
      const allProfiles = await this.profiles.getProfiles();
      const openNames = new Set(this.app.tabs.map(t => t.title || t.customTitle));
      for (const idOrName of startupProfiles) {
        const profile = allProfiles.find(p => p.id === idOrName || p.name === idOrName);
        if (profile && !openNames.has(profile.name)) {
          this.logger.info(`Opening startup tab: ${profile.name} (${profile.id})`);
          await this.profiles.openNewTabForProfile(profile);
          openNames.add(profile.name);
        }
      }
      if (this.app.tabs.length > 0) {
        this.app.selectTab(this.app.tabs[0]);
      }
    });
    return true;
  }
}
StartupTabsCLIHandler.ctorParameters = () => [
  { type: tabbyCore.AppService },
  { type: tabbyCore.ConfigService },
  { type: tabbyCore.ProfilesService },
  { type: tabbyCore.LogService },
];
StartupTabsCLIHandler = core.Injectable()(StartupTabsCLIHandler);

class StartupTabsModule {
  constructor(app, config, platform, zone) {
    window.addEventListener(
      'keydown',
      event => {
        if (event.ctrlKey && !event.shiftKey && !event.altKey && !event.metaKey) {
          if (event.key === 'PageDown' || event.code === 'PageDown' || event.key === 'Next') {
            event.preventDefault();
            event.stopPropagation();
            zone.run(() => app.nextTab());
          } else if (event.key === 'PageUp' || event.code === 'PageUp' || event.key === 'Prior') {
            event.preventDefault();
            event.stopPropagation();
            zone.run(() => app.previousTab());
          }
        }
      },
      true
    );

    let mouseDownPos = null;
    let dragMoved = false;
    let lastDragTime = 0;

    window.addEventListener(
      'mousedown',
      event => {
        if (event.button === 0) {
          mouseDownPos = { x: event.clientX, y: event.clientY };
          dragMoved = false;
        }
      },
      true
    );

    window.addEventListener(
      'mousemove',
      event => {
        if (mouseDownPos && (event.buttons & 1)) {
          if (Math.hypot(event.clientX - mouseDownPos.x, event.clientY - mouseDownPos.y) > 4) {
            dragMoved = true;
            lastDragTime = Date.now();
          }
        }
      },
      true
    );

    window.addEventListener(
      'mouseup',
      event => {
        if (mouseDownPos && event.button === 0) {
          if (Math.hypot(event.clientX - mouseDownPos.x, event.clientY - mouseDownPos.y) > 4) {
            dragMoved = true;
            lastDragTime = Date.now();
          }
          mouseDownPos = null;
        }
      },
      true
    );

    if (platform && typeof platform.openExternal === 'function') {
      const origOpenExternal = platform.openExternal.bind(platform);
      platform.openExternal = url => {
        if (dragMoved && Date.now() - lastDragTime < 250) {
          return;
        }
        if (process.platform === 'linux' && typeof url === 'string' && url.length > 0) {
          try {
            const env = Object.assign({}, process.env);
            delete env.LD_LIBRARY_PATH;
            const child = childProcess.spawn('/usr/bin/python3', ['-c', WAYLAND_OPEN_SCRIPT, url], {
              env,
              detached: true,
              stdio: 'ignore',
            });
            child.unref();
            return;
          } catch (err) {
            // Fall through to default handler
          }
        }
        return origOpenExternal(url);
      };
    }

    const reconfigureAllTabs = () => {
      for (const tab of app.tabs || []) {
        const innerTabs = typeof tab.getAllTabs === 'function' ? tab.getAllTabs() : [tab];
        for (const innerTab of innerTabs) {
          if (typeof innerTab.configure === 'function') {
            innerTab.configure();
          }
        }
      }
    };

    if (config && config.changed$) {
      config.changed$.subscribe(() => {
        zone.run(() => reconfigureAllTabs());
      });
    }

    if (platform && typeof platform.getConfigPath === 'function' && config) {
      const configPath = platform.getConfigPath();
      if (configPath) {
        fs.watchFile(configPath, { interval: 1000 }, async (curr, prev) => {
          if (curr.mtimeMs !== prev.mtimeMs) {
            try {
              await config.load();
              config.emitChange();
              zone.run(() => reconfigureAllTabs());
            } catch (err) {
              // Ignore transient read errors while file is being written
            }
          }
        });
      }
    }
  }
}
StartupTabsModule.ctorParameters = () => [
  { type: tabbyCore.AppService },
  { type: tabbyCore.ConfigService },
  { type: tabbyCore.PlatformService },
  { type: core.NgZone },
];
StartupTabsModule = core.NgModule({
  providers: [
    { provide: tabbyCore.ConfigProvider, useClass: StartupTabsConfigProvider, multi: true },
    { provide: tabbyCore.CLIHandler, useClass: StartupTabsCLIHandler, multi: true },
  ],
})(StartupTabsModule);

module.exports = {
  default: StartupTabsModule,
};
