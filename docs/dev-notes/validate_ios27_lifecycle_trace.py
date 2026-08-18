#!/usr/bin/env python3
"""Validate an iOS 27 lifecycle manifest and its prefixed NDJSON streams."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

try:
    from jsonschema import Draft202012Validator, FormatChecker
    from referencing import Registry, Resource
except ImportError as error:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: python3 -m pip install 'jsonschema[format]>=4.18,<5'"
    ) from error


PREFIX = "CIO-LIFECYCLE-TRACE "
ALIAS_KINDS = ("occurrence", "delivery", "request", "scene", "url", "closure")
MAX_ALIASES_PER_KIND = 256
STABLE_RECORD_FIELDS = (
    "manifest_id", "run_id", "stream_id", "process_id", "integration", "runtime",
    "provider", "scenario", "evidence_level",
)

REMOTE_SCENARIOS = {"push-foreground", "push-tap-warm", "push-tap-cold"}
LOCAL_SCENARIOS = {
    "local-notification-foreground", "local-notification-tap-warm", "local-notification-tap-cold"
}
CUSTOM_URL_SCENARIOS = {"custom-url-warm", "custom-url-cold"}
UNIVERSAL_LINK_SCENARIOS = {"universal-link-warm", "universal-link-cold"}
URL_SCENARIOS = CUSTOM_URL_SCENARIOS.union(UNIVERSAL_LINK_SCENARIOS)
QUICK_ACTION_SCENARIOS = {"quick-action-warm", "quick-action-cold"}
LIVE_ACTIVITY_SCENARIOS = {"live-activity-tap-warm", "live-activity-tap-cold"}
REGISTRATION_SCENARIOS = {"token-registration", "registration-failure"}
NATIVE_ONLY_SINGLE_STREAM_SCENARIOS = {
    "token-registration", "registration-failure", "background-fetch", "notification-settings",
}
COLD_START_SCENARIOS = {
    "icon-cold-launch", "push-tap-cold", "local-notification-tap-cold",
    "custom-url-cold", "universal-link-cold", "quick-action-cold",
    "live-activity-tap-cold",
}

HOST_TOPOLOGIES = {"app-delegate-only", "ui-scene", "swiftui-lifecycle"}
APP_DELEGATE_UI_CALLBACKS = {
    "application.did-become-active", "application.will-resign-active",
    "application.did-enter-background", "application.will-enter-foreground",
    "application.open-url", "application.continue-user-activity",
    "application.perform-quick-action",
}
SCENE_CALLBACK_PREFIXES = ("scene.", "uikit.scene-", "flutter.scene.")
SWIFTUI_CALLBACKS = {"swiftui.on-open-url", "swiftui.scene-phase-change"}
SCENE_UI_SCENARIOS = (
    {"icon-cold-launch", "app-background-foreground"}
    .union(CUSTOM_URL_SCENARIOS)
    .union(UNIVERSAL_LINK_SCENARIOS)
    .union(QUICK_ACTION_SCENARIOS)
    .union(LIVE_ACTIVITY_SCENARIOS)
)

REMOTE_NOTIFICATION_CALLBACKS = {
    "application.did-receive-remote-notification",
    "flutter.application.did-receive-remote-notification-forwarded",
    "expo.subscriber.did-receive-remote-notification-forwarded",
}
NOTIFICATION_PRESENTATION_NATIVE = {
    "notification-center.will-present",
    "flutter.notification-center.will-present-forwarded",
    "expo.notification-center-manager.will-present-forwarded",
    "expo.notifications-emitter.notification-received-event-sent",
}
REMOTE_NOTIFICATION_FOREGROUND_NATIVE = (
    REMOTE_NOTIFICATION_CALLBACKS.union(NOTIFICATION_PRESENTATION_NATIVE)
)
LOCAL_NOTIFICATION_FOREGROUND_NATIVE = NOTIFICATION_PRESENTATION_NATIVE
NOTIFICATION_TAP_NATIVE = {
    "notification-center.did-receive-response", "flutter.notification-response",
    "flutter.notification-center.did-receive-response-forwarded",
    "expo.notification-center-manager.did-receive-response-forwarded",
    "expo.notifications-emitter.notification-response-event-sent",
}
NOTIFICATION_COLD_PULL_NATIVE = {
    "expo.last-notification-response-pulled",
}
NOTIFICATION_TAP_COLD_NATIVE = NOTIFICATION_TAP_NATIVE.union(NOTIFICATION_COLD_PULL_NATIVE)
URL_NATIVE = {
    "application.open-url", "scene.open-url-contexts", "swiftui.on-open-url",
    "flutter.application.open-url-forwarded", "flutter.scene.open-url-contexts-forwarded",
    "expo.subscriber.open-url-forwarded",
    "host.route-url", "customerio.route-deep-link",
}
URL_COLD_NATIVE = URL_NATIVE.union({"scene.will-connect"})
USER_ACTIVITY_NATIVE = {
    "application.continue-user-activity", "scene.continue-user-activity",
    "flutter.application.continue-user-activity-forwarded",
    "flutter.scene.continue-user-activity-forwarded",
    "expo.subscriber.continue-user-activity-forwarded", "host.route-user-activity",
}
UNIVERSAL_LINK_NATIVE = USER_ACTIVITY_NATIVE.union({"swiftui.on-open-url"})
UNIVERSAL_LINK_COLD_NATIVE = UNIVERSAL_LINK_NATIVE.union({"scene.will-connect"})
QUICK_ACTION_NATIVE = {
    "application.perform-quick-action", "scene.perform-quick-action",
    "flutter.application.perform-quick-action-forwarded", "flutter.scene.perform-quick-action-forwarded",
    "expo.subscriber.perform-quick-action-forwarded", "host.route-quick-action",
}
QUICK_ACTION_COLD_NATIVE = QUICK_ACTION_NATIVE.union({"scene.will-connect"})
LAUNCH_NATIVE = {
    "application.did-finish-launching", "scene.will-connect",
    "uikit.application-did-finish-launching-notification", "uikit.scene-will-connect-notification",
    "flutter.application.did-finish-launching-forwarded", "flutter.implicit-engine-created",
    "expo.app-delegate-did-finish-launching-forwarded",
}
REGISTRATION_SUCCESS_NATIVE = {
    "application.did-register-for-remote-notifications", "apns.device-token-registered",
    "fcm.registration-token-refreshed", "flutter.application.did-register-for-remote-notifications-forwarded",
    "expo.subscriber.did-register-for-remote-notifications-forwarded",
    "customerio.register-device-token",
}
REGISTRATION_FAILURE_NATIVE = {
    "application.did-fail-to-register-for-remote-notifications",
    "apns.device-token-registration-failed",
    "flutter.application.did-fail-to-register-for-remote-notifications-forwarded",
    "expo.subscriber.did-fail-to-register-for-remote-notifications-forwarded",
}
BACKGROUND_FETCH_NATIVE = {
    "application.perform-background-fetch", "flutter.application.perform-background-fetch-forwarded",
    "expo.subscriber.perform-background-fetch-forwarded",
    "host.background-fetch-completion-result",
}
APP_STATE_NATIVE = {
    "application.did-become-active", "application.will-resign-active",
    "application.did-enter-background", "application.will-enter-foreground",
    "scene.did-become-active", "scene.will-resign-active", "scene.did-enter-background",
    "scene.will-enter-foreground", "swiftui.scene-phase-change",
    "uikit.application-did-become-active-notification",
    "uikit.application-will-resign-active-notification",
    "uikit.application-did-enter-background-notification",
    "uikit.application-will-enter-foreground-notification",
    "flutter.app-lifecycle-state", "expo.subscriber.did-become-active-forwarded",
    "expo.subscriber.will-resign-active-forwarded", "expo.subscriber.did-enter-background-forwarded",
    "expo.subscriber.will-enter-foreground-forwarded",
}

SCENARIO_HANDOFF = {
    "push-foreground": (REMOTE_NOTIFICATION_FOREGROUND_NATIVE, {"wrapper.app-received-notification"}),
    "push-tap-warm": (NOTIFICATION_TAP_NATIVE, {"wrapper.app-received-notification"}),
    "push-tap-cold": (NOTIFICATION_TAP_COLD_NATIVE, {"wrapper.app-received-notification"}),
    "local-notification-foreground": (LOCAL_NOTIFICATION_FOREGROUND_NATIVE, {"wrapper.app-received-notification"}),
    "local-notification-tap-warm": (NOTIFICATION_TAP_NATIVE, {"wrapper.app-received-notification"}),
    "local-notification-tap-cold": (NOTIFICATION_TAP_COLD_NATIVE, {"wrapper.app-received-notification"}),
    "custom-url-warm": (URL_NATIVE, {"wrapper.app-received-url"}),
    "custom-url-cold": (URL_COLD_NATIVE, {"wrapper.app-received-url"}),
    "universal-link-warm": (
        UNIVERSAL_LINK_NATIVE,
        {"wrapper.app-received-user-activity", "wrapper.app-received-url"},
    ),
    "universal-link-cold": (
        UNIVERSAL_LINK_COLD_NATIVE,
        {"wrapper.app-received-user-activity", "wrapper.app-received-url"},
    ),
    "quick-action-warm": (QUICK_ACTION_NATIVE, {"wrapper.app-received-quick-action"}),
    "quick-action-cold": (QUICK_ACTION_COLD_NATIVE, {"wrapper.app-received-quick-action"}),
    "live-activity-tap-warm": (URL_NATIVE, {"wrapper.app-received-url"}),
    "live-activity-tap-cold": (URL_COLD_NATIVE, {"wrapper.app-received-url"}),
    "app-background-foreground": (APP_STATE_NATIVE, {"wrapper.app-lifecycle-state"}),
}

ICON_LAUNCH_HANDOFF = {
    "flutter": (
        {"application.did-finish-launching"}, {"flutter.dart-main-entered"},
    ),
    "expo": (
        {"application.did-finish-launching"}, {"wrapper.app-lifecycle-state"},
    ),
}


def _scenario_handoff(
    scenario: str, integration: str
) -> tuple[set[str], set[str]] | None:
    if scenario == "icon-cold-launch":
        return ICON_LAUNCH_HANDOFF.get(integration)
    return SCENARIO_HANDOFF.get(scenario)
WRAPPER_RUNTIME_BY_INTEGRATION = {
    "flutter": "dart",
    "expo": "javascript",
}
LAUNCH_DEFINING = {"application.did-finish-launching"}
URL_DEFINING = {"application.open-url", "scene.open-url-contexts", "swiftui.on-open-url"}
URL_COLD_DEFINING = URL_DEFINING.union({"scene.will-connect"})
USER_ACTIVITY_DEFINING = {
    "application.continue-user-activity", "scene.continue-user-activity", "swiftui.on-open-url",
}
USER_ACTIVITY_COLD_DEFINING = USER_ACTIVITY_DEFINING.union({"scene.will-connect"})
QUICK_ACTION_DEFINING = {"application.perform-quick-action", "scene.perform-quick-action"}
QUICK_ACTION_COLD_DEFINING = QUICK_ACTION_DEFINING.union({"scene.will-connect"})
SCENARIO_REQUIRED_GROUPS = {
    "icon-cold-launch": [LAUNCH_DEFINING],
    "push-foreground": [{"notification-center.will-present"}, {"host.present-notification"}],
    "push-tap-warm": [
        {"notification-center.did-receive-response"},
        {"customerio.handle-notification-response"},
    ],
    "push-tap-cold": [
        {"notification-center.did-receive-response"},
        {"customerio.handle-notification-response"},
        LAUNCH_DEFINING,
    ],
    "local-notification-foreground": [
        {"notification-center.will-present"}, {"host.present-notification"},
    ],
    "local-notification-tap-warm": [{"notification-center.did-receive-response"}],
    "local-notification-tap-cold": [{"notification-center.did-receive-response"}, LAUNCH_DEFINING],
    "custom-url-warm": [URL_DEFINING],
    "custom-url-cold": [URL_COLD_DEFINING, LAUNCH_DEFINING],
    "universal-link-warm": [USER_ACTIVITY_DEFINING],
    "universal-link-cold": [USER_ACTIVITY_COLD_DEFINING, LAUNCH_DEFINING],
    "quick-action-warm": [QUICK_ACTION_DEFINING],
    "quick-action-cold": [QUICK_ACTION_COLD_DEFINING, LAUNCH_DEFINING],
    "live-activity-tap-warm": [URL_DEFINING],
    "live-activity-tap-cold": [URL_COLD_DEFINING, LAUNCH_DEFINING],
    "token-registration": [REGISTRATION_SUCCESS_NATIVE],
    "registration-failure": [{"application.did-fail-to-register-for-remote-notifications"}],
    "background-fetch": [{"application.perform-background-fetch"}, {"host.background-fetch-completion-result"}],
    "app-background-foreground": [
        {"application.did-enter-background", "scene.did-enter-background"},
        {"application.will-enter-foreground", "scene.will-enter-foreground"},
    ],
    "notification-settings": [{"notification-center.settings"}],
}

SCENARIO_BOUND_CALLBACKS: dict[str, set[str]] = {}


def _bind_scenarios(callbacks: Iterable[str], scenarios: set[str]) -> None:
    for callback in callbacks:
        SCENARIO_BOUND_CALLBACKS.setdefault(callback, set()).update(scenarios)


_bind_scenarios(
    {
        "application.did-finish-launching", "scene.will-connect",
        "uikit.application-did-finish-launching-notification",
        "uikit.scene-will-connect-notification",
        "flutter.application.did-finish-launching-forwarded",
        "flutter.scene.will-connect-forwarded",
        "expo.app-delegate-did-finish-launching-forwarded",
    },
    COLD_START_SCENARIOS,
)
_bind_scenarios({"flutter.dart-main-entered"}, {"icon-cold-launch"})
_bind_scenarios(
    {
        "application.open-url", "scene.open-url-contexts", "swiftui.on-open-url",
        "flutter.application.open-url-forwarded", "flutter.scene.open-url-contexts-forwarded",
        "expo.subscriber.open-url-forwarded",
    },
    URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS),
)
_bind_scenarios(
    {
        "application.continue-user-activity", "scene.continue-user-activity",
        "flutter.application.continue-user-activity-forwarded",
        "flutter.scene.continue-user-activity-forwarded",
        "expo.subscriber.continue-user-activity-forwarded",
    },
    UNIVERSAL_LINK_SCENARIOS,
)
_bind_scenarios(
    {
        "application.perform-quick-action", "scene.perform-quick-action",
        "flutter.application.perform-quick-action-forwarded",
        "flutter.scene.perform-quick-action-forwarded",
        "expo.subscriber.perform-quick-action-forwarded",
    },
    QUICK_ACTION_SCENARIOS,
)
_bind_scenarios(
    REMOTE_NOTIFICATION_CALLBACKS,
    {"push-foreground"},
)
_bind_scenarios(
    NOTIFICATION_PRESENTATION_NATIVE.union({"host.present-notification"}),
    {"push-foreground", "local-notification-foreground"},
)
_bind_scenarios(
    NOTIFICATION_TAP_NATIVE,
    {
        "push-tap-warm", "push-tap-cold",
        "local-notification-tap-warm", "local-notification-tap-cold",
    },
)
_bind_scenarios(
    NOTIFICATION_COLD_PULL_NATIVE,
    {"push-tap-cold", "local-notification-tap-cold"},
)
_bind_scenarios(BACKGROUND_FETCH_NATIVE, {"background-fetch"})
_bind_scenarios(
    {"wrapper.app-received-url"},
    URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS),
)
_bind_scenarios(
    {"wrapper.app-received-user-activity"},
    UNIVERSAL_LINK_SCENARIOS,
)
_bind_scenarios(
    {"wrapper.app-received-notification"},
    REMOTE_SCENARIOS.union(LOCAL_SCENARIOS),
)
_bind_scenarios(
    {"wrapper.app-received-quick-action"},
    QUICK_ACTION_SCENARIOS,
)

CALLBACK_MIN_IOS_MAJOR = {
    "swiftui.on-open-url": 14,
    "swiftui.scene-phase-change": 14,
}

COLD_BOOTSTRAP_GROUPS = {
    "flutter": (
        {"flutter.implicit-engine-created"},
        {"flutter.plugin-registered"},
    ),
    "expo": (
        {"expo.subscriber-registered"},
        {"expo.app-delegate-will-finish-launching-forwarded"},
        {
            "rct.javascript-did-load-notification",
            "rct.instance-did-load-bundle-notification",
        },
    ),
}

INTEGRATION_FORWARD_FOR_INGRESS = {
    "flutter": {
        "application.did-finish-launching": {"flutter.application.did-finish-launching-forwarded"},
        "notification-center.will-present": {"flutter.notification-center.will-present-forwarded"},
        "notification-center.did-receive-response": {
            "flutter.notification-center.did-receive-response-forwarded",
            "flutter.notification-response",
        },
        "application.did-receive-remote-notification": {
            "flutter.application.did-receive-remote-notification-forwarded",
        },
        "application.open-url": {"flutter.application.open-url-forwarded"},
        "scene.open-url-contexts": {"flutter.scene.open-url-contexts-forwarded"},
        "swiftui.on-open-url": {
            "flutter.application.open-url-forwarded", "flutter.scene.open-url-contexts-forwarded",
        },
        "scene.will-connect": {"flutter.scene.will-connect-forwarded"},
        "application.continue-user-activity": {
            "flutter.application.continue-user-activity-forwarded",
        },
        "scene.continue-user-activity": {"flutter.scene.continue-user-activity-forwarded"},
        "application.perform-quick-action": {"flutter.application.perform-quick-action-forwarded"},
        "scene.perform-quick-action": {"flutter.scene.perform-quick-action-forwarded"},
        "application.did-enter-background": {
            "flutter.application.did-enter-background-forwarded", "flutter.app-lifecycle-state",
        },
        "scene.did-enter-background": {
            "flutter.scene.did-enter-background-forwarded", "flutter.app-lifecycle-state",
        },
        "application.will-enter-foreground": {
            "flutter.application.will-enter-foreground-forwarded", "flutter.app-lifecycle-state",
        },
        "scene.will-enter-foreground": {
            "flutter.scene.will-enter-foreground-forwarded", "flutter.app-lifecycle-state",
        },
    },
    "expo": {
        "application.did-finish-launching": {
            "expo.app-delegate-did-finish-launching-forwarded",
        },
        "notification-center.will-present": {
            "expo.notifications-emitter.notification-received-event-sent",
        },
        "notification-center.did-receive-response": {
            "expo.notifications-emitter.notification-response-event-sent",
        },
        "application.did-receive-remote-notification": {
            "expo.subscriber.did-receive-remote-notification-forwarded",
        },
        "application.open-url": {"expo.subscriber.open-url-forwarded"},
        "swiftui.on-open-url": {"expo.subscriber.open-url-forwarded"},
        "application.continue-user-activity": {"expo.subscriber.continue-user-activity-forwarded"},
        "application.perform-quick-action": {"expo.subscriber.perform-quick-action-forwarded"},
        "application.did-enter-background": {"expo.subscriber.did-enter-background-forwarded"},
        "application.will-enter-foreground": {"expo.subscriber.will-enter-foreground-forwarded"},
    },
}

FRAMEWORK_ROLES = {
    "customerio-ios": "sdk",
    "customerio-messaging-push": "sdk",
    "customerio-flutter": "wrapper",
    "flutter": "runtime",
    "firebase-ios-sdk-messaging": "peer",
    "flutterfire-firebase-messaging": "plugin",
    "flutter-local-notifications": "plugin",
    "quick-actions-ios": "plugin",
    "customerio-expo-plugin": "wrapper",
    "expo": "runtime",
    "expo-notifications": "peer",
    "expo-modules-core": "peer",
    "customerio-reactnative": "wrapper",
    "react-native": "runtime",
    "react-native-push-notification": "plugin",
    "apple-usernotifications": "platform-framework",
    "apns-provider-sdk": "provider-sdk",
    "fcm-provider-sdk": "provider-sdk",
}

FRAMEWORK_REPOSITORIES = {
    "customerio-ios": "customerio-ios",
    "customerio-messaging-push": "customerio-ios",
    "customerio-flutter": "customerio-flutter",
    "customerio-expo-plugin": "customerio-expo-plugin",
    "customerio-reactnative": "customerio-reactnative",
}

DELEGATE_PEER_FRAMEWORKS = {
    "customerio-messaging-push": ("customerio-messaging-push", "sdk"),
    "expo-notifications": ("expo-notifications", "peer"),
    "flutter-local-notifications": ("flutter-local-notifications", "plugin"),
    "react-native-push-notification": ("react-native-push-notification", "plugin"),
}

RFC3339_PATTERN = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$"
)
DEVICE_IDENTIFIER_PATTERNS = (
    re.compile(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}"),
    re.compile(r"[0-9a-fA-F]{40}"),
    re.compile(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{16}"),
    re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
    re.compile(r"(?:^|[^A-Z0-9])[CFG][A-Z0-9]{9,11}(?:$|[^A-Z0-9])"),
)
PLACEHOLDER_PROVENANCE = re.compile(
    r"^(?:unknown|unspecified|n/?a|none|latest|dev|snapshot|local|0+(?:\.0+)*)$",
    re.IGNORECASE,
)

AUDITED_WRAPPER_TOPOLOGIES = {
    "expo": {
        "repositories": {
            "customerio-expo-plugin": "3637028bfa4c5c66752697b346ad826266e6ae03",
            "customerio-reactnative": "1edc94769359dfd992d6622884561d448d3f8dd9",
        },
        "frameworks": {
            "customerio-expo-plugin": "3.7.1",
            "expo": "57.0.12",
            "expo-notifications": "57.0.10",
            "expo-modules-core": "57.0.10",
            "customerio-reactnative": "6.6.2",
            "react-native": "0.86.2",
        },
    },
    "react-native": {
        "repositories": {
            "customerio-reactnative": "1edc94769359dfd992d6622884561d448d3f8dd9",
        },
        "frameworks": {
            "customerio-reactnative": "6.6.2",
            "react-native": "0.83.6",
        },
    },
}


class ContractError(ValueError):
    """A schema or relational contract violation."""


def _format_checker() -> FormatChecker:
    checker = FormatChecker()
    if not checker.conforms("2026-08-11T16:00:00Z", "date-time") or checker.conforms(
        "2026-08-11", "date-time"
    ):
        raise SystemExit(
            "jsonschema date-time format checker unavailable; "
            "install 'jsonschema[format]>=4.18,<5'"
        )
    return checker


FORMAT_CHECKER = _format_checker()


def _parse_time(value: str, source: str) -> datetime:
    if not isinstance(value, str) or RFC3339_PATTERN.fullmatch(value) is None:
        raise ContractError(
            f"{source}: expected RFC3339 date-time with timezone, got {value!r}"
        )
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if parsed.utcoffset() is None:
            raise ValueError("timezone offset is required")
        return parsed
    except (TypeError, ValueError) as error:
        raise ContractError(
            f"{source}: expected RFC3339 date-time with timezone, got {value!r}"
        ) from error


def _load_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as file:
            return json.load(file)
    except (OSError, json.JSONDecodeError) as error:
        raise ContractError(f"{path}: cannot load JSON: {error}") from error


def _schemas(schema_dir: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    trace = _load_json(schema_dir / "ios27-lifecycle-trace-v1.schema.json")
    manifest = _load_json(schema_dir / "ios27-lifecycle-capture-manifest-v1.schema.json")
    try:
        Draft202012Validator.check_schema(trace)
        Draft202012Validator.check_schema(manifest)
    except Exception as error:
        raise ContractError(f"invalid checked-in JSON Schema: {error}") from error
    return trace, manifest


def _validator(
    schema: dict[str, Any],
    referenced_schema: dict[str, Any] | None = None,
) -> Draft202012Validator:
    registry = Registry()
    if referenced_schema is not None:
        registry = registry.with_resource(
            referenced_schema["$id"], Resource.from_contents(referenced_schema)
        )
    return Draft202012Validator(schema, registry=registry, format_checker=FORMAT_CHECKER)


def _assert_schema(validator: Draft202012Validator, value: Any, source: str) -> None:
    errors = sorted(validator.iter_errors(value), key=lambda item: list(item.absolute_path))
    if errors:
        error = errors[0]
        location = ".".join(str(part) for part in error.absolute_path) or "$"
        raise ContractError(f"{source}: schema violation at {location}: {error.message}")


def _load_stream(path: Path, validator: Draft202012Validator) -> list[dict[str, Any]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise ContractError(f"{path}: cannot read stream: {error}") from error
    if not lines:
        raise ContractError(f"{path}: empty stream")
    records = []
    for line_number, line in enumerate(lines, 1):
        if not line.startswith(PREFIX):
            raise ContractError(f"{path}:{line_number}: missing exact {PREFIX!r} prefix")
        try:
            record = json.loads(line[len(PREFIX):])
        except json.JSONDecodeError as error:
            raise ContractError(f"{path}:{line_number}: invalid JSON: {error}") from error
        _assert_schema(validator, record, f"{path}:{line_number}")
        records.append(record)
    return records


def _validate_timestamps(manifest: dict[str, Any]) -> tuple[datetime, datetime]:
    started = _parse_time(manifest["run_started_at"], "manifest.run_started_at")
    ended = _parse_time(manifest["run_ended_at"], "manifest.run_ended_at")
    created = _parse_time(manifest["created_at"], "manifest.created_at")
    initiated = _parse_time(manifest["stimulus"]["initiated_at"], "manifest.stimulus.initiated_at")
    if not started <= initiated <= ended <= created:
        raise ContractError("manifest time order must be run_started <= stimulus <= run_ended <= created")
    receipt_value = manifest["provider_provenance"]["receipt_recorded_at"]
    if receipt_value is not None:
        receipt = _parse_time(receipt_value, "manifest.provider_provenance.receipt_recorded_at")
        if not initiated <= receipt <= ended:
            raise ContractError("provider receipt must not predate the stimulus or exceed run_ended_at")
    return started, ended


def _validate_scenario_provenance(manifest: dict[str, Any]) -> None:
    scenario = manifest["scenario"]
    evidence = manifest["evidence_level"]
    provenance = manifest["provider_provenance"]
    stimulus = manifest["stimulus"]
    if stimulus["scenario"] != scenario:
        raise ContractError("manifest stimulus.scenario must equal manifest scenario")

    provider = provenance["provider"]
    source = provenance["source"]
    environment = provenance["environment"]
    result = provenance["receipt_result"]
    receipt_at = provenance["receipt_recorded_at"]

    if scenario in REMOTE_SCENARIOS:
        if provider not in ("apn", "fcm"):
            raise ContractError("remote push/tap scenarios require provider apn or fcm")
        simulator_path = source == "simulator-control" and environment == "simulator" and result == "injected"
        real_path = (
            source in ("provider-api", "provider-console")
            and environment in ("sandbox", "production")
            and result == "accepted"
        )
        if not (simulator_path or real_path):
            raise ContractError("remote provider source, environment, and receipt are incompatible")
        expected_stimulus = "simulator-control" if simulator_path else "provider"
        if stimulus["source"] != expected_stimulus:
            raise ContractError("remote stimulus source does not match provider provenance")
        if receipt_at is None or result == "unknown":
            raise ContractError("remote acceptance requires a non-unknown receipt and timestamp")
        if evidence == "L3" and not real_path:
            raise ContractError("L3 remote evidence requires a real provider path")
        provider_sdk = provenance["provider_sdk"]
        if source == "provider-api":
            expected_sdk = "apns-provider-sdk" if provider == "apn" else "fcm-provider-sdk"
            if provider_sdk is None or provider_sdk["name"] != expected_sdk:
                raise ContractError(
                    f"{provider} provider-api provenance requires {expected_sdk}"
                )
        elif provider_sdk is not None:
            raise ContractError(
                f"{source} provenance must not claim a provider SDK; only provider-api may do so"
            )
    elif scenario in LOCAL_SCENARIOS:
        if not (
            provider == "local"
            and source in ("local-scheduler", "system-scheduler")
            and environment == "local"
            and result == "scheduled"
            and receipt_at is not None
            and provenance["provider_sdk"] is None
        ):
            raise ContractError("local notification scenarios require local scheduling provenance")
        allowed_sources = {"local-scheduler"}
        if "tap" in scenario:
            allowed_sources.add("notification-center")
        if stimulus["source"] not in allowed_sources:
            raise ContractError("local notification stimulus source is incompatible")
    elif scenario in REGISTRATION_SCENARIOS:
        expected_result = "registered" if scenario == "token-registration" else "failed"
        if not (
            provider in ("apn", "fcm")
            and source == "system-registration"
            and environment in ("sandbox", "production", "simulator")
            and result == expected_result
            and receipt_at is not None
            and stimulus["source"] == "system-registration"
            and provenance["provider_sdk"] is None
        ):
            raise ContractError("registration scenario provenance is incompatible")
        if evidence == "L3" and environment not in ("sandbox", "production"):
            raise ContractError(
                "L3 registration evidence requires a real sandbox or production path"
            )
    elif scenario not in ("unscoped", "unit-fixture"):
        if not (
            provider == "none" and source == "none" and environment == "none"
            and result == "not-applicable" and receipt_at is None
            and provenance["provider_sdk"] is None
        ):
            raise ContractError("non-provider scenario must use none/not-applicable provenance")
        source_rules = {
            "icon-cold-launch": {"app-icon"},
            "background-fetch": {"background-fetch-control"},
            "app-background-foreground": {"app-ui", "simulator-control"},
            "notification-settings": {"system-settings", "app-ui"},
        }
        if scenario in URL_SCENARIOS:
            allowed = {"app-ui", "simulator-control"}
        elif scenario in QUICK_ACTION_SCENARIOS:
            allowed = {"system-quick-action"}
        elif scenario in LIVE_ACTIVITY_SCENARIOS:
            allowed = {"live-activity"}
        else:
            allowed = source_rules.get(scenario, set())
        if stimulus["source"] not in allowed:
            raise ContractError(f"stimulus source is incompatible with scenario {scenario}")
    elif scenario == "unit-fixture":
        if not (
            evidence == "diagnostic" and provider == "none" and source == "none"
            and environment == "none" and result == "not-applicable"
            and receipt_at is None and provenance["provider_sdk"] is None
            and stimulus["source"] == "unit-fixture"
        ):
            raise ContractError("unit-fixture must use diagnostic none provenance")


def _validate_declared_host_topology(manifest: dict[str, Any]) -> None:
    """Reject unsupported integration/topology combinations before reading evidence."""
    topology = manifest["host_topology"]
    if topology not in HOST_TOPOLOGIES:
        raise ContractError(f"unsupported host_topology {topology}")
    integrations = {item["integration"] for item in manifest["streams"]}
    if topology == "swiftui-lifecycle" and integrations != {"native-ios"}:
        raise ContractError(
            "swiftui-lifecycle evidence is currently supported only for native-ios"
        )
    if topology == "swiftui-lifecycle" and manifest["scenario"] in QUICK_ACTION_SCENARIOS:
        raise ContractError(
            "swiftui-lifecycle quick-action evidence has no canonical v1 ingress"
        )


def _is_scene_callback(callback: str) -> bool:
    return callback.startswith(SCENE_CALLBACK_PREFIXES)


def _validate_topology_and_occurrence(
    manifest: dict[str, Any], records_by_stream: dict[str, list[dict[str, Any]]]
) -> None:
    """Enforce one explicit host topology and one safe activation occurrence."""
    topology = manifest["host_topology"]
    scenario = manifest["scenario"]
    all_records = [record for records in records_by_stream.values() for record in records]
    runtime_records = [record for record in all_records if record["kind"] != "trace-control"]

    if manifest["evidence_level"] in ("L2", "L3"):
        occurrences = {
            (record.get("correlation") or {}).get("occurrence")
            for record in runtime_records
        }
        if occurrences != {"occurrence-1"}:
            raise ContractError(
                "L2/L3 runtime seats require exactly one shared correlation.occurrence alias"
            )

    scene_records = [record for record in all_records if _is_scene_callback(record["callback"])]
    swiftui_records = [record for record in all_records if record["callback"] in SWIFTUI_CALLBACKS]
    application_ui_records = [
        record for record in all_records if record["callback"] in APP_DELEGATE_UI_CALLBACKS
    ]

    for record in scene_records:
        if (record.get("correlation") or {}).get("scene") is None:
            raise ContractError(
                f"{record['callback']} requires correlation.scene in a scene topology"
            )
    scene_aliases = {
        (record.get("correlation") or {}).get("scene") for record in all_records
    }
    scene_aliases.discard(None)
    if len(scene_aliases) > 1:
        raise ContractError(
            "lifecycle contract v1 permits exactly one participating scene per capture"
        )

    if topology == "app-delegate-only":
        if scene_records or swiftui_records:
            raise ContractError(
                "app-delegate-only evidence must not contain scene or SwiftUI callbacks"
            )
        if scene_aliases:
            raise ContractError("app-delegate-only evidence must not allocate scene aliases")
    elif topology == "ui-scene":
        if swiftui_records:
            raise ContractError("ui-scene evidence must not contain SwiftUI lifecycle callbacks")
        if application_ui_records:
            callbacks = sorted({record["callback"] for record in application_ui_records})
            raise ContractError(
                "ui-scene UI activation must not use AppDelegate ingress: "
                f"{callbacks}"
            )
        if scenario in SCENE_UI_SCENARIOS and len(scene_aliases) != 1:
            raise ContractError(
                f"ui-scene scenario {scenario} requires exactly one participating scene"
            )
    else:
        if scene_records:
            raise ContractError(
                "swiftui-lifecycle evidence must not contain UISceneDelegate callbacks"
            )
        if application_ui_records:
            callbacks = sorted({record["callback"] for record in application_ui_records})
            raise ContractError(
                "swiftui-lifecycle UI activation must not use AppDelegate ingress: "
                f"{callbacks}"
            )
        if scenario in SCENE_UI_SCENARIOS and scenario != "icon-cold-launch" and not swiftui_records:
            raise ContractError(
                f"swiftui-lifecycle scenario {scenario} requires a SwiftUI lifecycle ingress"
            )

    if scenario in URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS):
        for record in runtime_records:
            url_contexts = record["payload_summary"]["counts"].get("url_contexts")
            if url_contexts is not None and url_contexts > 1:
                raise ContractError(
                    "one activation occurrence must fail closed when multiple URL contexts arrive"
                )


def _validate_wrapper_acceptance_topology(
    manifest: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]] | None:
    """Validate the two runtime seats and process proof for wrapper acceptance."""
    if (
        manifest["evidence_level"] not in ("L2", "L3")
        or manifest["scenario"] in NATIVE_ONLY_SINGLE_STREAM_SCENARIOS
    ):
        return None
    declarations = manifest["streams"]
    integrations = {item["integration"] for item in declarations}
    if integrations == {"react-native"}:
        if len(declarations) != 1 or declarations[0]["runtime"] != "swift":
            raise ContractError(
                "standalone React Native iOS acceptance is one native Swift pass-through "
                "stream; no JavaScript notification receipt exists"
            )
        return None
    wrapper_integrations = integrations.intersection(WRAPPER_RUNTIME_BY_INTEGRATION)
    if not wrapper_integrations:
        return None
    if len(integrations) != 1:
        raise ContractError(
            "wrapper L2/L3 acceptance requires one shared supported integration topology"
        )
    integration = next(iter(integrations))
    expected_runtime = WRAPPER_RUNTIME_BY_INTEGRATION[integration]
    swift = [item for item in declarations if item["runtime"] == "swift"]
    wrapper = [item for item in declarations if item["runtime"] == expected_runtime]
    if len(declarations) != 2 or len(swift) != 1 or len(wrapper) != 1:
        raise ContractError(
            f"{integration} L2/L3 acceptance requires exactly one Swift and one "
            f"{expected_runtime} runtime seat"
        )
    native_declaration = swift[0]
    wrapper_declaration = wrapper[0]
    if native_declaration["process_instance_id"] != wrapper_declaration["process_instance_id"]:
        raise ContractError(
            f"{integration} Swift/wrapper seats require one shared process_instance_id"
        )
    native_pid = native_declaration["process_id"]
    wrapper_pid = wrapper_declaration["process_id"]
    if integration == "flutter":
        if native_pid is None or wrapper_pid is None or native_pid != wrapper_pid:
            raise ContractError(
                "Flutter Swift/Dart seats require the same non-null process_id"
            )
    elif wrapper_pid is not None and wrapper_pid != native_pid:
        raise ContractError(
            f"{integration} Swift/JavaScript seats with a reported process_id must match"
        )
    return native_declaration, wrapper_declaration


def _validate_manifest_relations(manifest: dict[str, Any]) -> tuple[datetime, datetime]:
    started, ended = _validate_timestamps(manifest)
    _validate_scenario_provenance(manifest)
    _validate_declared_host_topology(manifest)

    repositories = {item["name"]: item for item in manifest["repositories"]}
    frameworks = {item["name"]: item for item in manifest["frameworks"]}
    streams = {item["stream_id"]: item for item in manifest["streams"]}
    if len(repositories) != len(manifest["repositories"]):
        raise ContractError("manifest repository names must be unique")
    if len(frameworks) != len(manifest["frameworks"]):
        raise ContractError("manifest framework names must be unique")
    if len(streams) != len(manifest["streams"]):
        raise ContractError("manifest stream_id values must be unique")

    provenance_markers = {
        "flutter": (
            "customerio-flutter" in repositories
            or bool({
                "customerio-flutter", "flutter", "flutterfire-firebase-messaging",
                "flutter-local-notifications", "quick-actions-ios",
            }.intersection(frameworks))
        ),
        "expo": (
            "customerio-expo-plugin" in repositories
            or bool({
                "customerio-expo-plugin", "expo", "expo-notifications",
                "expo-modules-core",
            }.intersection(frameworks))
        ),
        "react-native": (
            "customerio-reactnative" in repositories
            or bool({
                "customerio-reactnative", "react-native",
                "react-native-push-notification",
            }.intersection(frameworks))
        ),
    }
    if provenance_markers["flutter"] and (
        provenance_markers["expo"] or provenance_markers["react-native"]
    ):
        raise ContractError("manifest wrapper provenance mixes incompatible integrations")
    expected_integration = (
        "flutter" if provenance_markers["flutter"]
        else "expo" if provenance_markers["expo"]
        else "react-native" if provenance_markers["react-native"]
        else "native-ios"
    )
    declared_integrations = {item["integration"] for item in streams.values()}
    if declared_integrations != {expected_integration}:
        raise ContractError(
            f"stream integration must match repository/framework provenance: "
            f"expected {expected_integration}, observed {sorted(declared_integrations)}"
        )

    for name, framework in frameworks.items():
        if framework["role"] != FRAMEWORK_ROLES[name]:
            raise ContractError(f"framework {name} has incorrect role {framework['role']}")
        repository_name = FRAMEWORK_REPOSITORIES.get(name)
        if repository_name is not None:
            repository = repositories.get(repository_name)
            if repository is None:
                raise ContractError(
                    f"framework {name} has no matching {repository_name} repository provenance"
                )
            if framework["commit_sha"] != repository["commit_sha"]:
                raise ContractError(f"framework/repository commit mismatch for {name}")
    customerio_ios_modules = [
        frameworks[name]
        for name in ("customerio-ios", "customerio-messaging-push")
        if name in frameworks
    ]
    modules_by_commit: dict[str, set[str]] = defaultdict(set)
    for framework in customerio_ios_modules:
        if framework["commit_sha"] is not None:
            modules_by_commit[framework["commit_sha"]].add(framework["version"])
    if any(len(versions) > 1 for versions in modules_by_commit.values()):
        raise ContractError(
            "customerio-ios modules at the same commit must use one coherent version"
        )

    def version_tuple(value: str) -> tuple[int, ...]:
        parts = tuple(int(part) for part in value.split("."))
        return parts + (0,) * (3 - len(parts))

    deployment = version_tuple(manifest["build"]["deployment_target"])
    sdk_version = version_tuple(manifest["sdk"]["version"])
    target_version = version_tuple(manifest["target"]["os_version"])
    if deployment < (13, 0) or deployment > sdk_version:
        raise ContractError("deployment target must be between iOS 13.0 and the build SDK version")
    if target_version < deployment:
        raise ContractError("target OS version must be at least the build deployment target")
    target_model = manifest["target"]["model"]
    target_os_name = manifest["target"]["os_name"]
    if target_model.startswith("iPad") and target_os_name != "iPadOS":
        raise ContractError("iPad target models require os_name=iPadOS")
    if target_model.startswith(("iPhone", "iPod touch")) and target_os_name != "iOS":
        raise ContractError("iPhone and iPod touch target models require os_name=iOS")
    if manifest["target"]["kind"] == "physical-device" and manifest["target"]["architecture"] != "arm64":
        raise ContractError("physical-device captures require arm64 architecture")
    provenance_labels = [
        ("build.scheme", manifest["build"]["scheme"]),
        ("build.target_name", manifest["build"]["target_name"]),
        ("target.model", manifest["target"]["model"]),
        ("sdk.build", manifest["sdk"]["build"]),
        ("target.os_build", manifest["target"]["os_build"]),
    ]
    provenance_labels.extend(
        (f"toolchain.{name}", value)
        for name, value in manifest["toolchain"].items() if value is not None
    )
    provenance_labels.extend(
        (f"frameworks.{framework['name']}.version", framework["version"])
        for framework in manifest["frameworks"]
    )
    provider_sdk_label = manifest["provider_provenance"]["provider_sdk"]
    if provider_sdk_label is not None:
        provenance_labels.append(("provider_provenance.provider_sdk.version", provider_sdk_label["version"]))
    for source, value in provenance_labels:
        if any(pattern.search(value) for pattern in DEVICE_IDENTIFIER_PATTERNS):
            raise ContractError(f"{source} must be a human-readable label, not a device identifier")

    if manifest["evidence_level"] in ("L2", "L3"):
        exact_values = [
            ("toolchain.xcode_version", manifest["toolchain"]["xcode_version"]),
            ("toolchain.xcode_build", manifest["toolchain"]["xcode_build"]),
            ("sdk.version", manifest["sdk"]["version"]),
            ("sdk.build", manifest["sdk"]["build"]),
            ("target.os_version", manifest["target"]["os_version"]),
            ("target.os_build", manifest["target"]["os_build"]),
        ]
        exact_values.extend(
            (f"toolchain.{name}", value)
            for name, value in manifest["toolchain"].items() if value is not None
        )
        exact_values.extend(
            (f"frameworks.{framework['name']}.version", framework["version"])
            for framework in manifest["frameworks"]
        )
        for source, value in exact_values:
            if PLACEHOLDER_PROVENANCE.fullmatch(value):
                raise ContractError(f"L2/L3 {source} must be an exact non-placeholder value")
        if manifest["target"]["model"].lower() in {
            "iphone", "ipad", "ipod touch", "iphone simulator", "ipad simulator",
            "iphone device", "ipad device",
        }:
            raise ContractError("L2/L3 target.model must identify a specific human device model")

    required_repositories = {"customerio-ios"}
    required_frameworks = {"customerio-ios", "apple-usernotifications"}
    integrations = set()
    runtimes = set()
    for stream in streams.values():
        integration = stream["integration"]
        runtime = stream["runtime"]
        integrations.add(integration)
        runtimes.add(runtime)
        if integration == "native-ios" and runtime != "swift":
            raise ContractError("native-ios streams must use Swift")
        if integration == "flutter":
            required_repositories.add("customerio-flutter")
            required_frameworks.update(("customerio-flutter", "flutter"))
            if runtime not in ("swift", "dart"):
                raise ContractError("Flutter streams must use Swift or Dart")
        if integration == "expo":
            required_repositories.update(("customerio-expo-plugin", "customerio-reactnative"))
            required_frameworks.update((
                "customerio-expo-plugin", "expo", "expo-notifications", "expo-modules-core",
                "customerio-reactnative", "react-native",
            ))
            if runtime not in ("swift", "javascript"):
                raise ContractError("Expo streams must use Swift or JavaScript")
        if integration == "react-native":
            required_repositories.add("customerio-reactnative")
            required_frameworks.update(("customerio-reactnative", "react-native"))
            if manifest["evidence_level"] in ("L2", "L3") and runtime != "swift":
                raise ContractError(
                    "standalone React Native iOS L2/L3 streams are native Swift pass-through only"
                )
            if runtime not in ("swift", "javascript"):
                raise ContractError("React Native streams must use Swift or JavaScript")
        if runtime != "javascript" and stream["process_id"] is None:
            raise ContractError("only JavaScript streams may use process_id=null")
        if stream["provider"] != manifest["provider_provenance"]["provider"]:
            raise ContractError("every stream provider must match provider provenance")

    if (
        manifest["evidence_level"] in ("L2", "L3")
        and len(streams) > 1
        and len(integrations) != 1
    ):
        raise ContractError("multi-stream L2/L3 captures require one shared integration topology")

    scenario = manifest["scenario"]
    provider = manifest["provider_provenance"]["provider"]
    if (
        manifest["evidence_level"] in ("L2", "L3")
        and scenario in NATIVE_ONLY_SINGLE_STREAM_SCENARIOS
        and len(streams) != 1
    ):
        raise ContractError(
            f"scenario {scenario} is a native-side single-stream acceptance topology"
        )
    _validate_wrapper_acceptance_topology(manifest)
    if provider == "fcm":
        required_frameworks.add("firebase-ios-sdk-messaging")
        if "flutter" in integrations:
            required_frameworks.add("flutterfire-firebase-messaging")
    if "flutter" in integrations and scenario in LOCAL_SCENARIOS:
        required_frameworks.add("flutter-local-notifications")
    if "flutter" in integrations and scenario in QUICK_ACTION_SCENARIOS:
        required_frameworks.add("quick-actions-ios")

    missing_repositories = required_repositories.difference(repositories)
    if missing_repositories:
        raise ContractError(f"manifest is missing repository provenance: {sorted(missing_repositories)}")
    missing_frameworks = required_frameworks.difference(frameworks)
    if missing_frameworks:
        raise ContractError(f"manifest is missing framework peers: {sorted(missing_frameworks)}")
    audited_topology = AUDITED_WRAPPER_TOPOLOGIES.get(expected_integration)
    if audited_topology is not None:
        for name, expected_sha in audited_topology["repositories"].items():
            if repositories[name]["commit_sha"] != expected_sha:
                raise ContractError(
                    f"{expected_integration} callback topology requires audited "
                    f"repository {name}@{expected_sha}"
                )
            if repositories[name]["dirty"]:
                raise ContractError(
                    f"{expected_integration} audited production repository {name} "
                    "must be clean"
                )
        for name, expected_version in audited_topology["frameworks"].items():
            if frameworks[name]["version"] != expected_version:
                raise ContractError(
                    f"{expected_integration} callback topology requires audited "
                    f"framework {name}@{expected_version}"
                )
    fixture_source = manifest.get("fixture_source")
    if expected_integration == "expo" and manifest["evidence_level"] in ("L2", "L3"):
        if fixture_source is None:
            raise ContractError("Expo L2/L3 requires exact fixture_source provenance")
        if fixture_source["name"] != "customerio-expo-plugin":
            raise ContractError(
                "Expo fixture_source.name must equal customerio-expo-plugin"
            )
    elif fixture_source is not None:
        raise ContractError("fixture_source provenance is supported only for Expo L2/L3")
    if frameworks["apple-usernotifications"]["version"] != manifest["sdk"]["version"]:
        raise ContractError("apple-usernotifications version must equal the build SDK version")

    toolchain = manifest["toolchain"]
    if "swift" in runtimes and toolchain["swift_version"] is None:
        raise ContractError("Swift runtime streams require a Swift toolchain version")
    if "dart" in runtimes and (
        toolchain["flutter_version"] is None or toolchain["dart_version"] is None
    ):
        raise ContractError("Dart runtime streams require Flutter and Dart toolchain versions")
    if "javascript" in runtimes and toolchain["node_version"] is None:
        raise ContractError("JavaScript runtime streams require a Node version")
    if "flutter" in integrations:
        if toolchain["flutter_version"] is None or toolchain["dart_version"] is None:
            raise ContractError("Flutter captures require Flutter and Dart toolchain versions")
        if frameworks["flutter"]["version"] != toolchain["flutter_version"]:
            raise ContractError("Flutter framework and toolchain versions must match")
    if integrations.intersection(("expo", "react-native")) and toolchain["node_version"] is None:
        raise ContractError("Expo and React Native captures require a Node version")
    if "expo" in integrations and toolchain["expo_cli_version"] is None:
        raise ContractError("Expo captures require an Expo CLI version")

    provider_sdk = manifest["provider_provenance"]["provider_sdk"]
    if provider_sdk is not None:
        peer = frameworks.get(provider_sdk["name"])
        if peer is None or peer["role"] != "provider-sdk" or peer["version"] != provider_sdk["version"]:
            raise ContractError("provider SDK provenance must match a provider-sdk framework peer")
    assertions = manifest["aggregate_assertions"]
    if manifest["evidence_level"] in ("L2", "L3") and len(streams) > 1 and not assertions:
        raise ContractError("multi-stream L2/L3 requires at least one aggregate assertion")
    assertion_names = set()
    for assertion in assertions:
        if assertion["name"] in assertion_names:
            raise ContractError("aggregate assertion names must be unique")
        assertion_names.add(assertion["name"])
        member_ids = [member["stream_id"] for member in assertion["members"]]
        if len(member_ids) != len(set(member_ids)):
            raise ContractError(f"aggregate assertion {assertion['name']} repeats a stream")
        unknown = set(member_ids).difference(streams)
        if unknown:
            raise ContractError(f"aggregate assertion uses undeclared streams: {sorted(unknown)}")
        for member in assertion["members"]:
            if member["callback"].startswith(("trace.", "fixture.")):
                raise ContractError(
                    f"aggregate assertion {assertion['name']} cannot select trace-control or fixture callbacks"
                )
            if "app_state" in member:
                callback = member["callback"]
                if (
                    _allowed_app_states(callback) is None
                    and callback not in {
                        "swiftui.scene-phase-change", "flutter.app-lifecycle-state",
                        "wrapper.app-lifecycle-state",
                    }
                ):
                    raise ContractError(
                        f"aggregate assertion {assertion['name']} uses app_state on "
                        f"non-lifecycle callback {callback}"
                    )
                allowed = _allowed_app_states(callback)
                if allowed is not None and member["app_state"] not in allowed:
                    raise ContractError(
                        f"aggregate assertion {assertion['name']} app_state is incompatible "
                        f"with {callback}"
                    )
    return started, ended


Rule = tuple[frozenset[str], frozenset[str], frozenset[str], frozenset[str], frozenset[str]]
CALLBACK_RULES: dict[str, Rule] = {}


def _rule(
    names: Iterable[str],
    integrations: Iterable[str],
    runtimes: Iterable[str],
    kinds: Iterable[str],
    owners: Iterable[str],
    phases: Iterable[str],
) -> None:
    value = tuple(frozenset(items) for items in (integrations, runtimes, kinds, owners, phases))
    for name in names:
        CALLBACK_RULES[name] = value  # type: ignore[assignment]


ALL_INTEGRATIONS = ("native-ios", "flutter", "expo", "react-native")
_rule(
    (
        "application.did-finish-launching", "application.configuration-for-connecting",
        "application.open-url",
        "application.continue-user-activity", "application.perform-quick-action",
        "application.did-register-for-remote-notifications",
        "application.did-fail-to-register-for-remote-notifications",
        "application.did-receive-remote-notification", "application.perform-background-fetch",
        "apns.device-token-registered", "apns.device-token-registration-failed",
    ),
    ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("application-delegate",), ("entry",),
)
_rule(
    (
        "application.did-discard-scene-sessions", "application.did-become-active", "application.will-resign-active",
        "application.did-enter-background", "application.will-enter-foreground", "application.will-terminate",
    ),
    ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("application-delegate",), ("state-change",),
)
_rule(
    ("scene.will-connect", "scene.open-url-contexts", "scene.continue-user-activity", "scene.perform-quick-action"),
    ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("scene-delegate",), ("entry",),
)
_rule(
    ("scene.did-disconnect", "scene.did-become-active", "scene.will-resign-active", "scene.did-enter-background", "scene.will-enter-foreground"),
    ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("scene-delegate",), ("state-change",),
)
_rule(("swiftui.on-open-url",), ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("swiftui-scene",), ("entry",))
_rule(("swiftui.scene-phase-change",), ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("swiftui-scene",), ("state-change",))
_rule(
    ("notification-center.will-present", "notification-center.did-receive-response", "notification-center.settings"),
    ALL_INTEGRATIONS, ("swift",), ("os-callback",), ("notification-center-delegate",), ("entry",),
)
_rule(("fcm.registration-token-refreshed",), ALL_INTEGRATIONS, ("swift",), ("framework-callback",), ("fcm-messaging-delegate",), ("entry",))

_rule(
    (
        "uikit.application-did-finish-launching-notification", "uikit.scene-will-connect-notification",
    ),
    ALL_INTEGRATIONS, ("swift",), ("observer-notification",), ("uikit-notification",), ("entry",),
)
_rule(
    (
        "uikit.application-did-become-active-notification", "uikit.application-will-resign-active-notification",
        "uikit.application-did-enter-background-notification", "uikit.application-will-enter-foreground-notification",
        "uikit.application-will-terminate-notification", "uikit.scene-did-disconnect-notification",
        "uikit.scene-did-activate-notification", "uikit.scene-will-deactivate-notification",
        "uikit.scene-did-enter-background-notification", "uikit.scene-will-enter-foreground-notification",
    ),
    ALL_INTEGRATIONS, ("swift",), ("observer-notification",), ("uikit-notification",), ("state-change",),
)
_rule(
    (
        "rct.javascript-will-start-loading-notification", "rct.javascript-did-load-notification",
        "rct.javascript-did-fail-to-load-notification", "rct.did-initialize-module-notification",
        "rct.bridge-will-reload-notification", "rct.bridge-did-invalidate-modules-notification",
        "rct.instance-did-load-bundle-notification",
    ),
    ("expo",), ("swift",), ("observer-notification",), ("rct-notification",), ("state-change",),
)

_rule(("flutter.implicit-engine-created",), ("flutter",), ("swift",), ("framework-callback",), ("flutter-engine",), ("result",))
_rule(("flutter.plugin-registered",), ("flutter",), ("swift",), ("framework-callback",), ("flutter-plugin",), ("result",))
_rule(
    tuple(name for name in (
        "flutter.application.did-finish-launching-forwarded", "flutter.application.open-url-forwarded",
        "flutter.application.continue-user-activity-forwarded", "flutter.application.perform-quick-action-forwarded",
        "flutter.application.did-register-for-remote-notifications-forwarded",
        "flutter.application.did-fail-to-register-for-remote-notifications-forwarded",
        "flutter.application.did-receive-remote-notification-forwarded",
        "flutter.application.perform-background-fetch-forwarded", "flutter.scene.will-connect-forwarded",
        "flutter.scene.open-url-contexts-forwarded", "flutter.scene.continue-user-activity-forwarded",
        "flutter.scene.perform-quick-action-forwarded", "flutter.notification-center.will-present-forwarded",
        "flutter.notification-center.did-receive-response-forwarded", "flutter.notification-response",
    )),
    ("flutter",), ("swift",), ("framework-callback",), ("flutter-plugin",), ("entry",),
)
_rule(("flutter.app-lifecycle-state",), ("flutter",), ("swift",), ("framework-callback",), ("flutter-engine", "flutter-plugin"), ("state-change",))
_rule(
    ("flutter.dart-main-entered",), ("flutter",), ("dart",),
    ("app-received",), ("flutter-dart",), ("entry",),
)
_rule(
    (
        "flutter.application.did-become-active-forwarded", "flutter.application.will-resign-active-forwarded",
        "flutter.application.did-enter-background-forwarded", "flutter.application.will-enter-foreground-forwarded",
        "flutter.application.will-terminate-forwarded", "flutter.scene.did-disconnect-forwarded",
        "flutter.scene.did-become-active-forwarded", "flutter.scene.will-resign-active-forwarded",
        "flutter.scene.did-enter-background-forwarded", "flutter.scene.will-enter-foreground-forwarded",
    ),
    ("flutter",), ("swift",), ("framework-callback",), ("flutter-plugin",), ("state-change",),
)

EXPO_FORWARD = tuple(
    name for name in (
        "expo.subscriber.open-url-forwarded",
        "expo.subscriber.continue-user-activity-forwarded", "expo.subscriber.perform-quick-action-forwarded",
        "expo.subscriber.did-register-for-remote-notifications-forwarded",
        "expo.subscriber.did-fail-to-register-for-remote-notifications-forwarded",
        "expo.subscriber.did-receive-remote-notification-forwarded",
        "expo.subscriber.perform-background-fetch-forwarded",
    )
)
_rule(EXPO_FORWARD, ("expo",), ("swift",), ("framework-callback",), ("expo-subscriber",), ("entry",))
_rule(
    (
        "expo.subscriber.did-become-active-forwarded", "expo.subscriber.will-resign-active-forwarded",
        "expo.subscriber.did-enter-background-forwarded", "expo.subscriber.will-enter-foreground-forwarded",
        "expo.subscriber.will-terminate-forwarded",
    ),
    ("expo",), ("swift",), ("framework-callback",), ("expo-subscriber",), ("state-change",),
)
_rule(("expo.subscriber-registered",), ("expo",), ("swift",), ("framework-callback",), ("expo-subscriber",), ("result",))
_rule(
    (
        "expo.app-delegate-will-finish-launching-forwarded",
        "expo.app-delegate-did-finish-launching-forwarded",
    ),
    ("expo",), ("swift",), ("framework-callback",), ("expo-framework",), ("entry",),
)
_rule(
    (
        "expo.notification-center-manager.will-present-forwarded",
        "expo.notification-center-manager.did-receive-response-forwarded",
    ),
    ("expo",), ("swift",), ("framework-callback",), ("expo-notifications",), ("entry",),
)
_rule(
    (
        "expo.notifications-emitter-created",
        "expo.notifications-emitter.notification-received-event-sent",
        "expo.notifications-emitter.notification-response-event-sent",
    ),
    ("expo",), ("swift",), ("framework-callback",), ("expo-notifications",), ("result",),
)
_rule(("expo.last-notification-response-pulled",), ("expo",), ("swift",), ("framework-callback",), ("expo-framework",), ("result",))

_rule(("host.route-url", "host.route-user-activity", "host.route-quick-action", "host.route-notification"), ALL_INTEGRATIONS, ("swift",), ("host-routing",), ("host",), ("intent", "result"))
_rule(("host.present-notification", "host.background-fetch-completion-result"), ALL_INTEGRATIONS, ("swift",), ("host-routing",), ("host",), ("result",))
_rule(("customerio.route-deep-link", "customerio.handle-notification-response", "customerio.register-device-token"), ALL_INTEGRATIONS, ("swift",), ("sdk-routing",), ("customerio-sdk",), ("intent", "result"))
_rule(("trace.scenario-start", "trace.scenario-end"), ALL_INTEGRATIONS, ("swift", "dart", "javascript"), ("trace-control",), ("trace-recorder",), ("state-change",))
_rule(("fixture.completion-created",), ("native-ios",), ("swift",), ("fixture-control",), ("fixture",), ("entry",))
_rule(("fixture.completion-observed",), ("native-ios",), ("swift",), ("completion-fixture",), ("fixture",), ("completion",))


def _validate_callback_rule(record: dict[str, Any]) -> None:
    callback = record["callback"]
    rule = CALLBACK_RULES.get(callback)
    if rule is None:
        if callback.startswith("wrapper.app-received-") or callback == "wrapper.app-lifecycle-state":
            if record["kind"] != "app-received":
                raise ContractError(f"{callback} must be app-received")
            expected_owner = {
                ("flutter", "dart"): "flutter-dart",
                ("expo", "javascript"): "expo-javascript",
            }.get((record["integration"], record["runtime"]))
            if expected_owner is None or record["owner"] != expected_owner:
                raise ContractError(f"{callback} has an incompatible wrapper runtime owner")
            expected_phase = "state-change" if callback == "wrapper.app-lifecycle-state" else "entry"
            if record["phase"] != expected_phase:
                raise ContractError(f"{callback} must use phase={expected_phase}")
            return
        raise ContractError(f"callback registry has no relational rule for {callback}")
    values = (
        record["integration"], record["runtime"], record["kind"], record["owner"], record["phase"]
    )
    labels = ("integration", "runtime", "kind", "owner", "phase")
    for value, allowed, label in zip(values, rule, labels):
        if value not in allowed:
            raise ContractError(f"{callback} has incompatible {label}={value}")


def _validate_scenario_bound_callback(record: dict[str, Any]) -> None:
    if record["evidence_level"] not in ("L2", "L3"):
        return
    allowed = SCENARIO_BOUND_CALLBACKS.get(record["callback"])
    if allowed is not None and record["scenario"] not in allowed:
        raise ContractError(
            f"{record['callback']} is an external-entry seat that cannot occur in "
            f"scenario {record['scenario']}; allowed scenarios are {sorted(allowed)}"
        )


def _aliases(record: dict[str, Any]) -> Iterable[tuple[str, str]]:
    correlation = record["correlation"] or {}
    values = set(correlation.items())
    if record["completion"] is not None:
        values.add(("closure", record["completion"]["closure"]))
    return sorted(values)


def _require(summary: dict[str, Any], section: str, field: str, callback: str) -> Any:
    value = summary[section].get(field)
    if value is None:
        raise ContractError(f"{callback} requires payload_summary.{section}.{field}")
    return value


def _allowed_app_states(callback: str) -> set[str] | None:
    if "did-finish-launching" in callback or "will-connect" in callback:
        return {"pre-application", "inactive"}
    if "did-become-active" in callback or "scene-did-activate" in callback:
        return {"active"}
    if "will-resign-active" in callback or "scene-will-deactivate" in callback:
        return {"active", "inactive"}
    if "did-enter-background" in callback:
        return {"background"}
    if "will-enter-foreground" in callback:
        return {"background", "inactive"}
    if "will-terminate" in callback:
        return {"active", "inactive", "background"}
    if "did-disconnect" in callback:
        return {"inactive", "background"}
    return None


def _validate_payload(record: dict[str, Any], target_os_version: str | None = None) -> None:
    callback = record["callback"]
    summary = record["payload_summary"]
    lower = callback.lower()
    flags = summary["flags"]
    counts = summary["counts"]
    enums = summary["enums"]
    if target_os_version is not None:
        minimum_major = CALLBACK_MIN_IOS_MAJOR.get(callback)
        target_major = int(target_os_version.split(".", 1)[0])
        if minimum_major is not None and target_major < minimum_major:
            raise ContractError(
                f"{callback} requires iOS {minimum_major} or newer, target is {target_os_version}"
            )

    def reject_none_when_present(flag: str, fields: tuple[str, ...], label: str) -> None:
        if flags.get(flag) is True:
            for field in fields:
                if enums.get(field) == "none":
                    raise ContractError(f"{callback} {label} presence cannot use {field}=none")

    def require_absent_values(
        flag: str,
        enum_fields: tuple[str, ...] = (),
        count_fields: tuple[str, ...] = (),
    ) -> None:
        if flags.get(flag) is False:
            for field in enum_fields:
                if field in enums and enums[field] != "none":
                    raise ContractError(f"{callback} {flag}=false requires {field}=none")
            for field in count_fields:
                if field in counts and counts[field] != 0:
                    raise ContractError(f"{callback} {flag}=false requires {field}=0")

    reject_none_when_present("has_url", ("url_scheme", "url_class"), "URL")
    reject_none_when_present("has_user_activity", ("activity_class",), "user activity")
    reject_none_when_present("has_shortcut", ("action_class",), "quick action")
    reject_none_when_present("has_scene", ("scene_state", "scene_role"), "scene")
    reject_none_when_present(
        "has_notification", ("notification_origin", "notification_class"), "notification"
    )
    require_absent_values(
        "has_url", ("url_scheme", "url_class"),
        ("url_path_components", "url_query_items", "url_contexts"),
    )
    require_absent_values("has_user_activity", ("activity_class",), ("user_activities",))
    require_absent_values("has_shortcut", ("action_class",))
    require_absent_values("has_scene", ("scene_state", "scene_role"), ("connected_scenes",))
    require_absent_values(
        "has_notification", ("notification_origin", "notification_class"),
        ("notification_user_info_keys",),
    )
    require_absent_values("has_device_token", count_fields=("device_token_bytes",))
    require_absent_values("has_fcm_token", count_fields=("fcm_token_characters",))
    if flags.get("has_notification_response") is True and flags.get("has_notification") is not True:
        raise ContractError(f"{callback} notification response requires has_notification=true")
    if flags.get("has_device_token") is True and counts.get("device_token_bytes", 0) < 1:
        raise ContractError(f"{callback} device token presence requires device_token_bytes >= 1")
    if flags.get("has_fcm_token") is True and counts.get("fcm_token_characters", 0) < 1:
        raise ContractError(f"{callback} FCM token presence requires fcm_token_characters >= 1")
    if flags.get("has_user_activity") is True and counts.get("user_activities", 0) < 1:
        raise ContractError(f"{callback} user activity presence requires user_activities >= 1")

    connection_options_url = (
        callback == "scene.will-connect"
        and record["scenario"] in CUSTOM_URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS)
    )
    url_callback = (
        "open-url" in lower or "route-url" in lower or callback == "swiftui.on-open-url"
        or callback in ("customerio.route-deep-link", "wrapper.app-received-url")
        or connection_options_url
    )
    if url_callback:
        if _require(summary, "flags", "has_url", callback) is not True:
            raise ContractError(f"{callback} requires has_url=true")
        _require(summary, "counts", "url_path_components", callback)
        _require(summary, "counts", "url_query_items", callback)
        scheme = _require(summary, "enums", "url_scheme", callback)
        url_class = _require(summary, "enums", "url_class", callback)
        if scheme in ("unknown", "none") or url_class == "none":
            raise ContractError(f"{callback} requires a classified URL scheme and class")
        if url_class == "web" and scheme not in ("http", "https"):
            raise ContractError(f"{callback} url_class=web requires an HTTP(S) scheme")
        if url_class in ("custom-scheme", "cio-live-activity") and scheme != "custom":
            raise ContractError(f"{callback} {url_class} requires url_scheme=custom")
        scenario = record["scenario"]
        if scenario.startswith("custom-url-") and (
            url_class != "custom-scheme" or scheme != "custom"
        ):
            raise ContractError(
                f"{callback} custom URL scenario requires custom scheme/class"
            )
        if scenario.startswith("universal-link-") and (
            url_class != "web" or scheme not in ("http", "https")
        ):
            raise ContractError(
                f"{callback} Universal Link URL seat requires HTTP(S) web classification"
            )
        if scenario.startswith("live-activity-tap-") and url_class != "cio-live-activity":
            raise ContractError(f"{callback} live activity scenario requires url_class=cio-live-activity")

    if callback in {"host.route-url", "customerio.route-deep-link"}:
        has_redirect = _require(summary, "flags", "has_redirect", callback)
        if not isinstance(has_redirect, bool):
            raise ContractError(f"{callback} requires boolean has_redirect classification")
        if record["phase"] == "intent":
            if "handled" in flags or "result" in enums:
                raise ContractError(
                    f"{callback} intent carries classification only; outcome belongs on result"
                )
        elif record["phase"] == "result":
            handled = _require(summary, "flags", "handled", callback)
            result = _require(summary, "enums", "result", callback)
            if callback == "customerio.route-deep-link" and has_redirect:
                if handled is not True or result != "redirect":
                    raise ContractError(
                        "Customer.io redirect result requires handled=true and result=redirect"
                    )
            else:
                expected_result = "handled" if handled else "unhandled"
                if result != expected_result:
                    raise ContractError(
                        f"{callback} result={result} contradicts handled={handled}"
                    )

    connection_options_activity = (
        callback == "scene.will-connect" and record["scenario"] in UNIVERSAL_LINK_SCENARIOS
    )
    if "user-activity" in lower or connection_options_activity:
        if _require(summary, "flags", "has_user_activity", callback) is not True:
            raise ContractError(f"{callback} requires has_user_activity=true")
        if _require(summary, "counts", "user_activities", callback) < 1:
            raise ContractError(f"{callback} requires user_activities >= 1")
        activity_class = _require(summary, "enums", "activity_class", callback)
        if activity_class == "none":
            raise ContractError(f"{callback} requires activity_class other than none")
        if record["scenario"].startswith("universal-link-") and activity_class != "web-browsing":
            raise ContractError(f"{callback} universal link scenario requires activity_class=web-browsing")

    connection_options_action = (
        callback == "scene.will-connect" and record["scenario"] in QUICK_ACTION_SCENARIOS
    )
    if "quick-action" in lower or connection_options_action:
        if _require(summary, "flags", "has_shortcut", callback) is not True:
            raise ContractError(f"{callback} requires has_shortcut=true")
        if _require(summary, "enums", "action_class", callback) == "none":
            raise ContractError(f"{callback} requires action_class other than none")

    if callback == "scene.will-connect" and record["scenario"] in COLD_START_SCENARIOS:
        allowed_connection_flags: set[str]
        if record["scenario"] in CUSTOM_URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS):
            allowed_connection_flags = {"has_url"}
        elif record["scenario"] in UNIVERSAL_LINK_SCENARIOS:
            allowed_connection_flags = {"has_user_activity"}
        elif record["scenario"] in QUICK_ACTION_SCENARIOS:
            allowed_connection_flags = {"has_shortcut"}
        elif record["scenario"] in REMOTE_SCENARIOS.union(LOCAL_SCENARIOS):
            allowed_connection_flags = {"has_notification", "has_notification_response"}
        else:
            allowed_connection_flags = set()
        for flag in (
            "has_url", "has_user_activity", "has_shortcut",
            "has_notification", "has_notification_response",
        ):
            if flags.get(flag) is True and flag not in allowed_connection_flags:
                raise ContractError(
                    f"scene.will-connect scenario {record['scenario']} forbids connectionOptions {flag}"
                )

    token_success = (
        "did-register-for-remote-notifications" in lower
        or callback == "apns.device-token-registered"
    )
    if token_success:
        if _require(summary, "flags", "has_device_token", callback) is not True:
            raise ContractError(f"{callback} requires has_device_token=true")
        if _require(summary, "counts", "device_token_bytes", callback) < 1:
            raise ContractError(f"{callback} requires device_token_bytes >= 1")
    if callback == "fcm.registration-token-refreshed":
        if _require(summary, "flags", "has_fcm_token", callback) is not True:
            raise ContractError(f"{callback} requires has_fcm_token=true")
        if _require(summary, "counts", "fcm_token_characters", callback) < 1:
            raise ContractError(f"{callback} requires fcm_token_characters >= 1")
    if callback == "customerio.register-device-token":
        if record["provider"] == "fcm":
            if _require(summary, "flags", "has_fcm_token", callback) is not True:
                raise ContractError(f"{callback} with FCM requires has_fcm_token=true")
            if _require(summary, "counts", "fcm_token_characters", callback) < 1:
                raise ContractError(f"{callback} with FCM requires fcm_token_characters >= 1")
        elif record["provider"] == "apn":
            if _require(summary, "flags", "has_device_token", callback) is not True:
                raise ContractError(f"{callback} with APN requires has_device_token=true")
            if _require(summary, "counts", "device_token_bytes", callback) < 1:
                raise ContractError(f"{callback} with APN requires device_token_bytes >= 1")
        else:
            raise ContractError(f"{callback} requires provider apn or fcm")

    registration_failure = "did-fail-to-register-for-remote-notifications" in lower or callback == "apns.device-token-registration-failed"
    if registration_failure:
        if summary["enums"].get("error_class") != "registration" or summary["enums"].get("result") != "failure":
            raise ContractError(f"{callback} requires registration/failure summary")

    state_callback = (
        "did-finish-launching" in callback
        or callback.endswith("did-become-active") or callback.endswith("will-resign-active")
        or callback.endswith("did-enter-background") or callback.endswith("will-enter-foreground")
        or callback.endswith("will-terminate") or callback.endswith("scene-phase-change")
        or callback.endswith("app-lifecycle-state") or "did-become-active-notification" in callback
        or "will-resign-active-notification" in callback or "did-enter-background-notification" in callback
        or "will-enter-foreground-notification" in callback or "scene-did-activate-notification" in callback
        or "scene-will-deactivate-notification" in callback or "scene-did-enter-background-notification" in callback
        or "scene-will-enter-foreground-notification" in callback or "will-terminate-notification" in callback
        or "did-disconnect-notification" in callback or "did-become-active-forwarded" in callback
        or "will-resign-active-forwarded" in callback or "did-enter-background-forwarded" in callback
        or "will-enter-foreground-forwarded" in callback or "will-terminate-forwarded" in callback
        or "did-disconnect-forwarded" in callback
        or callback.startswith("expo.subscriber.did-become-active")
        or callback.startswith("expo.subscriber.will-resign-active")
        or callback.startswith("expo.subscriber.did-enter-background")
        or callback.startswith("expo.subscriber.will-enter-foreground")
    )
    if state_callback:
        app_state = _require(summary, "enums", "app_state", callback)
    else:
        app_state = enums.get("app_state")
    allowed_app_states = _allowed_app_states(callback)
    if (
        record["integration"] == "flutter"
        and record["scenario"] == "icon-cold-launch"
        and callback in {
            "application.did-finish-launching",
            "flutter.application.did-finish-launching-forwarded",
            "uikit.application-did-finish-launching-notification",
        }
    ):
        # The empirical scene-enabled Flutter launch enters while UIKit reports
        # background; the legacy app-delegate topology reports inactive.
        allowed_app_states = set(allowed_app_states or ()).union({"background"})
    if allowed_app_states is not None:
        app_state = _require(summary, "enums", "app_state", callback)
        if app_state not in allowed_app_states:
            raise ContractError(
                f"{callback} app_state={app_state} is incompatible; "
                f"allowed={sorted(allowed_app_states)}"
            )
    if callback in {
        "swiftui.scene-phase-change", "flutter.app-lifecycle-state",
        "wrapper.app-lifecycle-state",
    } and record["evidence_level"] in ("L2", "L3"):
        app_state = _require(summary, "enums", "app_state", callback)
        if app_state in {"unknown", "off-main-thread"}:
            raise ContractError(f"{callback} L2/L3 requires a concrete app_state")

    scene_callback = _is_scene_callback(callback)
    if scene_callback:
        if _require(summary, "flags", "has_scene", callback) is not True:
            raise ContractError(f"{callback} requires has_scene=true")
        _require(summary, "enums", "scene_state", callback)
        _require(summary, "enums", "scene_role", callback)

    notification_callback = any(fragment in lower for fragment in (
        "notification-center", "did-receive-remote-notification", "notification-received",
        "notification-response", "route-notification", "present-notification",
        "handle-notification", "app-received-notification", "last-notification",
        "initial-notification",
    )) and callback != "notification-center.settings"
    if notification_callback:
        if _require(summary, "flags", "has_notification", callback) is not True:
            raise ContractError(f"{callback} requires has_notification=true")
        response_callback = "response" in lower or "pulled" in lower
        wrapper_notification = callback in ("wrapper.app-received-notification", "host.route-notification")
        tap_scenario = record["scenario"] in {
            "push-tap-warm", "push-tap-cold",
            "local-notification-tap-warm", "local-notification-tap-cold",
        }
        if response_callback or (wrapper_notification and tap_scenario):
            if _require(summary, "flags", "has_notification_response", callback) is not True:
                raise ContractError(f"{callback} requires has_notification_response=true")
        if (
            flags.get("has_notification_response") is True
            and not response_callback
            and not (wrapper_notification and tap_scenario)
        ):
            raise ContractError(f"{callback} is not a notification-response seat")
        origin = _require(summary, "enums", "notification_origin", callback)
        notification_class = _require(summary, "enums", "notification_class", callback)
        delegate_peer = _require(summary, "enums", "delegate_peer", callback)
        if record["evidence_level"] in ("L2", "L3") and (
            origin in ("unknown", "none") or notification_class in ("unknown", "none")
            or delegate_peer in ("framework-other", "unknown", "none")
        ):
            raise ContractError(
                f"{callback} L2/L3 notification summary requires an attested named delegate peer"
            )
        if record["scenario"] in REMOTE_SCENARIOS and origin != "remote":
            raise ContractError(f"{callback} remote scenario requires notification_origin=remote")
        if record["scenario"] in LOCAL_SCENARIOS and origin != "local":
            raise ContractError(f"{callback} local scenario requires notification_origin=local")
        if callback in REMOTE_NOTIFICATION_CALLBACKS and origin != "remote":
            raise ContractError(
                f"{callback} always requires notification_origin=remote"
            )
        if (
            record["scenario"] in {"push-tap-warm", "push-tap-cold"}
            and flags.get("has_notification_response") is True
        ):
            action_class = _require(summary, "enums", "action_class", callback)
            if action_class != "default":
                raise ContractError(
                    f"{callback} push-tap acceptance requires action_class=default"
                )

    if callback == "customerio.handle-notification-response":
        if record["phase"] != "result" or summary["enums"].get("result") != "handled":
            raise ContractError(
                "customerio.handle-notification-response requires phase=result and result=handled"
            )
        if summary["enums"].get("notification_class") != "customerio":
            raise ContractError(
                "customerio.handle-notification-response requires notification_class=customerio"
            )

    if callback == "expo.last-notification-response-pulled":
        if record["scenario"] not in {
            "push-tap-cold", "local-notification-tap-cold",
        }:
            raise ContractError(f"{callback} is valid only for a cold notification-tap scenario")
        _require(summary, "enums", "app_state", callback)

    presentation_names = (
        "presentation_alert", "presentation_badge", "presentation_sound",
        "presentation_banner", "presentation_list",
    )
    has_presentation_facts = any(name in flags for name in presentation_names) or (
        "presentation_options" in counts or "presentation_class" in enums
    )
    if target_os_version is not None and int(target_os_version.split(".", 1)[0]) < 14:
        if flags.get("presentation_banner") is True or flags.get("presentation_list") is True:
            raise ContractError("iOS 13 requires presentation_banner/list=false on every callback seat")
    if callback != "host.present-notification" and has_presentation_facts:
        raise ContractError("presentation facts are valid only on host.present-notification")

    if callback == "host.present-notification":
        for name in presentation_names:
            _require(summary, "flags", name, callback)
        expected = sum(1 for name in presentation_names if flags[name])
        if summary["counts"].get("presentation_options") != expected:
            raise ContractError("host.present-notification presentation count must equal exact flags")
        expected_class = "visible" if expected else "suppressed"
        presentation_class = _require(summary, "enums", "presentation_class", callback)
        if presentation_class != expected_class:
            raise ContractError(
                "host.present-notification presentation_class must match exact flags/count"
            )

    if callback == "host.background-fetch-completion-result":
        if summary["enums"].get("result") not in ("new-data", "no-data", "failure"):
            raise ContractError("background-fetch completion result must be new-data, no-data, or failure")


def _validate_stream(
    manifest: dict[str, Any],
    declaration: dict[str, Any],
    records: list[dict[str, Any]],
    started: datetime,
    ended: datetime,
) -> None:
    stream_id = declaration["stream_id"]
    start_indexes = [
        index for index, record in enumerate(records)
        if record["callback"] == "trace.scenario-start"
    ]
    end_indexes = [
        index for index, record in enumerate(records)
        if record["callback"] == "trace.scenario-end"
    ]
    if start_indexes != [0] or end_indexes != [len(records) - 1]:
        raise ContractError(
            f"stream {stream_id} must contain exactly one leading scenario-start "
            "and one final scenario-end"
        )
    if records[0]["callback"] != "trace.scenario-start" or records[0]["sequence"] != 1:
        raise ContractError(f"stream {stream_id} must start with trace.scenario-start at sequence 1")
    if records[-1]["callback"] != "trace.scenario-end":
        raise ContractError(f"stream {stream_id} is missing its final scenario-end record")
    if records[0]["recorder"]["dropped_records_total"] != 0:
        raise ContractError(f"stream {stream_id} must start with zero drops")
    initial = records[0]
    initial_recorder = initial["recorder"]
    if (
        initial["correlation"] is not None
        or any(initial_recorder["alias_counts"].values())
        or initial_recorder["alias_overflow"]
        or initial_recorder["alias_overflow_namespaces"]
        or initial_recorder["buffer_high_watermark"] != 1
    ):
        raise ContractError(
            f"stream {stream_id}: scenario-start must have pristine correlation and alias state"
        )
    if manifest["evidence_level"] in ("L2", "L3") and not any(
        record["kind"] != "trace-control" for record in records
    ):
        raise ContractError(f"stream {stream_id}: L2/L3 requires a non-control runtime observation")
    if (
        manifest["evidence_level"] in ("L2", "L3")
        and declaration["runtime"] == "swift"
    ):
        actual_scene_manifest = initial["payload_summary"]["flags"].get(
            "scene_manifest_active"
        )
        expected_scene_manifest = manifest["host_topology"] == "ui-scene"
        if actual_scene_manifest is not expected_scene_manifest:
            raise ContractError(
                f"stream {stream_id}: scene_manifest_active must match declared host_topology"
            )

    expected_stable = {
        "manifest_id": manifest["manifest_id"], "run_id": manifest["run_id"],
        "stream_id": stream_id, "process_id": declaration["process_id"],
        "integration": declaration["integration"], "runtime": declaration["runtime"],
        "provider": declaration["provider"], "scenario": manifest["scenario"],
        "evidence_level": manifest["evidence_level"],
    }
    previous_sequence = 0
    previous_monotonic = -1
    previous_captured: datetime | None = None
    previous_drops = 0
    previous_high_water = 0
    previous_alias_counts = {kind: 0 for kind in ALIAS_KINDS}
    previous_overflow_namespaces: set[str] = set()
    capacity: int | None = None
    record_by_sequence: dict[int, dict[str, Any]] = {}
    observed_alias_ordinals: dict[str, set[int]] = {kind: set() for kind in ALIAS_KINDS}
    last_new_alias_ordinal = {kind: 0 for kind in ALIAS_KINDS}
    completion_parent_by_closure: dict[str, int] = {}
    completion_outcomes: dict[str, list[str]] = defaultdict(list)
    fixture_creations: dict[str, int] = {}
    fixture_creation_drops: dict[str, int] = {}
    stimulus_time = _parse_time(
        manifest["stimulus"]["initiated_at"], "manifest.stimulus.initiated_at"
    )
    receipt_value = manifest["provider_provenance"]["receipt_recorded_at"]
    receipt_time = (
        _parse_time(receipt_value, "manifest.provider_provenance.receipt_recorded_at")
        if receipt_value is not None else None
    )
    acceptance_barrier = max(
        value for value in (stimulus_time, receipt_time) if value is not None
    )
    frameworks = {item["name"]: item for item in manifest["frameworks"]}

    for record_index, record in enumerate(records):
        sequence = record["sequence"]
        for field in STABLE_RECORD_FIELDS:
            if record[field] != expected_stable[field]:
                raise ContractError(f"stream {stream_id} sequence {sequence}: unstable {field}")
        _validate_callback_rule(record)
        _validate_scenario_bound_callback(record)
        _validate_payload(record, manifest["target"]["os_version"])

        delegate_peer = record["payload_summary"]["enums"].get("delegate_peer")
        peer_requirement = DELEGATE_PEER_FRAMEWORKS.get(delegate_peer)
        if peer_requirement is not None:
            peer_name, peer_role = peer_requirement
            peer = frameworks.get(peer_name)
            if peer is None or peer["role"] != peer_role:
                raise ContractError(
                    f"stream {stream_id} sequence {sequence}: delegate_peer={delegate_peer} "
                    f"requires manifest framework {peer_name} role={peer_role}"
                )
        if record["callback"] == "fcm.registration-token-refreshed":
            fcm_peer = frameworks.get("firebase-ios-sdk-messaging")
            if fcm_peer is None or fcm_peer["role"] != "peer":
                raise ContractError(
                    f"stream {stream_id} sequence {sequence}: "
                    "fcm.registration-token-refreshed requires manifest framework "
                    "firebase-ios-sdk-messaging role=peer"
                )

        captured = _parse_time(record["captured_at"], f"stream {stream_id} sequence {sequence}")
        if not started <= captured <= ended:
            raise ContractError(f"stream {stream_id} sequence {sequence}: captured_at outside run bounds")
        if previous_captured is not None and captured < previous_captured:
            raise ContractError(f"stream {stream_id}: captured_at decreased")
        if sequence in record_by_sequence or sequence <= previous_sequence:
            raise ContractError(f"stream {stream_id}: sequence output is not unique FIFO order")
        if record["monotonic_ms"] < previous_monotonic:
            raise ContractError(f"stream {stream_id}: monotonic_ms decreased")
        if record["kind"] != "trace-control" and captured < acceptance_barrier:
            raise ContractError(
                f"stream {stream_id} sequence {sequence}: runtime observation predates "
                "the stimulus/provider acceptance barrier"
            )
        if record["callback"] == "trace.scenario-end" and captured < acceptance_barrier:
            raise ContractError(
                f"stream {stream_id}: scenario-end predates the stimulus/provider acceptance barrier"
            )
        if (
            record_index == 0 and manifest["scenario"] in COLD_START_SCENARIOS
            and captured < acceptance_barrier
        ):
            raise ContractError(
                f"stream {stream_id}: cold-start scenario-start predates the stimulus/provider barrier"
            )

        recorder = record["recorder"]
        drops = recorder["dropped_records_total"]
        gap = sequence - previous_sequence - 1
        drop_delta = drops - previous_drops
        if gap != drop_delta:
            raise ContractError(f"stream {stream_id}: sequence gap {gap} is not accounted by drop delta {drop_delta}")
        if recorder["buffer_high_watermark"] < previous_high_water:
            raise ContractError(f"stream {stream_id}: buffer high-water mark decreased")
        if recorder["buffer_high_watermark"] < 1:
            raise ContractError(f"stream {stream_id}: non-empty stream requires buffer high-water >= 1")
        if recorder["buffer_high_watermark"] > recorder["buffer_capacity"]:
            raise ContractError(f"stream {stream_id}: buffer high-water exceeds capacity")
        if recorder["buffer_high_watermark"] > sequence:
            raise ContractError(
                f"stream {stream_id}: buffer high-water exceeds assigned sequence volume"
            )
        if drops > 0 and recorder["buffer_high_watermark"] != recorder["buffer_capacity"]:
            raise ContractError(
                f"stream {stream_id}: drop-oldest accounting requires high-water to reach capacity"
            )
        if drops > 0 and sequence < recorder["buffer_capacity"] + drops:
            raise ContractError(
                f"stream {stream_id}: drop-oldest accounting requires at least "
                "capacity + cumulative drops assigned sequences"
            )
        if capacity is None:
            capacity = recorder["buffer_capacity"]
        elif recorder["buffer_capacity"] != capacity:
            raise ContractError(f"stream {stream_id}: buffer capacity changed")

        counts = recorder["alias_counts"]
        overflow_namespaces = set(recorder["alias_overflow_namespaces"])
        canonical_overflow_order = [kind for kind in ALIAS_KINDS if kind in overflow_namespaces]
        if recorder["alias_overflow_namespaces"] != canonical_overflow_order:
            raise ContractError(f"stream {stream_id}: overflow namespaces are not in canonical order")
        if recorder["alias_overflow"] != bool(overflow_namespaces):
            raise ContractError(f"stream {stream_id}: alias_overflow must match overflow namespaces")
        if not previous_overflow_namespaces.issubset(overflow_namespaces):
            raise ContractError(f"stream {stream_id}: overflow namespaces are cumulative")
        for kind in ALIAS_KINDS:
            if counts[kind] < previous_alias_counts[kind]:
                raise ContractError(f"stream {stream_id}: cumulative {kind} alias count decreased")
            if kind in overflow_namespaces and counts[kind] != MAX_ALIASES_PER_KIND:
                raise ContractError(f"stream {stream_id}: false {kind} overflow below capacity")
        if manifest["evidence_level"] in ("L2", "L3") and (drops or overflow_namespaces):
            raise ContractError(f"stream {stream_id}: L2/L3 cannot contain drops or alias overflow")

        closure_alias = (record["correlation"] or {}).get("closure")
        if closure_alias is not None and (
            record["scenario"] != "unit-fixture"
            or record["kind"] not in ("fixture-control", "completion-fixture")
        ):
            raise ContractError(f"stream {stream_id}: closure aliases are fixture-only")
        if record["kind"] == "fixture-control":
            if closure_alias is None:
                raise ContractError(
                    f"stream {stream_id}: fixture.completion-created requires a closure alias"
                )
            if closure_alias in fixture_creations:
                raise ContractError(
                    f"stream {stream_id}: closure {closure_alias} has multiple creation records"
                )
            fixture_creations[closure_alias] = sequence
            fixture_creation_drops[closure_alias] = drops
        for kind, alias in _aliases(record):
            ordinal = int(alias.rsplit("-", 1)[1])
            if ordinal > counts[kind]:
                raise ContractError(f"stream {stream_id}: {alias} exceeds recorder alias count")
            if ordinal not in observed_alias_ordinals[kind]:
                if ordinal > previous_alias_counts[kind]:
                    if ordinal <= last_new_alias_ordinal[kind]:
                        raise ContractError(
                            f"stream {stream_id}: first-seen {kind} aliases are not ordinal"
                        )
                    last_new_alias_ordinal[kind] = ordinal
                observed_alias_ordinals[kind].add(ordinal)
        for kind in ALIAS_KINDS:
            missing_so_far = counts[kind] - len(observed_alias_ordinals[kind])
            if missing_so_far < 0 or missing_so_far > drops:
                raise ContractError(
                    f"stream {stream_id}: missing {kind} aliases exceed current dropped-record uncertainty"
                )

        completion = record["completion"]
        if completion is not None:
            closure = completion["closure"]
            if closure_alias != closure:
                raise ContractError(f"stream {stream_id}: completion closure is not correlated")
            parent_sequence = completion["parent_sequence"]
            parent = record_by_sequence.get(parent_sequence)
            if parent is None or parent_sequence >= sequence:
                raise ContractError(f"stream {stream_id}: completion parent is not earlier and emitted")
            if not (
                parent["kind"] == "fixture-control"
                and parent["owner"] == "fixture"
                and parent["callback"] == "fixture.completion-created"
                and (parent["correlation"] or {}).get("closure") == closure
            ):
                raise ContractError(f"stream {stream_id}: completion parent must be the exact fixture-control seat")
            stable_parent = completion_parent_by_closure.setdefault(closure, parent_sequence)
            if stable_parent != parent_sequence:
                raise ContractError(f"stream {stream_id}: completion parent changed within closure series")
            call_index = completion.get("call_index")
            prior_outcomes = completion_outcomes[closure]
            if completion["result"] == "not-invoked":
                if prior_outcomes:
                    raise ContractError(f"stream {stream_id}: not-invoked conflicts with an earlier outcome")
                prior_outcomes.append("not-invoked")
            else:
                if "not-invoked" in prior_outcomes:
                    raise ContractError(f"stream {stream_id}: invocation conflicts with not-invoked")
                expected_index = len(prior_outcomes) + 1
                if call_index != expected_index or completion["observed_call_count"] != call_index:
                    raise ContractError(f"stream {stream_id}: completion call index/count is not cumulative")
                prior_outcomes.append("invoked")

        record_by_sequence[sequence] = record
        previous_sequence = sequence
        previous_monotonic = record["monotonic_ms"]
        previous_captured = captured
        previous_drops = drops
        previous_high_water = recorder["buffer_high_watermark"]
        previous_alias_counts = dict(counts)
        previous_overflow_namespaces = overflow_namespaces

    final = records[-1]
    final_recorder = final["recorder"]
    total_drops = final_recorder["dropped_records_total"]
    for kind in ALIAS_KINDS:
        allocated = final_recorder["alias_counts"][kind]
        observed = observed_alias_ordinals[kind]
        missing = allocated - len(observed)
        if missing < 0 or missing > total_drops:
            raise ContractError(f"stream {stream_id}: missing {kind} aliases exceed dropped-record uncertainty")
        if total_drops == 0 and observed != set(range(1, allocated + 1)):
            raise ContractError(f"stream {stream_id}: zero-drop {kind} aliases are not contiguous")
    if manifest["scenario"] == "unit-fixture":
        if not fixture_creations:
            raise ContractError(f"stream {stream_id}: unit-fixture requires a completion creation")
        if set(fixture_creations) != set(completion_outcomes):
            raise ContractError(
                f"stream {stream_id}: every completion creation needs exactly one nonempty outcome series"
            )
        for closure, outcomes in completion_outcomes.items():
            if outcomes == ["not-invoked"] and total_drops != fixture_creation_drops[closure]:
                raise ContractError(
                    f"stream {stream_id}: negative completion {closure} requires zero drops "
                    "from closure creation through final closeout"
                )
        if observed_alias_ordinals["closure"] != {
            int(alias.rsplit("-", 1)[1]) for alias in fixture_creations
        }:
            raise ContractError(
                f"stream {stream_id}: closure aliases must reconcile to fixture creations and outcomes"
            )

    receipt = declaration["receipt"]
    drained = _parse_time(receipt["drained_at"], f"stream {stream_id} receipt.drained_at")
    assert previous_captured is not None
    if not previous_captured <= drained <= ended:
        raise ContractError(f"stream {stream_id}: drain receipt time is incoherent")
    if drained < acceptance_barrier:
        raise ContractError(
            f"stream {stream_id}: post-drain receipt predates the stimulus/provider acceptance barrier"
        )
    expected = {
        "last_assigned_sequence": final["sequence"],
        "last_emitted_sequence": final["sequence"],
        "emitted_records": len(records),
        "dropped_records_total": final_recorder["dropped_records_total"],
        "buffer_high_watermark": final_recorder["buffer_high_watermark"],
        "buffer_capacity": final_recorder["buffer_capacity"],
        "alias_counts": final_recorder["alias_counts"],
        "alias_overflow": final_recorder["alias_overflow"],
        "alias_overflow_namespaces": final_recorder["alias_overflow_namespaces"],
    }
    for field, value in expected.items():
        if receipt[field] != value:
            raise ContractError(f"stream {stream_id}: post-drain receipt {field} does not match final recorder state")
    if receipt["emitted_records"] + receipt["dropped_records_total"] != receipt["last_assigned_sequence"]:
        raise ContractError(f"stream {stream_id}: post-drain receipt accounting does not balance")


def _validate_aggregates(
    manifest: dict[str, Any], records_by_stream: dict[str, list[dict[str, Any]]]
) -> None:
    for assertion in manifest["aggregate_assertions"]:
        counts = []
        for member in assertion["members"]:
            count = sum(
                1 for record in records_by_stream[member["stream_id"]]
                if record["callback"] == member["callback"] and record["phase"] == member["phase"]
                and (
                    "app_state" not in member
                    or record["payload_summary"]["enums"].get("app_state")
                    == member["app_state"]
                )
            )
            counts.append(count)
        expected = assertion["expected_count"]
        if any(count != expected for count in counts):
            raise ContractError(
                f"aggregate assertion {assertion['name']} expected exact count {expected}, observed {counts}"
            )


def _lifecycle_transition(record: dict[str, Any]) -> str | None:
    callback = record["callback"]
    if "did-enter-background" in callback:
        return "background"
    if "will-enter-foreground" in callback:
        return "foreground"
    if callback == "swiftui.scene-phase-change":
        state = record["payload_summary"]["enums"].get("app_state")
        if state == "background":
            return "background"
        if state == "active":
            return "foreground"
        return None
    if callback in {"wrapper.app-lifecycle-state", "flutter.app-lifecycle-state"}:
        state = record["payload_summary"]["enums"].get("app_state")
        if state == "background":
            return "background"
        if state in ("active", "inactive"):
            return "foreground"
    return None


def _handoff_facts(record: dict[str, Any], scenario: str) -> dict[str, Any]:
    summary = record["payload_summary"]
    flags = summary["flags"]
    counts = summary["counts"]
    enums = summary["enums"]
    if scenario in REMOTE_SCENARIOS.union(LOCAL_SCENARIOS):
        return {
            "has_notification": flags.get("has_notification"),
            "has_notification_response": flags.get("has_notification_response", False),
            "notification_origin": enums.get("notification_origin"),
            "notification_class": enums.get("notification_class"),
            "action_class": enums.get("action_class"),
        }
    if scenario in CUSTOM_URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS):
        return {
            "has_url": flags.get("has_url"),
            "url_scheme": enums.get("url_scheme"),
            "url_class": enums.get("url_class"),
            "url_path_components": counts.get("url_path_components"),
            "url_query_items": counts.get("url_query_items"),
        }
    callback = record["callback"]
    if scenario in UNIVERSAL_LINK_SCENARIOS and (
        callback in {"swiftui.on-open-url", "wrapper.app-received-url"}
        or "open-url" in callback
        or "route-url" in callback
        or "deep-link" in callback
    ):
        return {
            "has_url": flags.get("has_url"),
            "url_scheme": enums.get("url_scheme"),
            "url_class": enums.get("url_class"),
            "url_path_components": counts.get("url_path_components"),
            "url_query_items": counts.get("url_query_items"),
        }
    if scenario in UNIVERSAL_LINK_SCENARIOS:
        return {
            "has_user_activity": flags.get("has_user_activity"),
            "activity_class": enums.get("activity_class"),
            "user_activities": counts.get("user_activities"),
        }
    if scenario in QUICK_ACTION_SCENARIOS:
        return {
            "has_shortcut": flags.get("has_shortcut"),
            "action_class": enums.get("action_class"),
        }
    if scenario == "app-background-foreground":
        return {"lifecycle_transition": _lifecycle_transition(record)}
    if scenario == "icon-cold-launch":
        # The native launch forward is observed while UIKit is inactive. The
        # wrapper receipt is deliberately terminal and therefore active. State
        # progression is validated explicitly instead of requiring equality.
        return {}
    return {}


def _validate_icon_launch_handoff(
    native_record: dict[str, Any],
    wrapper_record: dict[str, Any],
    integration: str,
    host_topology: str,
) -> None:
    native_state = native_record["payload_summary"]["enums"].get("app_state")
    expected_native_state = (
        "background"
        if integration == "flutter" and host_topology == "ui-scene"
        else "inactive"
    )
    if native_state != expected_native_state:
        raise ContractError(
            "icon-cold-launch native launch forwarding requires "
            f"app_state={expected_native_state} for {integration} topology"
        )
    if integration == "expo":
        wrapper_state = wrapper_record["payload_summary"]["enums"].get("app_state")
        if wrapper_state != "active":
            raise ContractError(
                "icon-cold-launch wrapper lifecycle receipt requires app_state=active"
            )
    _require_capture_time_order(
        native_record, wrapper_record, "icon-cold-launch native to wrapper progression"
    )


def _validate_icon_launch_native_forward(
    raw_record: dict[str, Any], forwarded_record: dict[str, Any], integration: str
) -> None:
    raw_state = raw_record["payload_summary"]["enums"].get("app_state")
    forwarded_state = forwarded_record["payload_summary"]["enums"].get("app_state")
    if raw_record["callback"] == "scene.will-connect":
        if integration == "flutter" and (
            raw_state != "pre-application" or forwarded_state != "pre-application"
        ):
            raise ContractError(
                "icon-cold-launch Flutter scene forwarding requires app_state=pre-application"
            )
        if raw_record["payload_summary"] != forwarded_record["payload_summary"]:
            raise ContractError(
                "icon-cold-launch scene forwarding must preserve payload summary"
            )
        return
    allowed_states = {"inactive", "background"} if integration == "flutter" else {"inactive"}
    if raw_state not in allowed_states:
        raise ContractError(
            "icon-cold-launch raw application entry has incompatible app_state"
        )
    if forwarded_state != raw_state:
        raise ContractError(
            "icon-cold-launch native launch forwarding must preserve app_state"
        )


def _record_matches_member(record: dict[str, Any], member: dict[str, Any]) -> bool:
    return (
        record["callback"] == member["callback"]
        and record["phase"] == member["phase"]
        and (
            "app_state" not in member
            or record["payload_summary"]["enums"].get("app_state")
            == member["app_state"]
        )
    )


def _require_order(before: dict[str, Any], after: dict[str, Any], label: str) -> None:
    if before.get("sequence") is not None and after.get("sequence") is not None:
        if before["sequence"] >= after["sequence"]:
            raise ContractError(f"{label} requires causal sequence ordering")


def _require_capture_time_order(
    before: dict[str, Any], after: dict[str, Any], label: str
) -> None:
    """Require wall-clock order for two streams in one declared process instance."""
    before_value = before.get("captured_at")
    after_value = after.get("captured_at")
    if before_value is None or after_value is None:
        return
    if _parse_time(before_value, f"{label} source") >= _parse_time(
        after_value, f"{label} target"
    ):
        raise ContractError(f"{label} requires causal capture-time ordering")


def _validate_cold_flutter_icon_topology(
    native_records: list[dict[str, Any]],
    wrapper_records: list[dict[str, Any]],
    host_topology: str,
) -> None:
    """Require the explicitly declared Flutter icon-launch order."""

    def exact(
        records: list[dict[str, Any]], callback: str, phase: str
    ) -> dict[str, Any]:
        matches = [
            record for record in records
            if record["callback"] == callback and record["phase"] == phase
        ]
        if len(matches) != 1:
            raise ContractError(
                "cold Flutter icon launch requires exactly one "
                f"{callback} phase={phase}, observed {len(matches)}"
            )
        return matches[0]

    application = exact(native_records, "application.did-finish-launching", "entry")
    application_forward = exact(
        native_records, "flutter.application.did-finish-launching-forwarded", "entry"
    )
    application_notification = exact(
        native_records, "uikit.application-did-finish-launching-notification", "entry"
    )
    engine = exact(native_records, "flutter.implicit-engine-created", "result")
    plugin = exact(native_records, "flutter.plugin-registered", "result")
    application_active = exact(
        native_records, "uikit.application-did-become-active-notification", "state-change"
    )
    dart_main = exact(wrapper_records, "flutter.dart-main-entered", "entry")

    scene_entries = [
        record for record in native_records
        if record["callback"] == "scene.will-connect" and record["phase"] == "entry"
    ]
    scene_forwards = [
        record for record in native_records
        if record["callback"] == "flutter.scene.will-connect-forwarded"
        and record["phase"] == "entry"
    ]
    if len(scene_entries) != len(scene_forwards) or len(scene_entries) > 1:
        raise ContractError(
            "cold Flutter icon launch requires either no scene connection seats or "
            "exactly one raw and forwarded scene connection seat"
        )
    expects_scene = host_topology == "ui-scene"
    if bool(scene_entries) != expects_scene:
        raise ContractError(
            "cold Flutter icon launch scene seats must match declared host_topology"
        )

    if scene_entries:
        ordered = (
            application,
            plugin,
            application_forward,
            application_notification,
            engine,
            scene_entries[0],
            scene_forwards[0],
            application_active,
        )
        label = "cold Flutter scene icon topology"
        expected_launch_state = "background"
        for record in (scene_entries[0], scene_forwards[0]):
            app_state = record["payload_summary"]["enums"].get("app_state")
            if app_state != "pre-application":
                raise ContractError(
                    f"{label} requires {record['callback']} "
                    f"app_state=pre-application, observed {app_state}"
                )
        if scene_entries[0]["payload_summary"] != scene_forwards[0]["payload_summary"]:
            raise ContractError(
                "cold Flutter scene icon forwarding must preserve payload summary"
            )
    else:
        ordered = (
            engine,
            plugin,
            application,
            application_forward,
            application_notification,
            application_active,
        )
        label = "cold Flutter legacy icon topology"
        expected_launch_state = "inactive"

    for record in (application, application_forward, application_notification):
        app_state = record["payload_summary"]["enums"].get("app_state")
        if app_state != expected_launch_state:
            raise ContractError(
                f"{label} requires {record['callback']} "
                f"app_state={expected_launch_state}, observed {app_state}"
            )

    for before, after in zip(ordered, ordered[1:]):
        _require_order(before, after, label)
    _require_capture_time_order(
        application_active,
        dart_main,
        "cold Flutter UIKit active notification to Dart main",
    )


def _require_same_correlation(
    source: dict[str, Any],
    target: dict[str, Any],
    keys: tuple[str, ...],
    label: str,
) -> None:
    source_correlation = source.get("correlation") or {}
    target_correlation = target.get("correlation") or {}
    remaining = keys
    if "occurrence" in keys:
        occurrence = source_correlation.get("occurrence")
        if occurrence is None:
            raise ContractError(f"{label} requires correlation.occurrence")
        if target_correlation.get("occurrence") != occurrence:
            raise ContractError(f"{label} must preserve correlation.occurrence")
        remaining = tuple(key for key in keys if key != "occurrence")
        if not remaining:
            return
    key = next((candidate for candidate in remaining if source_correlation.get(candidate)), None)
    if key is None:
        raise ContractError(f"{label} requires a non-null {remaining} correlation alias")
    if target_correlation.get(key) != source_correlation[key]:
        raise ContractError(f"{label} must preserve correlation.{key}")


def _has_same_correlation(
    source: dict[str, Any], target: dict[str, Any], keys: tuple[str, ...]
) -> bool:
    """Return whether a possible forwarding pair preserves one available alias."""
    source_correlation = source.get("correlation") or {}
    target_correlation = target.get("correlation") or {}
    remaining = keys
    if "occurrence" in keys:
        occurrence = source_correlation.get("occurrence")
        if occurrence is None or target_correlation.get("occurrence") != occurrence:
            return False
        remaining = tuple(key for key in keys if key != "occurrence")
        if not remaining:
            return True
    for key in remaining:
        value = source_correlation.get(key)
        if value is not None:
            return target_correlation.get(key) == value
    return not remaining


def _native_stream_records(
    manifest: dict[str, Any], records_by_stream: dict[str, list[dict[str, Any]]]
) -> list[dict[str, Any]]:
    swift_ids = [
        declaration["stream_id"] for declaration in manifest["streams"]
        if declaration["runtime"] == "swift"
    ]
    if len(swift_ids) != 1:
        raise ContractError("L2/L3 acceptance requires exactly one canonical Swift stream")
    return records_by_stream[swift_ids[0]]


def _raw_ingress_groups(scenario: str, host_topology: str) -> list[set[str]]:
    if scenario == "icon-cold-launch":
        return [LAUNCH_DEFINING]
    if scenario in {"push-foreground", "local-notification-foreground"}:
        return [{"notification-center.will-present"}]
    if scenario in {
        "push-tap-warm", "push-tap-cold",
        "local-notification-tap-warm", "local-notification-tap-cold",
    }:
        return [{"notification-center.did-receive-response"}]
    if scenario in CUSTOM_URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS):
        if host_topology == "app-delegate-only":
            return [{"application.open-url"}]
        if host_topology == "ui-scene":
            return [{"scene.will-connect" if scenario in COLD_START_SCENARIOS else "scene.open-url-contexts"}]
        return [{"swiftui.on-open-url"}]
    if scenario in UNIVERSAL_LINK_SCENARIOS:
        if host_topology == "app-delegate-only":
            return [{"application.continue-user-activity"}]
        if host_topology == "ui-scene":
            return [{"scene.will-connect" if scenario in COLD_START_SCENARIOS else "scene.continue-user-activity"}]
        return [{"swiftui.on-open-url"}]
    if scenario in QUICK_ACTION_SCENARIOS:
        if host_topology == "app-delegate-only":
            return [{"application.perform-quick-action"}]
        if host_topology == "ui-scene":
            return [{"scene.will-connect" if scenario in COLD_START_SCENARIOS else "scene.perform-quick-action"}]
        return []
    if scenario == "app-background-foreground":
        if host_topology == "app-delegate-only":
            return [
                {"application.did-enter-background"},
                {"application.will-enter-foreground"},
            ]
        if host_topology == "ui-scene":
            return [
                {"scene.did-enter-background"},
                {"scene.will-enter-foreground"},
            ]
        # SwiftUI expresses both transitions through one callback name. Its
        # background and active app_state seats are validated independently.
        return [{"swiftui.scene-phase-change"}]
    return []


def _scenario_correlation_keys(scenario: str) -> tuple[str, ...]:
    if scenario in REMOTE_SCENARIOS.union(LOCAL_SCENARIOS):
        return ("delivery", "request")
    if scenario in CUSTOM_URL_SCENARIOS.union(UNIVERSAL_LINK_SCENARIOS).union(
        LIVE_ACTIVITY_SCENARIOS
    ):
        return ("url",)
    if scenario in QUICK_ACTION_SCENARIOS:
        return ("request",)
    return ()


def _forward_correlation_keys(record: dict[str, Any], scenario: str) -> tuple[str, ...]:
    """Select correlation by the raw callback family, not unrelated scenario side effects."""
    callback = record["callback"]
    if callback in {
        "notification-center.will-present", "notification-center.did-receive-response",
        "application.did-receive-remote-notification",
    }:
        return ("occurrence", "delivery", "request")
    if callback == "application.did-finish-launching" or _lifecycle_transition(record) is not None:
        return ("occurrence",)
    return ("occurrence",) + _scenario_correlation_keys(scenario)


def _validate_native_causal_chains(
    manifest: dict[str, Any], records_by_stream: dict[str, list[dict[str, Any]]]
) -> None:
    """Validate causal chains that are meaningful only on complete capture records."""
    records = _native_stream_records(manifest, records_by_stream)
    if not records or any("sequence" not in record for record in records):
        return
    scenario = manifest["scenario"]

    def exact(callback: str, phase: str, label: str | None = None) -> dict[str, Any]:
        matches = [
            record for record in records
            if record["callback"] == callback and record["phase"] == phase
        ]
        if len(matches) != 1:
            raise ContractError(
                f"{label or callback} requires exactly one {callback} phase={phase}, "
                f"observed {len(matches)}"
            )
        return matches[0]

    if scenario in {"push-foreground", "local-notification-foreground"}:
        ingress = exact("notification-center.will-present", "entry")
        result = exact("host.present-notification", "result")
        _require_order(ingress, result, "notification presentation")
        if _handoff_facts(ingress, scenario) != _handoff_facts(result, scenario):
            raise ContractError("notification presentation must preserve safe classification facts")
        _require_same_correlation(
            ingress, result, ("delivery", "request"), "notification presentation"
        )

    if scenario in {"push-tap-warm", "push-tap-cold"}:
        ingress = exact("notification-center.did-receive-response", "entry")
        terminal = exact(
            "customerio.handle-notification-response", "result",
            "Customer.io push-tap terminal",
        )
        _require_order(ingress, terminal, "Customer.io push-tap handling")
        if _handoff_facts(ingress, scenario) != _handoff_facts(terminal, scenario):
            raise ContractError(
                "Customer.io push-tap handling must preserve default-action notification facts"
            )
        _require_same_correlation(
            ingress, terminal, ("delivery", "request"), "Customer.io push-tap handling"
        )

    if scenario == "background-fetch":
        ingress = exact("application.perform-background-fetch", "entry")
        result = exact("host.background-fetch-completion-result", "result")
        _require_order(ingress, result, "background-fetch completion")
        _require_same_correlation(ingress, result, ("request",), "background-fetch completion")

    if scenario == "token-registration":
        apns = exact("application.did-register-for-remote-notifications", "entry")
        result = exact("customerio.register-device-token", "result")
        provider = manifest["provider_provenance"]["provider"]
        source = apns
        if provider == "fcm":
            fcm = exact("fcm.registration-token-refreshed", "entry")
            _require_order(apns, fcm, "APNs to FCM registration")
            _require_same_correlation(
                apns, fcm, ("request",), "APNs to FCM registration"
            )
            source = fcm
        _require_order(source, result, "Customer.io token registration")
        source_flags = source["payload_summary"]["flags"]
        source_counts = source["payload_summary"]["counts"]
        result_flags = result["payload_summary"]["flags"]
        result_counts = result["payload_summary"]["counts"]
        token_fields = (
            ("has_fcm_token", "fcm_token_characters")
            if provider == "fcm" else ("has_device_token", "device_token_bytes")
        )
        if (
            source_flags.get(token_fields[0]) != result_flags.get(token_fields[0])
            or source_counts.get(token_fields[1]) != result_counts.get(token_fields[1])
        ):
            raise ContractError("Customer.io token registration must preserve provider token facts")
        _require_same_correlation(source, result, ("request",), "Customer.io token registration")

    if scenario == "app-background-foreground":
        backgrounds = [record for record in records if _lifecycle_transition(record) == "background"]
        foregrounds = [record for record in records if _lifecycle_transition(record) == "foreground"]
        if backgrounds and foregrounds and max(record["sequence"] for record in backgrounds) >= min(
            record["sequence"] for record in foregrounds
        ):
            raise ContractError("app background observations must precede foreground observations")

    if scenario in COLD_START_SCENARIOS and scenario != "icon-cold-launch":
        launch = exact("application.did-finish-launching", "entry")
        groups = _raw_ingress_groups(scenario, manifest["host_topology"])
        ingresses = [record for record in records if groups and record["callback"] in groups[0]]
        if len(ingresses) == 1:
            _require_order(launch, ingresses[0], "cold launch ingress")

    if manifest["host_topology"] == "ui-scene":
        scene_connections = [
            record for record in records
            if record["callback"] == "scene.will-connect" and record["phase"] == "entry"
        ]
        if scene_connections:
            launch = exact("application.did-finish-launching", "entry")
            if len(scene_connections) != 1:
                raise ContractError("ui-scene evidence requires exactly one scene.will-connect seat")
            _require_order(launch, scene_connections[0], "application launch to scene connection")

    if scenario in CUSTOM_URL_SCENARIOS.union(LIVE_ACTIVITY_SCENARIOS):
        ingress_callbacks = _raw_ingress_groups(scenario, manifest["host_topology"])[0]
        ingresses = [record for record in records if record["callback"] in ingress_callbacks]
        if len(ingresses) != 1:
            raise ContractError(f"{scenario} requires exactly one raw URL ingress")
        ingress = ingresses[0]
        host_intent = exact("host.route-url", "intent", "URL routing")
        host_result = exact("host.route-url", "result", "URL routing")
        _require_order(ingress, host_intent, "URL ingress to host routing")
        _require_order(host_intent, host_result, "host URL route intent/result")
        if (
            host_intent["payload_summary"]["flags"]["has_redirect"]
            != host_result["payload_summary"]["flags"]["has_redirect"]
        ):
            raise ContractError("host URL route intent/result has_redirect classification changed")
        routing_records = [host_intent, host_result]
        cio_intents = [
            record for record in records
            if record["callback"] == "customerio.route-deep-link" and record["phase"] == "intent"
        ]
        cio_results = [
            record for record in records
            if record["callback"] == "customerio.route-deep-link" and record["phase"] == "result"
        ]
        if scenario in LIVE_ACTIVITY_SCENARIOS:
            if len(cio_intents) != 1 or len(cio_results) != 1:
                raise ContractError(
                    "Live Activity routing requires exactly one Customer.io deep-link intent/result pair"
                )
        elif len(cio_intents) != len(cio_results) or len(cio_intents) > 1:
            raise ContractError(
                "custom URL Customer.io deep-link routing must be absent or one intent/result pair"
            )
        if cio_intents:
            _require_order(host_intent, cio_intents[0], "host to Customer.io URL route")
            _require_order(cio_intents[0], cio_results[0], "Customer.io URL route intent/result")
            _require_order(cio_results[0], host_result, "Customer.io to terminal host URL route")
            if (
                cio_intents[0]["payload_summary"]["flags"]["has_redirect"]
                != cio_results[0]["payload_summary"]["flags"]["has_redirect"]
            ):
                raise ContractError(
                    "Customer.io URL route intent/result has_redirect classification changed"
                )
            if (
                host_intent["payload_summary"]["flags"]["has_redirect"]
                != cio_intents[0]["payload_summary"]["flags"]["has_redirect"]
            ):
                raise ContractError(
                    "host and Customer.io URL route intent classifications disagree"
                )
            if (
                host_result["payload_summary"]["flags"]["handled"]
                != cio_results[0]["payload_summary"]["flags"]["handled"]
            ):
                raise ContractError(
                    "Customer.io and terminal host URL route handled outcomes disagree"
                )
            routing_records.extend((cio_intents[0], cio_results[0]))
        ingress_facts = _handoff_facts(ingress, scenario)
        for routed in routing_records:
            if _handoff_facts(routed, scenario) != ingress_facts:
                raise ContractError("URL routing must preserve ingress safe facts")
            _require_same_correlation(ingress, routed, ("url",), "URL routing")


def _validate_wrapper_forwarding_chain(
    manifest: dict[str, Any],
    records_by_stream: dict[str, list[dict[str, Any]]],
    topology: tuple[dict[str, Any], dict[str, Any]],
) -> None:
    native_declaration, wrapper_declaration = topology
    scenario = manifest["scenario"]
    integration = native_declaration["integration"]
    native_records = records_by_stream[native_declaration["stream_id"]]
    wrapper_records = records_by_stream[wrapper_declaration["stream_id"]]
    assertions = manifest["aggregate_assertions"]
    handoff = _scenario_handoff(scenario, integration)
    if handoff is None:
        raise ContractError(f"multi-stream L2/L3 scenario {scenario} has no canonical wrapper handoff")
    wrapper_callbacks = handoff[1]
    ingress_groups = _raw_ingress_groups(scenario, manifest["host_topology"])
    forward_registry = INTEGRATION_FORWARD_FOR_INGRESS[integration]

    allowed_forwards: set[str] = set()
    for group in ingress_groups:
        for callback in group:
            allowed_forwards.update(forward_registry.get(callback, ()))
    allowed_callbacks = allowed_forwards.union(wrapper_callbacks)

    selected_pairs: list[tuple[dict[str, Any], dict[str, Any], dict[str, Any]]] = []
    for assertion in assertions:
        members = assertion["members"]
        for member in members:
            if member["callback"] not in allowed_callbacks:
                raise ContractError(
                    f"aggregate assertion {assertion['name']} selects callback "
                    f"{member['callback']} unrelated to scenario {scenario}; the canonical "
                    f"{integration} forwarding chain is required"
                )
            if scenario == "app-background-foreground" and "app_state" not in member:
                raise ContractError(
                    "app-background-foreground aggregate selectors require app_state qualification"
                )
        if len(members) != 2:
            continue
        native_member = next(
            (
                member for member in members
                if member["stream_id"] == native_declaration["stream_id"]
                and member["callback"] in allowed_forwards
            ),
            None,
        )
        wrapper_member = next(
            (
                member for member in members
                if member["stream_id"] == wrapper_declaration["stream_id"]
                and member["callback"] in wrapper_callbacks
            ),
            None,
        )
        if native_member is None or wrapper_member is None:
            continue
        selected_native = [
            record for record in native_records if _record_matches_member(record, native_member)
        ]
        selected_wrapper = [
            record for record in wrapper_records if _record_matches_member(record, wrapper_member)
        ]
        if len(selected_native) == 1 and len(selected_wrapper) == 1:
            if scenario == "icon-cold-launch":
                _validate_icon_launch_handoff(
                    selected_native[0], selected_wrapper[0], integration,
                    manifest["host_topology"],
                )
            if _handoff_facts(selected_native[0], scenario) != _handoff_facts(
                selected_wrapper[0], scenario
            ):
                raise ContractError(
                    f"aggregate assertion {assertion['name']} payload facts do not reconcile"
                )
            selected_pairs.append((native_member, selected_native[0], selected_wrapper[0]))

    required_transitions = (
        {"background", "foreground"} if scenario == "app-background-foreground" else {None}
    )
    observed_transitions = {
        _lifecycle_transition(native_record) if scenario == "app-background-foreground" else None
        for _, native_record, _ in selected_pairs
    }
    if not required_transitions.issubset(observed_transitions):
        raise ContractError(
            f"{integration} {scenario} requires integration-forwarded aggregate handoffs "
            f"for {sorted(str(item) for item in required_transitions)}"
        )
    if scenario == "app-background-foreground":
        for member, _, wrapper_record in selected_pairs:
            if "app_state" not in member:
                raise ContractError(
                    "app-background-foreground aggregate selectors require app_state qualification"
                )
            if _lifecycle_transition(wrapper_record) not in required_transitions:
                raise ContractError("wrapper lifecycle handoff must classify background or foreground")

    raw_records = [
        record for record in native_records if record["callback"] in forward_registry
    ]

    assigned_forward_to_raw: dict[int, int] = {}
    for raw in raw_records:
        correlation_keys = _forward_correlation_keys(raw, scenario)
        fact_candidates = []
        for forwarded in native_records:
            if forwarded["callback"] not in forward_registry.get(raw["callback"], set()):
                continue
            if scenario == "app-background-foreground" and _lifecycle_transition(
                raw
            ) != _lifecycle_transition(forwarded):
                continue
            if _handoff_facts(raw, scenario) != _handoff_facts(forwarded, scenario):
                continue
            fact_candidates.append(forwarded)
        candidates = [
            forwarded for forwarded in fact_candidates
            if not correlation_keys or _has_same_correlation(raw, forwarded, correlation_keys)
        ]
        if len(fact_candidates) == 1 and not candidates and correlation_keys:
            _require_same_correlation(
                raw, fact_candidates[0], correlation_keys, f"{integration} native forwarding"
            )
        if len(candidates) != 1:
            raise ContractError(
                f"{raw['callback']} requires exactly one matching {integration} native forward, "
                f"observed {len(candidates)}"
            )
        forwarded = candidates[0]
        if scenario == "icon-cold-launch":
            _validate_icon_launch_native_forward(raw, forwarded, integration)
        forward_sequence = forwarded["sequence"]
        if forward_sequence in assigned_forward_to_raw:
            raise ContractError(
                f"{forwarded['callback']} cannot forward multiple raw native ingress seats"
            )
        assigned_forward_to_raw[forward_sequence] = raw["sequence"]
        _require_order(raw, forwarded, f"{integration} native forwarding")

    all_registered_forwards = {
        callback for callbacks in forward_registry.values() for callback in callbacks
    }
    observed_forward_sequences = {
        record["sequence"] for record in native_records
        if record["callback"] in all_registered_forwards
    }
    unassigned = observed_forward_sequences.difference(assigned_forward_to_raw)
    if unassigned:
        raise ContractError(
            f"{integration} capture contains an unselected or duplicate native forward at "
            f"sequence(s) {sorted(unassigned)}"
        )
    for _, forwarded, _ in selected_pairs:
        if forwarded["sequence"] not in assigned_forward_to_raw:
            raise ContractError(
                f"aggregate-selected {forwarded['callback']} is not the unique raw-ingress forward"
            )

    selected_wrapper_sequences = {wrapper["sequence"] for _, _, wrapper in selected_pairs}
    alternate_wrapper_receipts = [
        record for record in wrapper_records
        if record["callback"] in wrapper_callbacks
        and record["sequence"] not in selected_wrapper_sequences
    ]
    if alternate_wrapper_receipts:
        raise ContractError(
            f"{integration} capture contains an unselected alternate wrapper receipt"
        )

    if scenario in COLD_START_SCENARIOS:
        bootstrap_records = []
        for group in COLD_BOOTSTRAP_GROUPS[integration]:
            matches = [record for record in native_records if record["callback"] in group]
            if len(matches) != 1:
                raise ContractError(
                    f"cold {integration} acceptance requires exactly one bootstrap seat from "
                    f"{sorted(group)}, observed {len(matches)}"
                )
            bootstrap_records.append(matches[0])
        if not (integration == "flutter" and scenario == "icon-cold-launch"):
            for before, after in zip(bootstrap_records, bootstrap_records[1:]):
                _require_order(before, after, f"cold {integration} bootstrap")
            for bootstrap in bootstrap_records:
                for _, forwarded, _ in selected_pairs:
                    if (
                        integration == "expo"
                        and scenario == "icon-cold-launch"
                        and bootstrap["callback"] in {
                            "rct.javascript-did-load-notification",
                            "rct.instance-did-load-bundle-notification",
                        }
                    ):
                        # Expo's did-finish forward returns before the asynchronous
                        # React Native bundle-load notification in the pinned graph.
                        continue
                    _require_order(bootstrap, forwarded, f"cold {integration} bootstrap")
        if integration == "flutter" and scenario == "icon-cold-launch":
            _validate_cold_flutter_icon_topology(
                native_records, wrapper_records, manifest["host_topology"]
            )
        if integration == "expo":
            launches = [
                record for record in native_records
                if record["callback"] == "application.did-finish-launching"
                and record["phase"] == "entry"
            ]
            did_finish_forwards = [
                record for record in native_records
                if record["callback"] == "expo.app-delegate-did-finish-launching-forwarded"
            ]
            if len(launches) != 1 or len(did_finish_forwards) != 1:
                raise ContractError(
                    "cold Expo bootstrap requires one application launch entry and "
                    "one Expo did-finish forward"
                )
            _require_order(launches[0], bootstrap_records[2], "cold Expo launch to RCT load")
            _require_order(
                launches[0], did_finish_forwards[0], "cold Expo application forwarding"
            )
            if scenario == "icon-cold-launch":
                if launches[0]["payload_summary"]["enums"].get("app_state") != "inactive":
                    raise ContractError(
                        "icon-cold-launch application entry requires app_state=inactive"
                    )
                application_active = [
                    record for record in native_records
                    if record["callback"] == "application.did-become-active"
                    and record["payload_summary"]["enums"].get("app_state") == "active"
                ]
                expo_active = [
                    record for record in native_records
                    if record["callback"] == "expo.subscriber.did-become-active-forwarded"
                    and record["payload_summary"]["enums"].get("app_state") == "active"
                ]
                if len(application_active) != 1 or len(expo_active) != 1:
                    raise ContractError(
                        "cold Expo icon launch requires exactly one active application seat "
                        "and one active Expo subscriber forward"
                    )
                _require_order(
                    did_finish_forwards[0], application_active[0],
                    "cold Expo did-finish to application active",
                )
                _require_order(
                    application_active[0], expo_active[0],
                    "cold Expo application active forwarding",
                )
                for _, _, wrapper_receipt in selected_pairs:
                    _require_capture_time_order(
                        expo_active[0], wrapper_receipt,
                        "cold Expo active forward to wrapper receipt",
                    )
                    _require_capture_time_order(
                        bootstrap_records[2], wrapper_receipt,
                        "cold Expo RCT load to wrapper receipt",
                    )

    if integration == "expo" and scenario in REMOTE_SCENARIOS.union(LOCAL_SCENARIOS):
        manager_callback = (
            "expo.notification-center-manager.will-present-forwarded"
            if scenario.endswith("foreground")
            else "expo.notification-center-manager.did-receive-response-forwarded"
        )
        event_callback = (
            "expo.notifications-emitter.notification-received-event-sent"
            if scenario.endswith("foreground")
            else "expo.notifications-emitter.notification-response-event-sent"
        )
        managers = [record for record in native_records if record["callback"] == manager_callback]
        events = [record for record in native_records if record["callback"] == event_callback]
        if len(managers) != 1 or len(events) != 1:
            raise ContractError(
                "Expo notification acceptance requires exactly one NotificationCenterManager "
                "entry and one Notifications Emitter event"
            )
        raw_callback = (
            "notification-center.will-present"
            if scenario.endswith("foreground")
            else "notification-center.did-receive-response"
        )
        raws = [record for record in native_records if record["callback"] == raw_callback]
        if len(raws) != 1:
            raise ContractError("Expo notification acceptance requires one raw UN center ingress")
        raw, manager, event = raws[0], managers[0], events[0]
        _require_order(raw, manager, "Expo NotificationCenterManager forwarding")
        _require_order(manager, event, "Expo Notifications Emitter delivery")
        for target in (manager, event):
            if _handoff_facts(raw, scenario) != _handoff_facts(target, scenario):
                raise ContractError("Expo notification forwarding must preserve safe facts")
            _require_same_correlation(
                raw, target, ("delivery", "request"), "Expo notification forwarding"
            )
        if scenario in COLD_START_SCENARIOS:
            created = [
                record for record in native_records
                if record["callback"] == "expo.notifications-emitter-created"
            ]
            if len(created) != 1:
                raise ContractError(
                    "cold Expo notification acceptance requires one Notifications Emitter creation"
                )
            _require_order(created[0], event, "cold Expo Notifications Emitter delivery")


def _validate_partial_test_handoff(
    manifest: dict[str, Any],
    records_by_stream: dict[str, list[dict[str, Any]]],
    topology: tuple[dict[str, Any], dict[str, Any]],
) -> None:
    """Exercise fact matching for schema-less unit fixtures; captures always use the full chain."""
    scenario = manifest["scenario"]
    native_declaration, wrapper_declaration = topology
    integration = native_declaration["integration"]
    handoff = _scenario_handoff(scenario, integration)
    if handoff is None:
        raise ContractError(
            f"multi-stream L2/L3 scenario {scenario} has no canonical wrapper handoff"
        )
    native_callbacks, wrapper_callbacks = handoff
    declarations = {item["stream_id"]: item for item in manifest["streams"]}
    accepted = native_callbacks.union(wrapper_callbacks)
    found = False
    for assertion in manifest["aggregate_assertions"]:
        members = assertion["members"]
        for member in members:
            if member["callback"] not in accepted:
                raise ContractError(
                    f"aggregate assertion {assertion['name']} selects callback "
                    f"{member['callback']} unrelated to scenario {scenario}"
                )
        if len(members) != 2:
            continue
        native_member = next(
            (
                member for member in members
                if declarations[member["stream_id"]]["runtime"] == "swift"
                and member["callback"] in native_callbacks
            ),
            None,
        )
        wrapper_member = next(
            (
                member for member in members
                if declarations[member["stream_id"]]["runtime"] in ("dart", "javascript")
                and member["callback"] in wrapper_callbacks
            ),
            None,
        )
        if native_member is None or wrapper_member is None:
            continue
        native_records = [
            record for record in records_by_stream[native_member["stream_id"]]
            if _record_matches_member(record, native_member)
        ]
        wrapper_records = [
            record for record in records_by_stream[wrapper_member["stream_id"]]
            if _record_matches_member(record, wrapper_member)
        ]
        if len(native_records) == len(wrapper_records) == 1:
            if scenario == "icon-cold-launch":
                all_native_records = records_by_stream[native_declaration["stream_id"]]
                _validate_icon_launch_handoff(
                    native_records[0], wrapper_records[0], integration,
                    manifest["host_topology"],
                )
                if integration == "flutter":
                    raw_scene = [
                        record for record in all_native_records
                        if record["callback"] == "scene.will-connect"
                    ]
                    forwarded_scene = [
                        record for record in all_native_records
                        if record["callback"] == "flutter.scene.will-connect-forwarded"
                    ]
                    if len(raw_scene) == len(forwarded_scene) == 1:
                        _validate_icon_launch_native_forward(
                            raw_scene[0], forwarded_scene[0], integration
                        )
            if _handoff_facts(native_records[0], scenario) != _handoff_facts(
                wrapper_records[0], scenario
            ):
                raise ContractError(
                    f"aggregate assertion {assertion['name']} payload facts do not reconcile"
                )
        found = True
    if not found:
        raise ContractError(
            f"multi-stream L2/L3 scenario {scenario} requires a canonical native/wrapper handoff assertion"
        )


def _validate_scenario_acceptance(
    manifest: dict[str, Any], records_by_stream: dict[str, list[dict[str, Any]]]
) -> None:
    if manifest["evidence_level"] not in ("L2", "L3"):
        return
    scenario = manifest["scenario"]
    topology = _validate_wrapper_acceptance_topology(manifest)
    required_groups = list(SCENARIO_REQUIRED_GROUPS.get(scenario, ()))
    host_topology = manifest["host_topology"]
    all_records = [record for records in records_by_stream.values() for record in records]
    if scenario == "token-registration":
        provider = manifest["provider_provenance"]["provider"]
        required_groups = [
            {"application.did-register-for-remote-notifications"},
        ]
        if provider == "fcm":
            required_groups.insert(1, {"fcm.registration-token-refreshed"})
    elif scenario == "app-background-foreground":
        if host_topology == "app-delegate-only":
            required_groups = [
                {"application.did-enter-background"},
                {"application.will-enter-foreground"},
            ]
        elif host_topology == "ui-scene":
            required_groups = [
                {"scene.did-enter-background"},
                {"scene.will-enter-foreground"},
            ]
        else:
            required_groups = []
            swiftui_records = [
                record for record in all_records
                if record["callback"] == "swiftui.scene-phase-change"
            ]
            transition_counts = {
                transition: sum(
                    _lifecycle_transition(record) == transition
                    for record in swiftui_records
                )
                for transition in ("background", "foreground")
            }
            if transition_counts != {"background": 1, "foreground": 1}:
                raise ContractError(
                    "swiftui-lifecycle app-background-foreground requires exactly one "
                    "app_state=background seat and one app_state=active seat"
                )
    if not required_groups and not (
        scenario == "app-background-foreground" and host_topology == "swiftui-lifecycle"
    ):
        raise ContractError(f"scenario {scenario} has no canonical acceptance registry entry")

    for callbacks in required_groups:
        matching = [record for record in all_records if record["callback"] in callbacks]
        if scenario == "app-background-foreground":
            per_callback = {
                callback: sum(record["callback"] == callback for record in matching)
                for callback in callbacks
            }
            if not matching or any(count > 1 for count in per_callback.values()):
                raise ContractError(
                    f"scenario {scenario} requires at least one transition from "
                    f"{sorted(callbacks)} and at most one per callback seat"
                )
        elif len(matching) != 1:
            raise ContractError(
                f"scenario {scenario} requires exactly one defining callback from "
                f"{sorted(callbacks)}, observed {len(matching)}"
            )
    if scenario == "push-foreground":
        remote_application_entries = [
            record for record in all_records
            if record["callback"] == "application.did-receive-remote-notification"
        ]
        if len(remote_application_entries) > 1:
            raise ContractError(
                "one-stimulus push-foreground accepts at most one "
                "application.did-receive-remote-notification entry"
            )
    if scenario == "token-registration":
        registration_results = [
            record for record in all_records
            if record["callback"] == "customerio.register-device-token"
            and record.get("phase") == "result"
        ]
        if len(registration_results) != 1:
            raise ContractError(
                "scenario token-registration requires exactly one "
                "customerio.register-device-token phase=result seat, "
                f"observed {len(registration_results)}"
            )

    _validate_native_causal_chains(manifest, records_by_stream)
    assertions = manifest["aggregate_assertions"]
    if any(assertion["expected_count"] != 1 for assertion in assertions):
        raise ContractError("one-stimulus L2/L3 acceptance assertions require expected_count=1")
    if len(records_by_stream) == 1:
        return
    if topology is None:
        raise ContractError(
            f"multi-stream L2/L3 scenario {scenario} requires a supported wrapper topology"
        )
    declarations = {item["stream_id"]: item for item in manifest["streams"]}
    if any(
        "sequence" not in record
        or record.get("integration") != declarations[stream_id]["integration"]
        or record.get("runtime") != declarations[stream_id]["runtime"]
        for stream_id, records in records_by_stream.items() for record in records
    ):
        _validate_partial_test_handoff(manifest, records_by_stream, topology)
        return
    _validate_wrapper_forwarding_chain(manifest, records_by_stream, topology)


def validate_capture(
    manifest_path: Path,
    stream_paths: list[Path],
    schema_dir: Path | None = None,
) -> None:
    schema_dir = schema_dir or Path(__file__).resolve().parent
    trace_schema, manifest_schema = _schemas(schema_dir)
    manifest_validator = _validator(manifest_schema, trace_schema)
    trace_validator = _validator(trace_schema)
    manifest = _load_json(manifest_path)
    _assert_schema(manifest_validator, manifest, str(manifest_path))
    started, ended = _validate_manifest_relations(manifest)

    declarations = {item["stream_id"]: item for item in manifest["streams"]}
    records_by_stream: dict[str, list[dict[str, Any]]] = {}
    for path in stream_paths:
        records = _load_stream(path, trace_validator)
        stream_ids = {record["stream_id"] for record in records}
        if len(stream_ids) != 1:
            raise ContractError(f"{path}: each capture file must contain exactly one stream")
        stream_id = stream_ids.pop()
        if stream_id not in declarations:
            raise ContractError(f"{path}: undeclared stream_id {stream_id}")
        if stream_id in records_by_stream:
            raise ContractError(f"stream {stream_id} is split or duplicated across files")
        records_by_stream[stream_id] = records
    missing = set(declarations).difference(records_by_stream)
    if missing:
        raise ContractError(f"manifest streams are missing capture files: {sorted(missing)}")
    for stream_id, declaration in declarations.items():
        _validate_stream(manifest, declaration, records_by_stream[stream_id], started, ended)
    _validate_topology_and_occurrence(manifest, records_by_stream)
    _validate_scenario_acceptance(manifest, records_by_stream)
    _validate_aggregates(manifest, records_by_stream)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("streams", nargs="+", type=Path)
    parser.add_argument(
        "--schema-dir", type=Path, default=Path(__file__).resolve().parent,
        help="directory containing both v1 JSON schemas",
    )
    arguments = parser.parse_args(argv)
    try:
        validate_capture(arguments.manifest, arguments.streams, arguments.schema_dir)
    except ContractError as error:
        print(f"INVALID: {error}", file=sys.stderr)
        return 1
    print(f"VALID: {arguments.manifest} with {len(arguments.streams)} stream(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
