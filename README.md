# GGDIdentityOverlay Final Safe

Target profile:
- Bundle ID: com.seayoo.ggd
- Game version: 1.1.13
- Architecture: arm64
- Minimum iOS: 18.0

This build intentionally uses one Objective-C++ source file (`GGDFinal.mm`) so the runtime ABI and UI declarations stay in one compilation unit. The constructor only schedules UI installation. IL2CPP resolution and managed-object access are delayed until the app is active, the UnityFramework image is loaded, and the IL2CPP domain is available.

The overlay is touch-through: only its own floating button and panel accept touches. Markers do not accept touches.

Features in this build:
- load indicator and diagnostic panel
- version guard for com.seayoo.ggd / 1.1.13
- delayed UnityFramework + IL2CPP resolution
- bounded runtime type discovery for a player collection
- name/role probing through fields and one-level nested info objects
- enum role-name resolution when the runtime exposes enum metadata
- optional Unity Camera / Transform screen-position probing
- colored role markers (Duck=red, Goose=green, Neutral=yellow, other/purple, unknown=gray)

The code does not hardcode native offsets from the old plugin. It uses IL2CPP exported APIs and runtime metadata only. The numeric role-ID case remains explicit when the game does not expose a usable enum name.
