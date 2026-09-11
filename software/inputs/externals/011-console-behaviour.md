# Console Behaviour

Normal operation should provide useful progress without dumping internal selection/debug state.

Do not print project discovery/selection diagnostics such as discovered/selected project lists.

Do print concise progress messages that explain current work, such as building projects and source/binary package phases.

Keep raw R and Quarto subprocess output visible. It contains useful diagnostic and build information.

Errors and anomalous situations should remain explicit.
