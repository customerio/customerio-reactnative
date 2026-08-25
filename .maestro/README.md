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
metrics are covered separately by `run_remote_push.sh`, which uses the existing
APN sample, its notification service extension, a real workspace, and APNs.

Run with Maestro 2.6.0 and a booted iPhone simulator:

```bash
.maestro/run_scene_push.sh
```

Run the remote APNs loop after configuring the APN sample's ignored
`example/src/env.ts` file. The runner gives the notification service extension
the same APN workspace key for the build and restores its ignored config when
the run ends. Put the `Mobile SDK Maestro E2E` App API key from the same
`Mobile: React Native` workspace in `.maestro/.env` as shown by
`.maestro/.env.example`, then run:

```bash
.maestro/run_remote_push.sh
```

The remote flow identifies a fresh customer in the `Mobile: React Native`
workspace, sends the `jason` event used by its existing `push_notif_test`
automation (campaign 15), taps the real system notification, and requires
matching backend `delivered` and `opened` metrics. It is intentionally local or
trusted-CI only; pull requests do not receive the required workspace credential.
