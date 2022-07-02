subdir('ui')

droidian_settings_sources = [
  'main.vala',
  'encryption_service.vala',
  'encryption_page.vala',
  'window.vala',
]

droidian_settings_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.6'),
  dependency('libadwaita-1', version: '>= 1.1'),
]

gnome = import('gnome')

droidian_settings_sources += gnome.compile_resources('droidian_settings-resources',
  'droidian_settings.gresource.xml',
  dependencies: blueprints,
  c_name: 'droidian_settings'
)

executable('droidian-settings',
  [
    blueprints_hack, # hack
    droidian_settings_sources,
  ],
  vala_args: [
    '--target-glib=2.50',
    '--gresourcesdir=src/ui/', # Hack
  ],
  dependencies: droidian_settings_deps,
  install: true,
)
