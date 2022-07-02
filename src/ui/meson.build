blueprints_src = [
  'settings.blp',
  'encryption_page.blp',
  'encryption_passphrase.blp',
]

# Workaround for valac, see jwestman/blueprint-compiler#18, thanks
# to @fabrixxm

blueprints_ui = []
blueprints_vala = []
foreach b : blueprints_src
  blueprints_ui += b.replace('.blp', '.ui')
  blueprints_vala += b + '.vala'
endforeach

blueprints = custom_target('blueprints',
  input: blueprints_src,
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

blueprints_hack = custom_target('blueprints_hack',
  input: blueprints,
  output: blueprints_vala,
  command: [find_program('touch'), '@OUTPUT@'],
)
