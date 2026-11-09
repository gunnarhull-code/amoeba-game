Status: resolved
Type: task
Blocked by: 01

## Question

Once the engine is chosen ([Confirm engine & tooling choice](01-engine-tooling-choice.md)), scaffold an empty, runnable project skeleton (folder structure for scenes/scripts/assets, a boot scene/window, whether to initialize git now) so the core-loop prototype (ticket 11) has somewhere to start.

## Answer

Project lives in `game/` at the repo root (project.godot, main.tscn, main.gd). Run it with `godot --path game`. Git was already initialized.
