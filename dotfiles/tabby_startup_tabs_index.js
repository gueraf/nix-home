'use strict';

const core = require('@angular/core');
const tabbyCore = require('tabby-core');

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
  constructor(app, zone) {
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
  }
}
StartupTabsModule.ctorParameters = () => [
  { type: tabbyCore.AppService },
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
