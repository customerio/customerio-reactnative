# React Native iOS scene push E2E

`run_scene_push.sh` generates the scene-capable React Native 0.88 host that the
wrapper supports, installs the current wrapper package into it, and runs
black-box Maestro notification-tap tests from terminated and warm app states.
The JavaScript listener is registered before `CustomerIO.initialize`, and each
assertion requires the exact Customer.io destination to reach React Native
Linking.

The scene host installs the native bridge before React Native starts. This is
what lets the wrapper buffer a terminated-app notification URL until the
JavaScript listener and `CustomerIO.initialize` are ready.

The checked-in payload uses `simctl push` so the destination is deterministic
and does not require changing a shared Customer.io campaign. It validates the
client routing path, not backend `sent`, `delivered`, or `opened` metrics. Those
metrics remain a separate remote E2E lane using a real workspace and APNs.

Run with Maestro 2.8.0 and a booted iPhone simulator:

```bash
.maestro/run_scene_push.sh
```
