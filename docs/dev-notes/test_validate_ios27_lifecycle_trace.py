#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from validate_ios27_lifecycle_trace import (  # noqa: E402
    CALLBACK_RULES,
    FRAMEWORK_ROLES,
    PREFIX,
    ContractError,
    _load_json,
    _parse_time,
    _validate_callback_rule,
    _validate_payload,
    _validate_scenario_acceptance,
    validate_capture,
)


VECTORS = HERE / "ios27-lifecycle-trace-v1-test-vectors"


def load_records(name: str) -> list[dict]:
    records = []
    for line in (VECTORS / name).read_text(encoding="utf-8").splitlines():
        records.append(json.loads(line[len(PREFIX):]))
    return records


def sync_receipt(manifest: dict, stream_index: int, records: list[dict]) -> None:
    final = records[-1]
    recorder = final["recorder"]
    receipt = manifest["streams"][stream_index]["receipt"]
    receipt.update({
        "last_assigned_sequence": final["sequence"],
        "last_emitted_sequence": final["sequence"],
        "emitted_records": len(records),
        "dropped_records_total": recorder["dropped_records_total"],
        "buffer_high_watermark": recorder["buffer_high_watermark"],
        "buffer_capacity": recorder["buffer_capacity"],
        "alias_counts": copy.deepcopy(recorder["alias_counts"]),
        "alias_overflow": recorder["alias_overflow"],
        "alias_overflow_namespaces": copy.deepcopy(recorder["alias_overflow_namespaces"]),
    })


class LifecycleTraceContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = _load_json(VECTORS / "manifest.valid.json")
        self.native = load_records("native.valid.ndjson")
        self.wrapper = load_records("wrapper.valid.ndjson")
        self.aggregate_vectors = _load_json(VECTORS / "aggregate.invalid-counts.json")["cases"]

    def validate_temp(
        self,
        manifest: dict,
        streams: list[list[dict]],
        expected_error: str | None = None,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest_path = root / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            stream_paths = []
            for index, records in enumerate(streams):
                path = root / f"stream-{index}.ndjson"
                path.write_text(
                    "\n".join(PREFIX + json.dumps(record, separators=(",", ":")) for record in records) + "\n",
                    encoding="utf-8",
                )
                stream_paths.append(path)
            if expected_error is None:
                validate_capture(manifest_path, stream_paths, HERE)
            else:
                with self.assertRaisesRegex(ContractError, expected_error):
                    validate_capture(manifest_path, stream_paths, HERE)

    @staticmethod
    def make_native_single(manifest: dict, records: list[dict]) -> None:
        manifest["repositories"] = [
            item for item in manifest["repositories"] if item["name"] == "customerio-ios"
        ]
        manifest["frameworks"] = [
            item for item in manifest["frameworks"]
            if item["name"] in ("customerio-ios", "customerio-messaging-push", "apple-usernotifications")
        ]
        manifest["toolchain"].update({
            "flutter_version": None, "dart_version": None,
            "node_version": None, "expo_cli_version": None,
        })
        manifest["streams"] = [manifest["streams"][0]]
        manifest["streams"][0]["integration"] = "native-ios"
        manifest["aggregate_assertions"] = []
        records[:] = [
            record for record in records
            if not record["callback"].startswith(("flutter.", "expo.", "react-native."))
        ]
        for sequence, record in enumerate(records, 1):
            record["sequence"] = sequence
            record["integration"] = "native-ios"

    def normalize_capture(self, manifest: dict, streams: list[list[dict]]) -> None:
        """Normalize synthetic full-capture records and their post-drain receipts."""
        manifest["run_ended_at"] = "2026-08-11T16:00:30Z"
        manifest["created_at"] = "2026-08-11T16:00:31Z"
        cold = manifest["scenario"].endswith("-cold") or manifest["scenario"] == "icon-cold-launch"
        for stream_index, records in enumerate(streams):
            declaration = manifest["streams"][stream_index]
            alias_counts = {name: 0 for name in ("delivery", "request", "scene", "url", "closure")}
            for index, record in enumerate(records, 1):
                record.update({
                    "manifest_id": manifest["manifest_id"], "run_id": manifest["run_id"],
                    "stream_id": declaration["stream_id"], "sequence": index,
                    "monotonic_ms": 1000 * (stream_index + 1) + index,
                    "process_id": declaration["process_id"],
                    "integration": declaration["integration"], "runtime": declaration["runtime"],
                    "provider": declaration["provider"], "scenario": manifest["scenario"],
                    "evidence_level": manifest["evidence_level"],
                })
                if index == 1:
                    record["captured_at"] = (
                        "2026-08-11T16:00:03Z" if cold else "2026-08-11T16:00:00Z"
                    )
                elif index == len(records):
                    record["captured_at"] = "2026-08-11T16:00:28Z"
                else:
                    record["captured_at"] = f"2026-08-11T16:00:{index + 2:02d}Z"
                for name, alias in (record.get("correlation") or {}).items():
                    alias_counts[name] = max(alias_counts[name], int(alias.rsplit("-", 1)[1]))
                recorder = record["recorder"]
                recorder.update({
                    "dropped_records_total": 0,
                    "alias_counts": copy.deepcopy(alias_counts),
                    "alias_overflow": False, "alias_overflow_namespaces": [],
                    "buffer_high_watermark": 1, "buffer_capacity": 256,
                })
            sync_receipt(manifest, stream_index, records)
            declaration["receipt"]["drained_at"] = "2026-08-11T16:00:29Z"

    def runtime_record(
        self,
        callback: str,
        owner: str,
        kind: str,
        phase: str,
        payload: dict,
        correlation: dict | None = None,
        wrapper: bool = False,
    ) -> dict:
        record = copy.deepcopy(self.wrapper[1] if wrapper else self.native[1])
        record.update({
            "callback": callback, "owner": owner, "kind": kind, "phase": phase,
            "payload_summary": copy.deepcopy(payload), "correlation": correlation,
            "completion": None,
        })
        return record

    def convert_wrapper_integration(
        self, manifest: dict, native: list[dict], wrapper: list[dict], integration: str
    ) -> None:
        manifest["repositories"] = [
            item for item in manifest["repositories"] if item["name"] != "customerio-flutter"
        ]
        manifest["frameworks"] = [
            item for item in manifest["frameworks"]
            if item["name"] not in ("customerio-flutter", "flutter")
        ]
        manifest["toolchain"].update({
            "flutter_version": None, "dart_version": None, "node_version": "20.19.0",
            "expo_cli_version": "57.0.0" if integration == "expo" else None,
        })
        manifest["streams"][0]["integration"] = integration
        if integration == "expo":
            repositories = (
                ("customerio-expo-plugin", "3637028bfa4c5c66752697b346ad826266e6ae03"),
                ("customerio-reactnative", "1edc94769359dfd992d6622884561d448d3f8dd9"),
            )
            frameworks = (
                ("customerio-expo-plugin", "wrapper", "3.7.1", repositories[0][1]),
                ("expo", "runtime", "57.0.12", None),
                ("expo-notifications", "peer", "57.0.10", None),
                ("expo-modules-core", "peer", "57.0.10", None),
                ("customerio-reactnative", "wrapper", "6.6.2", repositories[1][1]),
                ("react-native", "runtime", "0.86.2", None),
            )
            manifest["streams"][1]["integration"] = integration
            manifest["streams"][1].update({"runtime": "javascript", "process_id": None})
            forward = next(
                record for record in native
                if record["callback"] == "flutter.notification-center.did-receive-response-forwarded"
            )
            forward.update({
                "callback": "expo.notifications-emitter.notification-response-event-sent",
                "owner": "expo-notifications", "phase": "result",
            })
            manager = copy.deepcopy(forward)
            manager.update({
                "callback": "expo.notification-center-manager.did-receive-response-forwarded",
                "owner": "expo-notifications", "phase": "entry",
            })
            native.insert(native.index(forward), manager)
            wrapper[1]["owner"] = "expo-javascript"
        else:
            repositories = (("customerio-reactnative", "1edc94769359dfd992d6622884561d448d3f8dd9"),)
            frameworks = (
                ("customerio-reactnative", "wrapper", "6.6.2", repositories[0][1]),
                ("react-native", "runtime", "0.83.6", None),
            )
        for name, sha in repositories:
            manifest["repositories"].append({
                "name": name, "commit_sha": sha, "dirty": False, "source_snapshot": None,
            })
        for name, role, version, sha in frameworks:
            manifest["frameworks"].append({
                "name": name, "role": role, "version": version, "commit_sha": sha,
            })
        if integration == "expo":
            manifest["aggregate_assertions"][0]["members"][0]["callback"] = (
                "expo.notifications-emitter.notification-response-event-sent"
            )
            manifest["aggregate_assertions"][0]["members"][0]["phase"] = "result"
        else:
            manifest["streams"] = [manifest["streams"][0]]
            manifest["aggregate_assertions"] = []
            native[:] = [
                record for record in native
                if not record["callback"].startswith("flutter.")
            ]

    def url_capture(self, live_activity: bool = False) -> tuple[dict, list[dict], list[dict]]:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        scenario = "live-activity-tap-warm" if live_activity else "custom-url-warm"
        manifest["scenario"] = scenario
        manifest["stimulus"].update({
            "scenario": scenario, "source": "live-activity" if live_activity else "app-ui",
        })
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        for stream in manifest["streams"]:
            stream["provider"] = "none"
        payload = {
            "flags": {"has_url": True},
            "counts": {"url_path_components": 2, "url_query_items": 0},
            "enums": {
                "url_scheme": "custom",
                "url_class": "cio-live-activity" if live_activity else "custom-scheme",
            },
        }
        route_intent_payload = copy.deepcopy(payload)
        route_intent_payload["flags"]["has_redirect"] = live_activity
        host_result_payload = copy.deepcopy(route_intent_payload)
        host_result_payload["flags"]["handled"] = True
        host_result_payload["enums"]["result"] = "handled"
        customerio_result_payload = copy.deepcopy(route_intent_payload)
        customerio_result_payload["flags"]["handled"] = True
        customerio_result_payload["enums"]["result"] = (
            "redirect" if live_activity else "handled"
        )
        correlation = {"url": "url-1"}
        native = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.open-url", "application-delegate", "os-callback", "entry",
                payload, correlation,
            ),
            self.runtime_record(
                "flutter.application.open-url-forwarded", "flutter-plugin",
                "framework-callback", "entry", payload, correlation,
            ),
            self.runtime_record(
                "host.route-url", "host", "host-routing", "intent",
                route_intent_payload, correlation,
            ),
        ]
        if live_activity:
            native.extend((
                self.runtime_record(
                    "customerio.route-deep-link", "customerio-sdk", "sdk-routing", "intent",
                    route_intent_payload, correlation,
                ),
                self.runtime_record(
                    "customerio.route-deep-link", "customerio-sdk", "sdk-routing", "result",
                    customerio_result_payload, correlation,
                ),
            ))
        native.extend((
            self.runtime_record(
                "host.route-url", "host", "host-routing", "result",
                host_result_payload, correlation,
            ),
            copy.deepcopy(self.native[-1]),
        ))
        wrapper = [
            copy.deepcopy(self.wrapper[0]),
            self.runtime_record(
                "wrapper.app-received-url", "flutter-dart", "app-received", "entry",
                payload, wrapper=True,
            ),
            copy.deepcopy(self.wrapper[-1]),
        ]
        manifest["aggregate_assertions"] = [{
            "name": "url-forwarding", "relation": "equal-exact-count", "expected_count": 1,
            "members": [
                {
                    "stream_id": manifest["streams"][0]["stream_id"],
                    "callback": "flutter.application.open-url-forwarded", "phase": "entry",
                },
                {
                    "stream_id": manifest["streams"][1]["stream_id"],
                    "callback": "wrapper.app-received-url", "phase": "entry",
                },
            ],
        }]
        self.normalize_capture(manifest, [native, wrapper])
        return manifest, native, wrapper

    def test_valid_two_stream_exact_handoff(self) -> None:
        validate_capture(
            VECTORS / "manifest.valid.json",
            [VECTORS / "native.valid.ndjson", VECTORS / "wrapper.valid.ndjson"],
            HERE,
        )

    def test_full_capture_requires_integration_forward_not_raw_os_selector(self) -> None:
        self.manifest["aggregate_assertions"][0]["members"][0]["callback"] = (
            "notification-center.did-receive-response"
        )
        self.validate_temp(
            self.manifest, [self.native, self.wrapper],
            "canonical flutter forwarding chain is required",
        )

    def test_full_capture_forwarding_preserves_order_facts_and_correlation(self) -> None:
        reordered = copy.deepcopy(self.native)
        forwarded = reordered.pop(3)
        reordered.insert(1, forwarded)
        self.normalize_capture(self.manifest, [reordered, self.wrapper])
        self.validate_temp(
            self.manifest, [reordered, self.wrapper], "native forwarding requires causal sequence"
        )

        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        native[3]["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        wrapper[1]["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper], "requires exactly one matching flutter native forward"
        )

        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        native[3]["correlation"] = {"delivery": "delivery-2"}
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper], "must preserve correlation.delivery")

    def test_warm_expo_and_react_native_use_honest_ios_topologies(self) -> None:
        for integration in ("expo", "react-native"):
            with self.subTest(integration=integration):
                manifest = _load_json(VECTORS / "manifest.valid.json")
                native = load_records("native.valid.ndjson")
                wrapper = load_records("wrapper.valid.ndjson")
                self.convert_wrapper_integration(manifest, native, wrapper, integration)
                streams = [native, wrapper] if integration == "expo" else [native]
                self.normalize_capture(manifest, streams)
                self.validate_temp(manifest, streams)

    def test_integration_is_derived_from_wrapper_provenance(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        for declaration in manifest["streams"]:
            declaration["integration"] = "native-ios"
        self.validate_temp(
            manifest, [self.native, self.wrapper],
            "stream integration must match repository/framework provenance: expected flutter",
        )

        runtime_only = copy.deepcopy(manifest)
        runtime_only["repositories"] = [
            item for item in runtime_only["repositories"]
            if item["name"] != "customerio-flutter"
        ]
        runtime_only["frameworks"] = [
            item for item in runtime_only["frameworks"]
            if item["name"] != "customerio-flutter"
        ]
        self.validate_temp(
            runtime_only, [self.native, self.wrapper],
            "stream integration must match repository/framework provenance: expected flutter",
        )

    def test_push_tap_requires_default_action_and_customerio_terminal(self) -> None:
        for action_class in ("dismiss", "custom"):
            with self.subTest(action_class=action_class):
                manifest = _load_json(VECTORS / "manifest.valid.json")
                native = load_records("native.valid.ndjson")
                wrapper = load_records("wrapper.valid.ndjson")
                for record in native + wrapper:
                    if record["payload_summary"]["flags"].get("has_notification_response"):
                        record["payload_summary"]["enums"]["action_class"] = action_class
                self.normalize_capture(manifest, [native, wrapper])
                self.validate_temp(
                    manifest, [native, wrapper], "push-tap acceptance requires action_class=default"
                )

        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = [
            record for record in load_records("native.valid.ndjson")
            if record["callback"] != "customerio.handle-notification-response"
        ]
        wrapper = load_records("wrapper.valid.ndjson")
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "requires exactly one defining callback.*customerio.handle-notification-response.*observed 0",
        )

        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        terminal = next(
            record for record in native
            if record["callback"] == "customerio.handle-notification-response"
        )
        terminal["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "customerio.handle-notification-response requires notification_class=customerio",
        )

    def test_unselected_alternate_native_forward_is_rejected(self) -> None:
        native = copy.deepcopy(self.native)
        canonical = next(
            record for record in native
            if record["callback"] == "flutter.notification-center.did-receive-response-forwarded"
        )
        alternate = copy.deepcopy(canonical)
        alternate["callback"] = "flutter.notification-response"
        native.insert(native.index(canonical) + 1, alternate)
        self.normalize_capture(self.manifest, [native, self.wrapper])
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "requires exactly one matching flutter native forward, observed 2",
        )

    def test_l2_exact_provenance_rejects_placeholders_and_generic_models(self) -> None:
        mutations = (
            ("xcode build", lambda manifest: manifest["toolchain"].update({"xcode_build": "unknown"})),
            (
                "framework version",
                lambda manifest: manifest["frameworks"][0].update({"version": "snapshot"}),
            ),
            ("device model", lambda manifest: manifest["target"].update({"model": "iPhone"})),
        )
        for label, mutate in mutations:
            with self.subTest(label=label):
                manifest = copy.deepcopy(self.manifest)
                mutate(manifest)
                self.validate_temp(manifest, [self.native, self.wrapper], "exact non-placeholder|specific human")

    def test_fabricated_expo_and_javascript_react_native_topologies_reject(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        self.convert_wrapper_integration(manifest, native, wrapper, "expo")
        manager = next(
            record for record in native
            if record["callback"] == "expo.notification-center-manager.did-receive-response-forwarded"
        )
        manager["callback"] = "expo.subscriber.notification-center-did-receive-response-forwarded"
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper], "schema violation at callback")

        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        original_wrapper_declaration = copy.deepcopy(manifest["streams"][1])
        self.convert_wrapper_integration(manifest, native, wrapper, "react-native")
        original_wrapper_declaration.update({
            "integration": "react-native", "runtime": "javascript", "process_id": None,
        })
        manifest["streams"].append(original_wrapper_declaration)
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "standalone React Native iOS L2/L3 streams are native Swift pass-through only",
        )

    def test_expo_and_react_native_callback_topologies_require_exact_audited_provenance(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        self.convert_wrapper_integration(manifest, native, wrapper, "expo")
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

        for repository_name in ("customerio-expo-plugin", "customerio-reactnative"):
            with self.subTest(repository=repository_name):
                mutated = copy.deepcopy(manifest)
                arbitrary_sha = "9999999999999999999999999999999999999999"
                next(
                    item for item in mutated["repositories"]
                    if item["name"] == repository_name
                )["commit_sha"] = arbitrary_sha
                next(
                    item for item in mutated["frameworks"]
                    if item["name"] == repository_name
                )["commit_sha"] = arbitrary_sha
                self.validate_temp(
                    mutated, [native, wrapper],
                    f"expo callback topology requires audited repository {repository_name}",
                )

        pinned_frameworks = (
            "customerio-expo-plugin", "expo", "expo-notifications",
            "expo-modules-core", "customerio-reactnative", "react-native",
        )
        for framework_name in pinned_frameworks:
            with self.subTest(framework=framework_name):
                mutated = copy.deepcopy(manifest)
                next(
                    item for item in mutated["frameworks"]
                    if item["name"] == framework_name
                )["version"] = "99.0.0"
                self.validate_temp(
                    mutated, [native, wrapper],
                    f"expo callback topology requires audited framework {framework_name}",
                )

        rn_manifest = _load_json(VECTORS / "manifest.valid.json")
        rn_native = load_records("native.valid.ndjson")
        rn_wrapper = load_records("wrapper.valid.ndjson")
        self.convert_wrapper_integration(
            rn_manifest, rn_native, rn_wrapper, "react-native"
        )
        self.normalize_capture(rn_manifest, [rn_native])
        self.validate_temp(rn_manifest, [rn_native])

        mutated = copy.deepcopy(rn_manifest)
        arbitrary_sha = "9999999999999999999999999999999999999999"
        next(
            item for item in mutated["repositories"]
            if item["name"] == "customerio-reactnative"
        )["commit_sha"] = arbitrary_sha
        next(
            item for item in mutated["frameworks"]
            if item["name"] == "customerio-reactnative"
        )["commit_sha"] = arbitrary_sha
        self.validate_temp(
            mutated, [rn_native],
            "react-native callback topology requires audited repository customerio-reactnative",
        )

        mutated = copy.deepcopy(rn_manifest)
        next(
            item for item in mutated["frameworks"]
            if item["name"] == "customerio-reactnative"
        )["version"] = "99.0.0"
        self.validate_temp(
            mutated, [rn_native],
            "react-native callback topology requires audited framework customerio-reactnative",
        )

        for version in ("0.86.2", "99.0.0"):
            with self.subTest(standalone_react_native_version=version):
                mutated = copy.deepcopy(rn_manifest)
                next(
                    item for item in mutated["frameworks"]
                    if item["name"] == "react-native"
                )["version"] = version
                self.validate_temp(
                    mutated, [rn_native],
                    "react-native callback topology requires audited framework react-native",
                )

    def test_wrapper_receipt_callbacks_are_scenario_bound_in_full_capture(self) -> None:
        mutations = (
            (
                "wrapper.app-received-url",
                {"flags": {"has_url": True}, "counts": {"url_path_components": 1, "url_query_items": 0},
                 "enums": {"url_scheme": "custom", "url_class": "custom-scheme"}},
            ),
            (
                "wrapper.app-received-quick-action",
                {"flags": {"has_shortcut": True}, "counts": {}, "enums": {"action_class": "default"}},
            ),
        )
        for callback, payload in mutations:
            with self.subTest(callback=callback):
                manifest = _load_json(VECTORS / "manifest.valid.json")
                native = load_records("native.valid.ndjson")
                wrapper = load_records("wrapper.valid.ndjson")
                wrapper[1].update({"callback": callback, "payload_summary": payload})
                self.normalize_capture(manifest, [native, wrapper])
                self.validate_temp(
                    manifest, [native, wrapper], f"{callback} is an external-entry seat"
                )

    def test_l3_registration_rejects_simulator_provenance_full_capture(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest.update({"evidence_level": "L3", "scenario": "token-registration"})
        manifest["sdk"]["name"] = "iphoneos"
        manifest["target"].update({"kind": "physical-device", "architecture": "arm64"})
        manifest["stimulus"].update({"scenario": "token-registration", "source": "system-registration"})
        manifest["provider_provenance"].update({
            "provider": "apn", "source": "system-registration", "environment": "simulator",
            "receipt_result": "registered", "provider_sdk": None,
        })
        for stream in manifest["streams"]:
            stream["provider"] = "apn"
        self.validate_temp(
            manifest, [self.native, self.wrapper], "L3 registration evidence requires a real"
        )

    def test_url_and_live_activity_full_capture_routing_is_exact_and_ordered(self) -> None:
        for live_activity in (False, True):
            with self.subTest(live_activity=live_activity):
                manifest, native, wrapper = self.url_capture(live_activity)
                self.validate_temp(manifest, [native, wrapper])

                duplicate_manifest = copy.deepcopy(manifest)
                duplicate_native = copy.deepcopy(native)
                result_index = next(
                    index for index, record in enumerate(duplicate_native)
                    if record["callback"] == "host.route-url" and record["phase"] == "result"
                )
                duplicate_native.insert(result_index, copy.deepcopy(duplicate_native[result_index]))
                self.normalize_capture(duplicate_manifest, [duplicate_native, copy.deepcopy(wrapper)])
                self.validate_temp(
                    duplicate_manifest, [duplicate_native, wrapper],
                    "URL routing requires exactly one host.route-url phase=result, observed 2",
                )

                mismatch_manifest = copy.deepcopy(manifest)
                mismatch_native = copy.deepcopy(native)
                host_result = next(
                    record for record in mismatch_native
                    if record["callback"] == "host.route-url" and record["phase"] == "result"
                )
                host_result["payload_summary"]["counts"]["url_path_components"] = 99
                self.normalize_capture(mismatch_manifest, [mismatch_native, copy.deepcopy(wrapper)])
                self.validate_temp(
                    mismatch_manifest, [mismatch_native, wrapper],
                    "URL routing must preserve ingress safe facts",
                )

        manifest, native, wrapper = self.url_capture(True)
        native = [record for record in native if record["callback"] != "customerio.route-deep-link"]
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper], "Live Activity routing requires exactly one Customer.io"
        )

        manifest, native, wrapper = self.url_capture(True)
        host_intent = next(
            record for record in native
            if record["callback"] == "host.route-url" and record["phase"] == "intent"
        )
        host_intent["payload_summary"]["flags"]["has_redirect"] = False
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "host URL route intent/result has_redirect classification changed",
        )

        manifest, native, wrapper = self.url_capture(True)
        host_result = next(
            record for record in native
            if record["callback"] == "host.route-url" and record["phase"] == "result"
        )
        host_result["payload_summary"]["flags"]["handled"] = False
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper], "host.route-url result=handled contradicts handled=False"
        )

        manifest, native, wrapper = self.url_capture(True)
        cio_intent = next(
            record for record in native
            if record["callback"] == "customerio.route-deep-link" and record["phase"] == "intent"
        )
        cio_intent["payload_summary"]["flags"]["has_redirect"] = False
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "Customer.io URL route intent/result has_redirect classification changed",
        )

        manifest, native, wrapper = self.url_capture(True)
        cio_result = next(
            record for record in native
            if record["callback"] == "customerio.route-deep-link" and record["phase"] == "result"
        )
        cio_result["payload_summary"]["flags"]["handled"] = False
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "Customer.io redirect result requires handled=true and result=redirect",
        )

        manifest, native, wrapper = self.url_capture(True)
        host_intent = next(
            record for record in native
            if record["callback"] == "host.route-url" and record["phase"] == "intent"
        )
        host_intent["payload_summary"]["flags"]["handled"] = True
        host_intent["payload_summary"]["enums"]["result"] = "handled"
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "host.route-url intent carries classification only; outcome belongs on result",
        )

        manifest, native, wrapper = self.url_capture(True)
        host_result = next(
            record for record in native
            if record["callback"] == "host.route-url" and record["phase"] == "result"
        )
        host_result["payload_summary"]["flags"]["handled"] = False
        host_result["payload_summary"]["enums"]["result"] = "unhandled"
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(
            manifest, [native, wrapper],
            "Customer.io and terminal host URL route handled outcomes disagree",
        )

    def test_url_route_requires_non_null_stable_correlation(self) -> None:
        manifest, native, wrapper = self.url_capture()
        native[2]["correlation"] = {"url": "url-2"}
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper], "must preserve correlation.url")

    def test_embedded_serial_in_human_model_is_rejected(self) -> None:
        self.manifest["target"]["model"] = "iPhone C02ZQ0ABCDEF"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "schema violation at target.model"
        )

    def test_foreground_presentation_full_capture_is_ordered_and_reconciled(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "push-foreground"
        manifest["stimulus"]["scenario"] = "push-foreground"
        notification = {
            "flags": {"has_notification": True}, "counts": {"notification_user_info_keys": 3},
            "enums": {
                "notification_origin": "remote", "notification_class": "customerio",
                "delegate_peer": "host",
            },
        }
        presentation = copy.deepcopy(notification)
        presentation["flags"].update({
            "presentation_alert": True, "presentation_badge": False,
            "presentation_sound": False, "presentation_banner": False,
            "presentation_list": False,
        })
        presentation["counts"]["presentation_options"] = 1
        presentation["enums"]["presentation_class"] = "visible"
        correlation = {"delivery": "delivery-1"}
        native = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "notification-center.will-present", "notification-center-delegate",
                "os-callback", "entry", notification, correlation,
            ),
            self.runtime_record(
                "flutter.notification-center.will-present-forwarded", "flutter-plugin",
                "framework-callback", "entry", notification, correlation,
            ),
            self.runtime_record(
                "host.present-notification", "host", "host-routing", "result",
                presentation, correlation,
            ),
            copy.deepcopy(self.native[-1]),
        ]
        wrapper = [
            copy.deepcopy(self.wrapper[0]),
            self.runtime_record(
                "wrapper.app-received-notification", "flutter-dart", "app-received", "entry",
                notification, wrapper=True,
            ),
            copy.deepcopy(self.wrapper[-1]),
        ]
        manifest["aggregate_assertions"][0]["members"][0]["callback"] = (
            "flutter.notification-center.will-present-forwarded"
        )
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

        invalid = copy.deepcopy(native)
        invalid[1], invalid[3] = invalid[3], invalid[1]
        self.normalize_capture(manifest, [invalid, wrapper])
        self.validate_temp(manifest, [invalid, wrapper], "notification presentation requires causal")

        invalid = copy.deepcopy(native)
        invalid[3]["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        self.normalize_capture(manifest, [invalid, wrapper])
        self.validate_temp(
            manifest, [invalid, wrapper], "notification presentation must preserve safe classification"
        )

        remote_entry = self.runtime_record(
            "application.did-receive-remote-notification", "application-delegate",
            "os-callback", "entry", notification, correlation,
        )
        remote_forward = self.runtime_record(
            "flutter.application.did-receive-remote-notification-forwarded", "flutter-plugin",
            "framework-callback", "entry", notification, correlation,
        )
        with_remote_delivery = [*native[:-1], remote_entry, remote_forward, native[-1]]
        self.normalize_capture(manifest, [with_remote_delivery, wrapper])
        self.validate_temp(manifest, [with_remote_delivery, wrapper])

        duplicate_forward = copy.deepcopy(with_remote_delivery)
        forward_index = next(
            index for index, record in enumerate(duplicate_forward)
            if record["callback"] == "flutter.application.did-receive-remote-notification-forwarded"
        )
        duplicate_forward.insert(forward_index, copy.deepcopy(duplicate_forward[forward_index]))
        self.normalize_capture(manifest, [duplicate_forward, wrapper])
        self.validate_temp(
            manifest, [duplicate_forward, wrapper],
            "application.did-receive-remote-notification requires exactly one matching "
            "flutter native forward, observed 2",
        )

        contradictory_forward = copy.deepcopy(with_remote_delivery)
        contradictory = next(
            record for record in contradictory_forward
            if record["callback"] == "flutter.application.did-receive-remote-notification-forwarded"
        )
        contradictory["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        self.normalize_capture(manifest, [contradictory_forward, wrapper])
        self.validate_temp(
            manifest, [contradictory_forward, wrapper],
            "application.did-receive-remote-notification requires exactly one matching "
            "flutter native forward, observed 0",
        )

        two_deliveries = copy.deepcopy(with_remote_delivery)
        second_entry = copy.deepcopy(remote_entry)
        second_entry["correlation"] = {"delivery": "delivery-2"}
        second_forward = copy.deepcopy(remote_forward)
        second_forward["correlation"] = {"delivery": "delivery-2"}
        two_deliveries[-1:-1] = [second_entry, second_forward]
        self.normalize_capture(manifest, [two_deliveries, wrapper])
        self.validate_temp(
            manifest, [two_deliveries, wrapper],
            "one-stimulus push-foreground accepts at most one "
            "application.did-receive-remote-notification entry",
        )

        expo_manifest = _load_json(VECTORS / "manifest.valid.json")
        converter_native = load_records("native.valid.ndjson")
        converter_wrapper = load_records("wrapper.valid.ndjson")
        self.convert_wrapper_integration(
            expo_manifest, converter_native, converter_wrapper, "expo"
        )
        expo_manifest["scenario"] = "push-foreground"
        expo_manifest["stimulus"]["scenario"] = "push-foreground"
        expo_native = copy.deepcopy(with_remote_delivery)
        presentation_forward = next(
            record for record in expo_native
            if record["callback"] == "flutter.notification-center.will-present-forwarded"
        )
        presentation_forward.update({
            "callback": "expo.notifications-emitter.notification-received-event-sent",
            "owner": "expo-notifications", "phase": "result",
        })
        manager = copy.deepcopy(presentation_forward)
        manager.update({
            "callback": "expo.notification-center-manager.will-present-forwarded",
            "owner": "expo-notifications", "phase": "entry",
        })
        expo_native.insert(expo_native.index(presentation_forward), manager)
        expo_remote_forward = next(
            record for record in expo_native
            if record["callback"] == "flutter.application.did-receive-remote-notification-forwarded"
        )
        expo_remote_forward.update({
            "callback": "expo.subscriber.did-receive-remote-notification-forwarded",
            "owner": "expo-subscriber",
        })
        expo_wrapper = copy.deepcopy(wrapper)
        expo_wrapper[1]["owner"] = "expo-javascript"
        expo_manifest["aggregate_assertions"][0]["members"][0].update({
            "callback": "expo.notifications-emitter.notification-received-event-sent",
            "phase": "result",
        })
        self.normalize_capture(expo_manifest, [expo_native, expo_wrapper])
        self.validate_temp(expo_manifest, [expo_native, expo_wrapper])

        expo_duplicate = copy.deepcopy(expo_native)
        expo_forward_index = next(
            index for index, record in enumerate(expo_duplicate)
            if record["callback"] == "expo.subscriber.did-receive-remote-notification-forwarded"
        )
        expo_duplicate.insert(
            expo_forward_index, copy.deepcopy(expo_duplicate[expo_forward_index])
        )
        self.normalize_capture(expo_manifest, [expo_duplicate, expo_wrapper])
        self.validate_temp(
            expo_manifest, [expo_duplicate, expo_wrapper],
            "application.did-receive-remote-notification requires exactly one matching "
            "expo native forward, observed 2",
        )

        expo_contradictory = copy.deepcopy(expo_native)
        next(
            record for record in expo_contradictory
            if record["callback"] == "expo.subscriber.did-receive-remote-notification-forwarded"
        )["payload_summary"]["enums"]["notification_class"] = "non-customerio"
        self.normalize_capture(expo_manifest, [expo_contradictory, expo_wrapper])
        self.validate_temp(
            expo_manifest, [expo_contradictory, expo_wrapper],
            "application.did-receive-remote-notification requires exactly one matching "
            "expo native forward, observed 0",
        )

        expo_two_deliveries = copy.deepcopy(expo_native)
        expo_second_entry = copy.deepcopy(remote_entry)
        expo_second_entry["correlation"] = {"delivery": "delivery-2"}
        expo_second_forward = copy.deepcopy(expo_remote_forward)
        expo_second_forward["correlation"] = {"delivery": "delivery-2"}
        expo_two_deliveries[-1:-1] = [expo_second_entry, expo_second_forward]
        self.normalize_capture(expo_manifest, [expo_two_deliveries, expo_wrapper])
        self.validate_temp(
            expo_manifest, [expo_two_deliveries, expo_wrapper],
            "one-stimulus push-foreground accepts at most one "
            "application.did-receive-remote-notification entry",
        )

    def test_background_fetch_full_capture_completion_follows_entry(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "background-fetch"
        manifest["stimulus"].update({"scenario": "background-fetch", "source": "background-fetch-control"})
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        manifest["streams"] = [manifest["streams"][0]]
        manifest["streams"][0].update({"integration": "native-ios", "provider": "none"})
        manifest["aggregate_assertions"] = []
        empty = {"flags": {}, "counts": {}, "enums": {}}
        result = {"flags": {}, "counts": {}, "enums": {"result": "no-data"}}
        correlation = {"request": "request-1"}
        records = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.perform-background-fetch", "application-delegate",
                "os-callback", "entry", empty, correlation,
            ),
            self.runtime_record(
                "host.background-fetch-completion-result", "host", "host-routing",
                "result", result, correlation,
            ),
            copy.deepcopy(self.native[-1]),
        ]
        self.make_native_single(manifest, records)
        self.normalize_capture(manifest, [records])
        self.validate_temp(manifest, [records])
        records[1], records[2] = records[2], records[1]
        self.normalize_capture(manifest, [records])
        self.validate_temp(manifest, [records], "background-fetch completion requires causal")

    def test_fcm_registration_full_capture_orders_apns_fcm_and_customerio(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "token-registration"
        manifest["stimulus"].update({"scenario": "token-registration", "source": "system-registration"})
        manifest["provider_provenance"].update({
            "provider": "fcm", "source": "system-registration", "environment": "simulator",
            "receipt_result": "registered", "provider_sdk": None,
        })
        manifest["streams"] = [manifest["streams"][0]]
        manifest["streams"][0].update({"integration": "native-ios", "provider": "fcm"})
        manifest["aggregate_assertions"] = []
        apns_payload = {
            "flags": {"has_device_token": True}, "counts": {"device_token_bytes": 32},
            "enums": {},
        }
        fcm_payload = {
            "flags": {"has_fcm_token": True}, "counts": {"fcm_token_characters": 152},
            "enums": {},
        }
        correlation = {"request": "request-1"}
        records = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.did-register-for-remote-notifications", "application-delegate",
                "os-callback", "entry", apns_payload, correlation,
            ),
            self.runtime_record(
                "fcm.registration-token-refreshed", "fcm-messaging-delegate",
                "framework-callback", "entry", fcm_payload, correlation,
            ),
            self.runtime_record(
                "customerio.register-device-token", "customerio-sdk", "sdk-routing",
                "result", fcm_payload, correlation,
            ),
            copy.deepcopy(self.native[-1]),
        ]
        self.make_native_single(manifest, records)
        manifest["frameworks"].append({
            "name": "firebase-ios-sdk-messaging", "role": "peer",
            "version": "12.0.0", "commit_sha": None,
        })
        self.normalize_capture(manifest, [records])
        self.validate_temp(manifest, [records])
        mismatched_identity = copy.deepcopy(records)
        mismatched_identity[2]["correlation"] = {"request": "request-2"}
        mismatched_identity[3]["correlation"] = {"request": "request-2"}
        self.normalize_capture(manifest, [mismatched_identity])
        self.validate_temp(
            manifest, [mismatched_identity],
            "APNs to FCM registration must preserve correlation.request",
        )
        records[2], records[3] = records[3], records[2]
        self.normalize_capture(manifest, [records])
        self.validate_temp(manifest, [records], "Customer.io token registration requires causal")

    def test_cold_flutter_capture_requires_launch_order_and_in_process_bootstrap(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "push-tap-cold"
        manifest["stimulus"]["scenario"] = "push-tap-cold"
        launch_payload = {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}}
        empty = {"flags": {}, "counts": {}, "enums": {}}
        native = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.did-finish-launching", "application-delegate", "os-callback",
                "entry", launch_payload,
            ),
            self.runtime_record(
                "flutter.implicit-engine-created", "flutter-engine", "framework-callback",
                "result", empty,
            ),
            self.runtime_record(
                "flutter.plugin-registered", "flutter-plugin", "framework-callback",
                "result", empty,
            ),
            self.runtime_record(
                "flutter.application.did-finish-launching-forwarded", "flutter-plugin",
                "framework-callback", "entry", launch_payload,
            ),
            copy.deepcopy(self.native[1]),
            copy.deepcopy(self.native[2]),
            copy.deepcopy(self.native[3]),
            copy.deepcopy(self.native[-1]),
        ]
        wrapper = copy.deepcopy(self.wrapper)
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

        impossible_connection = copy.deepcopy(native)
        impossible_connection.insert(-1, self.runtime_record(
            "scene.will-connect", "scene-delegate", "os-callback", "entry",
            {
                "flags": {
                    "has_scene": True, "has_notification": True,
                    "has_notification_response": True, "has_shortcut": True,
                },
                "counts": {"notification_user_info_keys": 3},
                "enums": {
                    "app_state": "inactive", "scene_state": "unattached",
                    "scene_role": "application", "notification_origin": "remote",
                    "notification_class": "customerio", "delegate_peer": "host",
                    "action_class": "default",
                },
            },
        ))
        self.normalize_capture(manifest, [impossible_connection, wrapper])
        self.validate_temp(
            manifest, [impossible_connection, wrapper],
            "scene.will-connect scenario push-tap-cold forbids connectionOptions has_shortcut",
        )

        missing = [record for record in native if record["callback"] != "flutter.plugin-registered"]
        self.normalize_capture(manifest, [missing, wrapper])
        self.validate_temp(manifest, [missing, wrapper], "cold flutter acceptance requires exactly one bootstrap")

        bootstrap_reordered = copy.deepcopy(native)
        engine_index = next(
            index for index, record in enumerate(bootstrap_reordered)
            if record["callback"] == "flutter.implicit-engine-created"
        )
        plugin_index = next(
            index for index, record in enumerate(bootstrap_reordered)
            if record["callback"] == "flutter.plugin-registered"
        )
        bootstrap_reordered[engine_index], bootstrap_reordered[plugin_index] = (
            bootstrap_reordered[plugin_index], bootstrap_reordered[engine_index]
        )
        self.normalize_capture(manifest, [bootstrap_reordered, wrapper])
        self.validate_temp(
            manifest, [bootstrap_reordered, wrapper], "cold flutter bootstrap requires causal"
        )

        reordered = copy.deepcopy(native)
        launch = reordered.pop(1)
        raw_index = next(
            index for index, record in enumerate(reordered)
            if record["callback"] == "notification-center.did-receive-response"
        )
        reordered.insert(raw_index + 1, launch)
        self.normalize_capture(manifest, [reordered, wrapper])
        self.validate_temp(manifest, [reordered, wrapper], "cold launch ingress requires causal")

    def test_cold_expo_uses_pinned_subscriber_rct_and_notifications_emitter_order(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        native = load_records("native.valid.ndjson")
        wrapper = load_records("wrapper.valid.ndjson")
        self.convert_wrapper_integration(manifest, native, wrapper, "expo")
        manifest["scenario"] = "push-tap-cold"
        manifest["stimulus"]["scenario"] = "push-tap-cold"
        launch_payload = {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}}
        empty = {"flags": {}, "counts": {}, "enums": {}}
        bootstrap = [
            self.runtime_record(
                "expo.subscriber-registered", "expo-subscriber", "framework-callback",
                "result", empty,
            ),
            self.runtime_record(
                "expo.app-delegate-will-finish-launching-forwarded", "expo-framework",
                "framework-callback", "entry", launch_payload,
            ),
            self.runtime_record(
                "application.did-finish-launching", "application-delegate", "os-callback",
                "entry", launch_payload,
            ),
            self.runtime_record(
                "rct.javascript-did-load-notification", "rct-notification",
                "observer-notification", "state-change", empty,
            ),
            self.runtime_record(
                "expo.notifications-emitter-created", "expo-notifications",
                "framework-callback", "result", empty,
            ),
            self.runtime_record(
                "expo.app-delegate-did-finish-launching-forwarded", "expo-framework",
                "framework-callback", "entry", launch_payload,
            ),
        ]
        native = [native[0], *bootstrap, *native[1:-1], native[-1]]
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

        rct_before_launch = copy.deepcopy(native)
        rct_index = next(
            index for index, record in enumerate(rct_before_launch)
            if record["callback"] in {
                "rct.javascript-did-load-notification",
                "rct.instance-did-load-bundle-notification",
            }
        )
        launch_index = next(
            index for index, record in enumerate(rct_before_launch)
            if record["callback"] == "application.did-finish-launching"
        )
        rct_before_launch[rct_index], rct_before_launch[launch_index] = (
            rct_before_launch[launch_index], rct_before_launch[rct_index]
        )
        self.normalize_capture(manifest, [rct_before_launch, wrapper])
        self.validate_temp(
            manifest, [rct_before_launch, wrapper], "cold Expo launch to RCT load requires causal"
        )

        reordered = copy.deepcopy(native)
        subscriber_index = next(
            index for index, record in enumerate(reordered)
            if record["callback"] == "expo.subscriber-registered"
        )
        will_finish_index = next(
            index for index, record in enumerate(reordered)
            if record["callback"] == "expo.app-delegate-will-finish-launching-forwarded"
        )
        reordered[subscriber_index], reordered[will_finish_index] = (
            reordered[will_finish_index], reordered[subscriber_index]
        )
        self.normalize_capture(manifest, [reordered, wrapper])
        self.validate_temp(
            manifest, [reordered, wrapper], "cold expo bootstrap requires causal"
        )

    def test_dual_wrapper_lifecycle_transitions_use_state_qualified_assertions(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "app-background-foreground"
        manifest["stimulus"].update({"scenario": "app-background-foreground", "source": "app-ui"})
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        for stream in manifest["streams"]:
            stream["provider"] = "none"
        background = {"flags": {}, "counts": {}, "enums": {"app_state": "background"}}
        foreground_native = {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}}
        foreground_wrapper = {"flags": {}, "counts": {}, "enums": {"app_state": "active"}}
        native = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.did-enter-background", "application-delegate", "os-callback",
                "state-change", background,
            ),
            self.runtime_record(
                "flutter.application.did-enter-background-forwarded", "flutter-plugin",
                "framework-callback", "state-change", background,
            ),
            self.runtime_record(
                "application.will-enter-foreground", "application-delegate", "os-callback",
                "state-change", foreground_native,
            ),
            self.runtime_record(
                "flutter.application.will-enter-foreground-forwarded", "flutter-plugin",
                "framework-callback", "state-change", foreground_native,
            ),
            copy.deepcopy(self.native[-1]),
        ]
        wrapper = [
            copy.deepcopy(self.wrapper[0]),
            self.runtime_record(
                "wrapper.app-lifecycle-state", "flutter-dart", "app-received",
                "state-change", background, wrapper=True,
            ),
            self.runtime_record(
                "wrapper.app-lifecycle-state", "flutter-dart", "app-received",
                "state-change", foreground_wrapper, wrapper=True,
            ),
            copy.deepcopy(self.wrapper[-1]),
        ]
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [
            {
                "name": "background-forwarding", "relation": "equal-exact-count",
                "expected_count": 1, "members": [
                    {"stream_id": native_id, "callback": "flutter.application.did-enter-background-forwarded", "phase": "state-change", "app_state": "background"},
                    {"stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state", "phase": "state-change", "app_state": "background"},
                ],
            },
            {
                "name": "foreground-forwarding", "relation": "equal-exact-count",
                "expected_count": 1, "members": [
                    {"stream_id": native_id, "callback": "flutter.application.will-enter-foreground-forwarded", "phase": "state-change", "app_state": "inactive"},
                    {"stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state", "phase": "state-change", "app_state": "active"},
                ],
            },
        ]
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

    def test_dual_application_and_scene_lifecycle_ingress_has_unique_flutter_forwards(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "app-background-foreground"
        manifest["stimulus"].update({"scenario": "app-background-foreground", "source": "app-ui"})
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        for declaration in manifest["streams"]:
            declaration["provider"] = "none"
        background = {"flags": {}, "counts": {}, "enums": {"app_state": "background"}}
        foreground = {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}}
        scene_background = {
            "flags": {"has_scene": True}, "counts": {},
            "enums": {
                "app_state": "background", "scene_state": "background",
                "scene_role": "application",
            },
        }
        scene_foreground = {
            "flags": {"has_scene": True}, "counts": {},
            "enums": {
                "app_state": "inactive", "scene_state": "background",
                "scene_role": "application",
            },
        }
        seats = (
            ("application.did-enter-background", "application-delegate", "os-callback", background),
            ("flutter.application.did-enter-background-forwarded", "flutter-plugin", "framework-callback", background),
            ("scene.did-enter-background", "scene-delegate", "os-callback", scene_background),
            ("flutter.scene.did-enter-background-forwarded", "flutter-plugin", "framework-callback", scene_background),
            ("application.will-enter-foreground", "application-delegate", "os-callback", foreground),
            ("flutter.application.will-enter-foreground-forwarded", "flutter-plugin", "framework-callback", foreground),
            ("scene.will-enter-foreground", "scene-delegate", "os-callback", scene_foreground),
            ("flutter.scene.will-enter-foreground-forwarded", "flutter-plugin", "framework-callback", scene_foreground),
        )
        native = [copy.deepcopy(self.native[0])]
        native.extend(
            self.runtime_record(callback, owner, kind, "state-change", payload)
            for callback, owner, kind, payload in seats
        )
        native.append(copy.deepcopy(self.native[-1]))
        wrapper = [
            copy.deepcopy(self.wrapper[0]),
            self.runtime_record(
                "wrapper.app-lifecycle-state", "flutter-dart", "app-received",
                "state-change", background, wrapper=True,
            ),
            self.runtime_record(
                "wrapper.app-lifecycle-state", "flutter-dart", "app-received",
                "state-change", {"flags": {}, "counts": {}, "enums": {"app_state": "active"}},
                wrapper=True,
            ),
            copy.deepcopy(self.wrapper[-1]),
        ]
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [
            {
                "name": "background-forward", "relation": "equal-exact-count", "expected_count": 1,
                "members": [
                    {
                        "stream_id": native_id,
                        "callback": "flutter.application.did-enter-background-forwarded",
                        "phase": "state-change", "app_state": "background",
                    },
                    {
                        "stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state",
                        "phase": "state-change", "app_state": "background",
                    },
                ],
            },
            {
                "name": "foreground-forward", "relation": "equal-exact-count", "expected_count": 1,
                "members": [
                    {
                        "stream_id": native_id,
                        "callback": "flutter.application.will-enter-foreground-forwarded",
                        "phase": "state-change", "app_state": "inactive",
                    },
                    {
                        "stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state",
                        "phase": "state-change", "app_state": "active",
                    },
                ],
            },
        ]
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

        missing_scene_forward = [
            record for record in native
            if record["callback"] != "flutter.scene.did-enter-background-forwarded"
        ]
        self.normalize_capture(manifest, [missing_scene_forward, wrapper])
        self.validate_temp(
            manifest, [missing_scene_forward, wrapper],
            "scene.did-enter-background requires exactly one matching flutter native forward, observed 0",
        )

        self.normalize_capture(manifest, [native, wrapper])
        invalid_manifest = copy.deepcopy(manifest)
        for assertion in invalid_manifest["aggregate_assertions"]:
            for member in assertion["members"]:
                member.pop("app_state")
        self.validate_temp(
            invalid_manifest, [native, wrapper],
            "app-background-foreground aggregate selectors require app_state qualification",
        )

        reversed_native = [native[0], *native[5:9], *native[1:5], native[-1]]
        self.normalize_capture(manifest, [reversed_native, wrapper])
        self.validate_temp(
            manifest, [reversed_native, wrapper], "app background observations must precede foreground"
        )

    def test_full_capture_rejects_callback_incompatible_app_state(self) -> None:
        native = copy.deepcopy(self.native)
        invalid_state = self.runtime_record(
            "application.did-enter-background", "application-delegate", "os-callback",
            "state-change", {"flags": {}, "counts": {}, "enums": {"app_state": "active"}},
        )
        native.insert(-1, invalid_state)
        self.normalize_capture(self.manifest, [native, self.wrapper])
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "application.did-enter-background app_state=active is incompatible",
        )

    def test_universal_link_activity_handoff_ignores_incidental_url_facts(self) -> None:
        manifest = _load_json(VECTORS / "manifest.valid.json")
        manifest["scenario"] = "universal-link-warm"
        manifest["stimulus"].update({"scenario": "universal-link-warm", "source": "app-ui"})
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        for stream in manifest["streams"]:
            stream["provider"] = "none"
        native_payload = {
            "flags": {"has_user_activity": True, "has_url": True},
            "counts": {
                "user_activities": 1, "url_path_components": 2, "url_query_items": 0,
            },
            "enums": {
                "activity_class": "web-browsing", "url_scheme": "https", "url_class": "web",
            },
        }
        wrapper_payload = {
            "flags": {"has_user_activity": True}, "counts": {"user_activities": 1},
            "enums": {"activity_class": "web-browsing"},
        }
        correlation = {"url": "url-1"}
        native = [
            copy.deepcopy(self.native[0]),
            self.runtime_record(
                "application.continue-user-activity", "application-delegate", "os-callback",
                "entry", native_payload, correlation,
            ),
            self.runtime_record(
                "flutter.application.continue-user-activity-forwarded", "flutter-plugin",
                "framework-callback", "entry", native_payload, correlation,
            ),
            copy.deepcopy(self.native[-1]),
        ]
        wrapper = [
            copy.deepcopy(self.wrapper[0]),
            self.runtime_record(
                "wrapper.app-received-user-activity", "flutter-dart", "app-received",
                "entry", wrapper_payload, wrapper=True,
            ),
            copy.deepcopy(self.wrapper[-1]),
        ]
        manifest["aggregate_assertions"] = [{
            "name": "activity-forwarding", "relation": "equal-exact-count", "expected_count": 1,
            "members": [
                {"stream_id": manifest["streams"][0]["stream_id"], "callback": "flutter.application.continue-user-activity-forwarded", "phase": "entry"},
                {"stream_id": manifest["streams"][1]["stream_id"], "callback": "wrapper.app-received-user-activity", "phase": "entry"},
            ],
        }]
        self.normalize_capture(manifest, [native, wrapper])
        self.validate_temp(manifest, [native, wrapper])

    def test_valid_zero_call_completion_fixture(self) -> None:
        validate_capture(
            VECTORS / "manifest.completion-valid.json",
            [VECTORS / "completion.valid-zero-call.ndjson"],
            HERE,
        )

    def test_native_producer_note_withdraws_false_conformance_claims(self) -> None:
        note = (HERE / "IOS27-LIFECYCLE-CALLBACK-CONTRACT.md").read_text(encoding="utf-8")
        self.assertIn("producer draft is not conformant", note)
        self.assertIn("earlier statements that seven synthetic L0 records validated", note)
        self.assertIn("are withdrawn", note)
        self.assertIn("Do not use output from the frozen Swift draft", note)

    def test_callback_enum_has_relational_rule(self) -> None:
        schema = _load_json(HERE / "ios27-lifecycle-trace-v1.schema.json")
        callbacks = set(schema["properties"]["callback"]["enum"])
        generic = {
            "wrapper.app-received-url", "wrapper.app-received-user-activity",
            "wrapper.app-received-notification", "wrapper.app-received-quick-action",
            "wrapper.app-lifecycle-state",
        }
        self.assertEqual(callbacks, set(CALLBACK_RULES).union(generic))

    def test_sibling_schemas_share_registry_and_canonical_time_pattern(self) -> None:
        trace_schema = _load_json(HERE / "ios27-lifecycle-trace-v1.schema.json")
        manifest_schema = _load_json(HERE / "ios27-lifecycle-capture-manifest-v1.schema.json")
        self.assertEqual(
            set(manifest_schema["$defs"]["framework_name"]["enum"]), set(FRAMEWORK_ROLES)
        )
        self.assertEqual(
            trace_schema["$defs"]["date_time"]["pattern"],
            manifest_schema["$defs"]["date_time"]["pattern"],
        )

    def test_aggregate_zero_equals_zero_is_invalid(self) -> None:
        self.assertEqual(self.aggregate_vectors[0]["observed_count_per_member"], 0)
        native = load_records("native.invalid-aggregate-zero.ndjson")
        wrapper = load_records("wrapper.invalid-aggregate-zero.ndjson")
        sync_receipt(self.manifest, 0, native)
        sync_receipt(self.manifest, 1, wrapper)
        self.validate_temp(self.manifest, [native, wrapper], "requires exactly one defining callback.*observed 0")

    def test_aggregate_two_equals_two_is_invalid(self) -> None:
        self.assertEqual(self.aggregate_vectors[1]["observed_count_per_member"], 2)
        native = copy.deepcopy(self.native)
        wrapper = copy.deepcopy(self.wrapper)
        for records in (native, wrapper):
            duplicate = copy.deepcopy(records[1])
            duplicate["sequence"] = 3
            duplicate["monotonic_ms"] += 1
            duplicate["captured_at"] = "2026-08-11T16:00:03.250Z"
            for record in records[2:]:
                record["sequence"] += 1
                record["monotonic_ms"] += 1
            records.insert(2, duplicate)
        sync_receipt(self.manifest, 0, native)
        sync_receipt(self.manifest, 1, wrapper)
        self.validate_temp(self.manifest, [native, wrapper], "requires exactly one defining callback.*observed 2")

    def test_expected_count_zero_is_schema_invalid(self) -> None:
        self.manifest["aggregate_assertions"][0]["expected_count"] = 0
        self.validate_temp(self.manifest, [self.native, self.wrapper], "1 was expected")

    def test_multi_stream_acceptance_requires_aggregate(self) -> None:
        self.manifest["aggregate_assertions"] = []
        self.validate_temp(self.manifest, [self.native, self.wrapper], "requires at least one aggregate")

    def test_aggregate_selector_cannot_use_trace_control_or_fixture(self) -> None:
        for index, member in enumerate(self.manifest["aggregate_assertions"][0]["members"]):
            member.update({
                "callback": "trace.scenario-start",
                "phase": "state-change",
                "stream_id": self.manifest["streams"][index]["stream_id"],
            })
        self.validate_temp(
            self.manifest, [self.native, self.wrapper],
            "schema violation at aggregate_assertions.0.members.0.callback",
        )

    def test_single_stream_unrelated_runtime_callback_is_not_acceptance(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        records = copy.deepcopy(self.native)
        self.make_native_single(manifest, records)
        records[1].update({
            "callback": "application.did-become-active", "phase": "state-change",
            "owner": "application-delegate", "kind": "os-callback",
            "payload_summary": {
                "flags": {}, "counts": {}, "enums": {"app_state": "active"},
            },
        })
        sync_receipt(manifest, 0, records)
        self.validate_temp(
            manifest, [records], "requires exactly one defining callback.*observed 0"
        )

    def test_single_stream_defining_callback_is_exactly_once(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        records = copy.deepcopy(self.native)
        self.make_native_single(manifest, records)
        duplicate = copy.deepcopy(records[1])
        duplicate.update({
            "sequence": 3, "monotonic_ms": 1002,
            "captured_at": "2026-08-11T16:00:03.500Z",
        })
        records[-1].update({
            "sequence": 4, "monotonic_ms": 1003,
            "captured_at": "2026-08-11T16:00:04Z",
        })
        records.insert(2, duplicate)
        self.normalize_capture(manifest, [records])
        self.validate_temp(
            manifest, [records], "requires exactly one defining callback.*observed 2"
        )

    def test_handoff_requires_same_supported_integration(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["streams"][1].update({"integration": "expo", "runtime": "javascript"})
        with self.assertRaisesRegex(ContractError, "shared supported integration"):
            _validate_scenario_acceptance(
                manifest,
                {
                    manifest["streams"][0]["stream_id"]: self.native,
                    manifest["streams"][1]["stream_id"]: self.wrapper,
                },
            )
        self.validate_temp(
            manifest, [self.native, self.wrapper], "must match repository/framework provenance"
        )

    def test_wrapper_acceptance_requires_both_runtime_seats(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["streams"] = [manifest["streams"][0]]
        manifest["aggregate_assertions"] = []
        self.validate_temp(
            manifest, [self.native],
            "flutter L2/L3 acceptance requires exactly one Swift and one dart runtime seat",
        )

    def test_wrapper_process_identity_is_proven(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["streams"][1]["process_id"] = 322
        self.validate_temp(
            manifest, [self.native, self.wrapper],
            "Flutter Swift/Dart seats require the same non-null process_id",
        )

        manifest = copy.deepcopy(self.manifest)
        manifest["streams"][1]["process_instance_id"] = (
            "77777777-7777-4777-8777-777777777777"
        )
        self.validate_temp(
            manifest, [self.native, self.wrapper], "shared process_instance_id"
        )

    def test_javascript_null_pid_uses_shared_process_instance_proof(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["streams"][0].update({"integration": "expo", "runtime": "swift"})
        manifest["streams"][1].update({
            "integration": "expo", "runtime": "javascript", "process_id": None,
        })
        _validate_scenario_acceptance(
            manifest,
            {
                manifest["streams"][0]["stream_id"]: self.native,
                manifest["streams"][1]["stream_id"]: self.wrapper,
            },
        )
        manifest["streams"][1]["process_instance_id"] = (
            "77777777-7777-4777-8777-777777777777"
        )
        with self.assertRaisesRegex(ContractError, "shared process_instance_id"):
            _validate_scenario_acceptance(
                manifest,
                {
                    manifest["streams"][0]["stream_id"]: self.native,
                    manifest["streams"][1]["stream_id"]: self.wrapper,
                },
            )

    def test_notification_handoff_reconciles_safe_classification(self) -> None:
        with self.assertRaisesRegex(ContractError, "payload facts do not reconcile"):
            validate_capture(
                VECTORS / "manifest.valid.json",
                [
                    VECTORS / "native.valid.ndjson",
                    VECTORS / "wrapper.invalid-handoff-classification.ndjson",
                ],
                HERE,
            )

    def test_url_activity_and_action_handoffs_reconcile_safe_facts(self) -> None:
        cases = (
            (
                "custom-url-warm", "application.open-url", "wrapper.app-received-url",
                {
                    "flags": {"has_url": True},
                    "counts": {"url_path_components": 1, "url_query_items": 0},
                    "enums": {"url_scheme": "custom", "url_class": "custom-scheme"},
                },
                ("counts", "url_query_items", 1),
            ),
            (
                "universal-link-warm", "application.continue-user-activity",
                "wrapper.app-received-user-activity",
                {
                    "flags": {"has_user_activity": True},
                    "counts": {"user_activities": 1},
                    "enums": {"activity_class": "web-browsing"},
                },
                ("enums", "activity_class", "custom"),
            ),
            (
                "quick-action-warm", "application.perform-quick-action",
                "wrapper.app-received-quick-action",
                {
                    "flags": {"has_shortcut": True}, "counts": {},
                    "enums": {"action_class": "default"},
                },
                ("enums", "action_class", "custom"),
            ),
        )
        for scenario, native_callback, wrapper_callback, payload, mutation in cases:
            with self.subTest(scenario=scenario):
                manifest = copy.deepcopy(self.manifest)
                manifest["scenario"] = scenario
                native_id = manifest["streams"][0]["stream_id"]
                wrapper_id = manifest["streams"][1]["stream_id"]
                manifest["aggregate_assertions"] = [{
                    "name": "safe-facts", "relation": "equal-exact-count", "expected_count": 1,
                    "members": [
                        {"stream_id": native_id, "callback": native_callback, "phase": "entry"},
                        {"stream_id": wrapper_id, "callback": wrapper_callback, "phase": "entry"},
                    ],
                }]
                native_record = {"callback": native_callback, "phase": "entry", "payload_summary": copy.deepcopy(payload)}
                wrapper_payload = copy.deepcopy(payload)
                section, field, value = mutation
                wrapper_payload[section][field] = value
                wrapper_record = {"callback": wrapper_callback, "phase": "entry", "payload_summary": wrapper_payload}
                with self.assertRaisesRegex(ContractError, "payload facts do not reconcile"):
                    _validate_scenario_acceptance(
                        manifest, {native_id: [native_record], wrapper_id: [wrapper_record]}
                    )

    def test_warm_notification_handoff_rejects_cold_pull_selector(self) -> None:
        self.manifest["aggregate_assertions"][0]["members"][0].update({
            "callback": "expo.last-notification-response-pulled", "phase": "result",
        })
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "unrelated to scenario push-tap-warm"
        )

        record = copy.deepcopy(self.native[1])
        record.update({
            "callback": "expo.last-notification-response-pulled", "scenario": "push-tap-warm",
            "payload_summary": {
                "flags": {"has_notification": True, "has_notification_response": True},
                "counts": {},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "host", "app_state": "active",
                    "action_class": "default",
                },
            },
        })
        with self.assertRaisesRegex(ContractError, "valid only for a cold notification-tap"):
            _validate_payload(record)

    def test_local_notification_handoff_rejects_remote_delivery_selector(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "local-notification-foreground"
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [{
            "name": "wrong-local-handoff", "relation": "equal-exact-count",
            "expected_count": 1,
            "members": [
                {
                    "stream_id": native_id,
                    "callback": "application.did-receive-remote-notification",
                    "phase": "entry",
                },
                {
                    "stream_id": wrapper_id,
                    "callback": "wrapper.app-received-notification", "phase": "entry",
                },
            ],
        }]
        notification = {
            "flags": {"has_notification": True}, "counts": {},
            "enums": {
                "notification_origin": "local", "notification_class": "customerio",
                "delegate_peer": "host",
            },
        }
        presentation = copy.deepcopy(notification)
        presentation["flags"].update({
            "presentation_alert": False, "presentation_badge": False,
            "presentation_sound": False, "presentation_banner": False,
            "presentation_list": False,
        })
        presentation["counts"]["presentation_options"] = 0
        presentation["enums"]["presentation_class"] = "suppressed"
        native_records = [
            {"callback": "notification-center.will-present", "phase": "entry",
             "payload_summary": copy.deepcopy(notification)},
            {"callback": "host.present-notification", "phase": "result",
             "payload_summary": presentation},
            {"callback": "application.did-receive-remote-notification", "phase": "entry",
             "payload_summary": copy.deepcopy(notification)},
        ]
        wrapper_records = [{
            "callback": "wrapper.app-received-notification", "phase": "entry",
            "payload_summary": copy.deepcopy(notification),
        }]
        with self.assertRaisesRegex(ContractError, "unrelated to scenario"):
            _validate_scenario_acceptance(
                manifest, {native_id: native_records, wrapper_id: wrapper_records}
            )

    def test_remote_delivery_callback_always_has_remote_origin(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "local-notification-foreground",
            "callback": "application.did-receive-remote-notification",
        })
        record["payload_summary"]["flags"]["has_notification_response"] = False
        record["payload_summary"]["enums"]["notification_origin"] = "local"
        with self.assertRaisesRegex(ContractError, "always requires notification_origin=remote"):
            _validate_payload(record)

    def test_foreground_acceptance_requires_one_host_presentation_result(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "push-foreground"
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [{
            "name": "foreground-handoff", "relation": "equal-exact-count",
            "expected_count": 1,
            "members": [
                {"stream_id": native_id, "callback": "notification-center.will-present", "phase": "entry"},
                {"stream_id": wrapper_id, "callback": "wrapper.app-received-notification", "phase": "entry"},
            ],
        }]
        payload = {
            "flags": {"has_notification": True}, "counts": {},
            "enums": {
                "notification_origin": "remote", "notification_class": "customerio",
                "delegate_peer": "host",
            },
        }
        will_present = {
            "callback": "notification-center.will-present", "phase": "entry",
            "payload_summary": copy.deepcopy(payload),
        }
        wrapper = {
            "callback": "wrapper.app-received-notification", "phase": "entry",
            "payload_summary": copy.deepcopy(payload),
        }
        with self.assertRaisesRegex(ContractError, "host.present-notification.*observed 0"):
            _validate_scenario_acceptance(
                manifest, {native_id: [will_present], wrapper_id: [wrapper]}
            )
        host = {
            "callback": "host.present-notification", "phase": "result",
            "payload_summary": copy.deepcopy(payload),
        }
        _validate_scenario_acceptance(
            manifest, {native_id: [will_present, host], wrapper_id: [wrapper]}
        )
        with self.assertRaisesRegex(ContractError, "host.present-notification.*observed 2"):
            _validate_scenario_acceptance(
                manifest, {native_id: [will_present, host, copy.deepcopy(host)], wrapper_id: [wrapper]}
            )

    def test_acceptance_stream_requires_non_control_observation(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        native = [copy.deepcopy(self.native[0]), copy.deepcopy(self.native[-1])]
        native[-1]["sequence"] = 2
        self.make_native_single(manifest, native)
        sync_receipt(manifest, 0, native)
        self.validate_temp(manifest, [native], "requires a non-control runtime observation")

    def test_external_entry_callback_cannot_come_from_another_scenario(self) -> None:
        native = copy.deepcopy(self.native)
        quick_action = copy.deepcopy(native[1])
        quick_action.update({
            "sequence": 3, "monotonic_ms": 1002,
            "captured_at": "2026-08-11T16:00:03.500Z",
            "owner": "application-delegate", "kind": "os-callback",
            "callback": "application.perform-quick-action", "phase": "entry",
            "payload_summary": {
                "flags": {"has_shortcut": True}, "counts": {},
                "enums": {"action_class": "default"},
            },
        })
        native[-1].update({"sequence": 4, "monotonic_ms": 1003})
        native.insert(2, quick_action)
        sync_receipt(self.manifest, 0, native)
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "application.perform-quick-action is an external-entry seat that cannot occur",
        )

    def test_lifecycle_side_effect_is_allowed_inside_push_scenario(self) -> None:
        native = copy.deepcopy(self.native)
        lifecycle = copy.deepcopy(native[1])
        lifecycle.update({
            "sequence": 4, "monotonic_ms": 1003,
            "captured_at": "2026-08-11T16:00:03.750Z",
            "owner": "application-delegate", "kind": "os-callback",
            "callback": "application.did-become-active", "phase": "state-change",
            "payload_summary": {
                "flags": {}, "counts": {}, "enums": {"app_state": "active"},
            },
        })
        native[-1].update({"sequence": 5, "monotonic_ms": 1004})
        native.insert(-1, lifecycle)
        self.normalize_capture(self.manifest, [native, self.wrapper])
        self.validate_temp(self.manifest, [native, self.wrapper])

    def test_application_and_scene_transitions_can_both_define_lifecycle_run(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "app-background-foreground"
        manifest["stimulus"].update({
            "scenario": "app-background-foreground", "source": "app-ui",
        })
        manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
            "provider_sdk": None,
        })
        manifest["streams"] = [manifest["streams"][0]]
        manifest["streams"][0]["integration"] = "native-ios"
        manifest["streams"][0]["provider"] = "none"
        manifest["aggregate_assertions"] = []
        start = copy.deepcopy(self.native[0])
        end = copy.deepcopy(self.native[-1])
        for record in (start, end):
            record.update({
                "scenario": "app-background-foreground", "provider": "none",
                "integration": "native-ios",
            })
        seats = (
            ("application.did-enter-background", "application-delegate", {}, {"app_state": "background"}),
            (
                "scene.did-enter-background", "scene-delegate", {"has_scene": True},
                {"app_state": "background", "scene_state": "background", "scene_role": "application"},
            ),
            ("application.will-enter-foreground", "application-delegate", {}, {"app_state": "background"}),
            (
                "scene.will-enter-foreground", "scene-delegate", {"has_scene": True},
                {"app_state": "background", "scene_state": "background", "scene_role": "application"},
            ),
        )
        records = [start]
        for index, (callback, owner, flags, enums) in enumerate(seats, 2):
            record = copy.deepcopy(self.native[1])
            record.update({
                "sequence": index, "monotonic_ms": 1000 + index,
                "captured_at": f"2026-08-11T16:00:0{index + 1}Z",
                "provider": "none", "scenario": "app-background-foreground",
                "integration": "native-ios",
                "callback": callback, "owner": owner, "phase": "state-change",
                "payload_summary": {"flags": flags, "counts": {}, "enums": enums},
            })
            records.append(record)
        end.update({
            "sequence": 6, "monotonic_ms": 1006,
            "captured_at": "2026-08-11T16:00:08Z",
        })
        records.append(end)
        self.make_native_single(manifest, records)
        sync_receipt(manifest, 0, records)
        manifest["streams"][0]["receipt"]["drained_at"] = "2026-08-11T16:00:09Z"
        self.validate_temp(manifest, [records])

        duplicate = copy.deepcopy(records[1])
        with self.assertRaisesRegex(ContractError, "at most one per callback seat"):
            _validate_scenario_acceptance(
                manifest, {manifest["streams"][0]["stream_id"]: records + [duplicate]}
            )

    def test_lifecycle_handoff_reconciles_state_but_scene_aliases_stay_stream_local(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "app-background-foreground"
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [{
            "name": "scene-state-handoff", "relation": "equal-exact-count",
            "expected_count": 1,
            "members": [
                {"stream_id": native_id, "callback": "scene.did-enter-background", "phase": "state-change"},
                {"stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state", "phase": "state-change"},
            ],
        }]
        background = {
            "callback": "scene.did-enter-background", "phase": "state-change",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "background"}},
            "correlation": {"scene": "scene-1"},
        }
        foreground = {
            "callback": "scene.will-enter-foreground", "phase": "state-change",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "background"}},
            "correlation": {"scene": "scene-1"},
        }
        wrapper = {
            "callback": "wrapper.app-lifecycle-state", "phase": "state-change",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "background"}},
            "correlation": {"scene": "scene-1"},
        }
        records = {native_id: [background, foreground], wrapper_id: [wrapper]}
        _validate_scenario_acceptance(manifest, records)
        wrapper["payload_summary"]["enums"]["app_state"] = "active"
        with self.assertRaisesRegex(ContractError, "payload facts do not reconcile"):
            _validate_scenario_acceptance(manifest, records)
        wrapper["payload_summary"]["enums"]["app_state"] = "background"
        wrapper["correlation"]["scene"] = "scene-2"
        _validate_scenario_acceptance(manifest, records)
        background["correlation"] = None
        _validate_scenario_acceptance(manifest, records)

    def test_icon_launch_handoff_reconciles_app_state(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "icon-cold-launch"
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [{
            "name": "launch-state-handoff", "relation": "equal-exact-count",
            "expected_count": 1,
            "members": [
                {"stream_id": native_id, "callback": "application.did-finish-launching", "phase": "entry"},
                {"stream_id": wrapper_id, "callback": "wrapper.app-lifecycle-state", "phase": "state-change"},
            ],
        }]
        native = {
            "callback": "application.did-finish-launching", "phase": "entry",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}},
        }
        wrapper = {
            "callback": "wrapper.app-lifecycle-state", "phase": "state-change",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}},
        }
        records = {native_id: [native], wrapper_id: [wrapper]}
        _validate_scenario_acceptance(manifest, records)
        wrapper["payload_summary"]["enums"]["app_state"] = "active"
        with self.assertRaisesRegex(ContractError, "payload facts do not reconcile"):
            _validate_scenario_acceptance(manifest, records)

    def test_remote_provider_must_be_compatible(self) -> None:
        self.manifest["provider_provenance"].update({
            "provider": "none", "source": "none", "environment": "none",
            "receipt_result": "not-applicable", "receipt_recorded_at": None,
        })
        self.validate_temp(self.manifest, [self.native, self.wrapper], "require provider apn or fcm")

    def test_l3_remote_rejects_simulator_injection(self) -> None:
        self.manifest["evidence_level"] = "L3"
        self.manifest["sdk"]["name"] = "iphoneos"
        self.manifest["target"]["kind"] = "physical-device"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "L3 remote evidence requires a real provider path")

    def test_local_scenario_rejects_remote_provenance(self) -> None:
        self.manifest["scenario"] = "local-notification-tap-warm"
        self.manifest["stimulus"]["scenario"] = "local-notification-tap-warm"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "local scheduling provenance")

    def test_provider_receipt_cannot_predate_stimulus(self) -> None:
        self.manifest["provider_provenance"]["receipt_recorded_at"] = "2026-08-11T16:00:01Z"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "must not predate")

    def test_runtime_observation_must_follow_provider_acceptance_barrier(self) -> None:
        native = copy.deepcopy(self.native)
        native[1]["captured_at"] = "2026-08-11T16:00:02.250Z"
        self.validate_temp(
            self.manifest, [native, self.wrapper], "runtime observation predates"
        )

    def test_cold_start_cannot_record_scenario_start_before_stimulus(self) -> None:
        self.manifest["scenario"] = "push-tap-cold"
        self.manifest["stimulus"]["scenario"] = "push-tap-cold"
        for records in (self.native, self.wrapper):
            for record in records:
                record["scenario"] = "push-tap-cold"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "cold-start scenario-start predates"
        )

    def test_provider_api_sdk_name_must_match_apn_or_fcm(self) -> None:
        for provider, wrong_sdk in (
            ("apn", "fcm-provider-sdk"), ("fcm", "apns-provider-sdk"),
        ):
            with self.subTest(provider=provider):
                manifest = copy.deepcopy(self.manifest)
                manifest["provider_provenance"].update({
                    "provider": provider, "source": "provider-api",
                    "environment": "sandbox", "receipt_result": "accepted",
                    "provider_sdk": {"name": wrong_sdk, "version": "1.0.0"},
                })
                manifest["stimulus"]["source"] = "provider"
                for stream in manifest["streams"]:
                    stream["provider"] = provider
                expected = "apns-provider-sdk" if provider == "apn" else "fcm-provider-sdk"
                self.validate_temp(
                    manifest, [self.native, self.wrapper], f"requires {expected}"
                )

    def test_provider_console_must_not_claim_api_sdk(self) -> None:
        self.manifest["provider_provenance"].update({
            "source": "provider-console", "environment": "sandbox",
            "receipt_result": "accepted",
            "provider_sdk": {"name": "apns-provider-sdk", "version": "1.0.0"},
        })
        self.manifest["stimulus"]["source"] = "provider"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "must not claim a provider SDK"
        )

    def test_record_timestamp_must_be_monotonic_and_bounded(self) -> None:
        native = copy.deepcopy(self.native)
        native[1]["captured_at"] = "2026-08-11T15:59:58Z"
        self.validate_temp(self.manifest, [native, self.wrapper], "outside run bounds")
        native = copy.deepcopy(self.native)
        native[-1]["captured_at"] = "2026-08-11T16:00:02.750Z"
        self.validate_temp(self.manifest, [native, self.wrapper], "captured_at decreased")

    def test_missing_tail_is_invalid(self) -> None:
        native = copy.deepcopy(self.native[:-1])
        self.validate_temp(self.manifest, [native, self.wrapper], "one final scenario-end")

    def test_scenario_start_requires_pristine_alias_and_correlation_state(self) -> None:
        for field in ("alias", "correlation", "high-water"):
            with self.subTest(field=field):
                native = copy.deepcopy(self.native)
                if field == "alias":
                    native[0]["recorder"]["alias_counts"]["delivery"] = 1
                else:
                    if field == "correlation":
                        native[0]["correlation"] = {"delivery": "delivery-1"}
                        native[0]["recorder"]["alias_counts"]["delivery"] = 1
                    else:
                        native[0]["recorder"]["buffer_high_watermark"] = 2
                self.validate_temp(
                    self.manifest, [native, self.wrapper], "scenario-start must have pristine"
                )

    def test_post_drain_receipt_must_match_final_snapshot(self) -> None:
        self.manifest["streams"][0]["receipt"]["buffer_high_watermark"] = 2
        self.validate_temp(self.manifest, [self.native, self.wrapper], "post-drain receipt buffer_high_watermark")
        manifest = copy.deepcopy(self.manifest)
        manifest["streams"][0]["receipt"]["drained_at"] = "2026-08-11T16:00:03Z"
        self.validate_temp(manifest, [self.native, self.wrapper], "drain receipt time is incoherent")

    def test_safe_label_rejects_url_shaped_scheme(self) -> None:
        self.manifest["build"]["scheme"] = "https://example.test?q=secret#fragment"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "does not match")

    def test_safe_label_rejects_email_shaped_identifier(self) -> None:
        self.manifest["build"]["scheme"] = "alice@example.com"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper],
            "schema violation at build.scheme: .* does not match",
        )

    def test_dirty_repository_requires_snapshot_hashes(self) -> None:
        self.manifest["repositories"][0]["dirty"] = True
        self.validate_temp(self.manifest, [self.native, self.wrapper], "is not of type 'object'")

    def test_framework_repository_commit_must_match(self) -> None:
        self.manifest["frameworks"][0]["commit_sha"] = "3333333333333333333333333333333333333333"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "commit mismatch")

    def test_framework_role_is_exact(self) -> None:
        self.manifest["frameworks"][2]["role"] = "peer"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "incorrect role")

    def test_same_commit_customerio_modules_require_coherent_versions(self) -> None:
        framework = {
            "name": "customerio-messaging-push", "role": "sdk", "version": "999.0",
            "commit_sha": self.manifest["repositories"][0]["commit_sha"],
        }
        self.manifest["frameworks"].append(framework)
        self.validate_temp(
            self.manifest, [self.native, self.wrapper],
            "customerio-ios modules at the same commit must use one coherent version",
        )
        framework["version"] = self.manifest["frameworks"][0]["version"]
        self.validate_temp(self.manifest, [self.native, self.wrapper])

    def test_deployment_target_and_physical_architecture_are_reconciled(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["build"]["deployment_target"] = "27.0"
        self.validate_temp(manifest, [self.native, self.wrapper], "deployment target")
        manifest = copy.deepcopy(self.manifest)
        manifest["evidence_level"] = "diagnostic"
        manifest["target"]["kind"] = "physical-device"
        manifest["target"]["architecture"] = "x86_64"
        self.validate_temp(manifest, [self.native, self.wrapper], "physical-device captures require arm64")

        manifest = copy.deepcopy(self.manifest)
        manifest["target"]["os_version"] = "12.4"
        self.validate_temp(
            manifest, [self.native, self.wrapper], "target OS version must be at least"
        )

    def test_target_model_rejects_udid_shaped_safe_label(self) -> None:
        self.manifest["target"]["model"] = "01234567-89AB-CDEF-0123-456789ABCDEF"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "schema violation at target.model"
        )

    def test_target_model_rejects_serial_shaped_label(self) -> None:
        self.manifest["target"]["model"] = "C02ZQ0ABCDEF"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "schema violation at target.model"
        )

    def test_target_model_and_os_name_are_coherent(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["target"]["os_name"] = "iPadOS"
        self.validate_temp(
            manifest, [self.native, self.wrapper], "iPhone and iPod touch.*os_name=iOS"
        )

        manifest = copy.deepcopy(self.manifest)
        manifest["target"].update({"model": "iPad Pro", "os_name": "iOS"})
        self.validate_temp(
            manifest, [self.native, self.wrapper], "iPad target models require os_name=iPadOS"
        )

        manifest["target"]["os_name"] = "iPadOS"
        self.validate_temp(manifest, [self.native, self.wrapper])

    def test_identifier_substrings_are_rejected_across_provenance_labels(self) -> None:
        identifier = "01234567-89ab-cdef-0123-456789abcdef"
        mutations = (
            ("target.model", lambda manifest: manifest["target"].update({"model": f"Lab-{identifier}-Phone"})),
            ("toolchain.xcode_build", lambda manifest: manifest["toolchain"].update({"xcode_build": f"Build-{identifier}"})),
            ("frameworks.0.version", lambda manifest: manifest["frameworks"][0].update({"version": f"v-{identifier}"})),
        )
        for field, mutate in mutations:
            with self.subTest(field=field):
                manifest = copy.deepcopy(self.manifest)
                mutate(manifest)
                self.validate_temp(
                    manifest, [self.native, self.wrapper], f"schema violation at {field.replace('.0', '.0')}"
                )

    def test_acceptance_product_must_be_application(self) -> None:
        self.manifest["build"]["product_kind"] = "unit-test"
        self.validate_temp(
            self.manifest, [self.native, self.wrapper],
            "schema violation at build.product_kind: 'application' was expected",
        )

    def test_flutter_toolchain_and_framework_versions_match(self) -> None:
        self.manifest["toolchain"]["flutter_version"] = "3.41.5"
        self.validate_temp(self.manifest, [self.native, self.wrapper], "must match")

    def test_swift_runtime_requires_swift_toolchain_version(self) -> None:
        self.manifest["toolchain"]["swift_version"] = None
        self.validate_temp(
            self.manifest, [self.native, self.wrapper], "Swift runtime streams require"
        )

    def test_provider_sdk_must_match_framework_peer(self) -> None:
        self.manifest["provider_provenance"]["provider_sdk"] = {
            "name": "apns-provider-sdk", "version": "1.0.0"
        }
        self.validate_temp(self.manifest, [self.native, self.wrapper], "must not claim a provider SDK")

        manifest = copy.deepcopy(self.manifest)
        manifest["provider_provenance"].update({
            "source": "provider-api", "environment": "sandbox",
            "receipt_result": "accepted",
            "provider_sdk": {"name": "apns-provider-sdk", "version": "1.0.0"},
        })
        manifest["stimulus"]["source"] = "provider"
        self.validate_temp(
            manifest, [self.native, self.wrapper], "provider SDK provenance must match"
        )

    def test_unit_fixture_cannot_claim_provider_sdk(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        manifest["provider_provenance"]["provider_sdk"] = {
            "name": "apns-provider-sdk", "version": "1.0.0",
        }
        self.validate_temp(manifest, [records], "unit-fixture must use diagnostic none provenance")

    def test_native_only_acceptance_scenarios_reject_multiple_streams(self) -> None:
        cases = (
            ("token-registration", "system-registration", "registered", "system-registration"),
            ("registration-failure", "system-registration", "failed", "system-registration"),
            ("background-fetch", "none", "not-applicable", "background-fetch-control"),
            ("notification-settings", "none", "not-applicable", "system-settings"),
        )
        for scenario, source, result, stimulus_source in cases:
            with self.subTest(scenario=scenario):
                manifest = copy.deepcopy(self.manifest)
                manifest["scenario"] = scenario
                manifest["stimulus"].update({"scenario": scenario, "source": stimulus_source})
                if source == "system-registration":
                    manifest["provider_provenance"].update({
                        "provider": "apn", "source": source, "environment": "simulator",
                        "receipt_result": result, "provider_sdk": None,
                    })
                else:
                    manifest["provider_provenance"].update({
                        "provider": "none", "source": "none", "environment": "none",
                        "receipt_result": result, "receipt_recorded_at": None,
                        "provider_sdk": None,
                    })
                    for stream in manifest["streams"]:
                        stream["provider"] = "none"
                self.validate_temp(
                    manifest, [self.native, self.wrapper], "native-side single-stream acceptance topology"
                )

    def test_expo_and_fcm_internal_peers_are_required(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["repositories"] = [
            item for item in manifest["repositories"] if item["name"] != "customerio-flutter"
        ]
        manifest["frameworks"] = [
            item for item in manifest["frameworks"]
            if item["name"] not in ("customerio-flutter", "flutter")
        ]
        manifest["streams"][0].update({"integration": "expo", "runtime": "swift"})
        manifest["streams"][1].update({"integration": "expo", "runtime": "javascript"})
        manifest["toolchain"].update({"node_version": "20.19.0", "expo_cli_version": "57.0.0"})
        manifest["repositories"].append({
            "name": "customerio-expo-plugin",
            "commit_sha": "3333333333333333333333333333333333333333",
            "dirty": False, "source_snapshot": None,
        })
        self.validate_temp(manifest, [self.native, self.wrapper], "missing repository provenance")
        manifest["repositories"].append({
            "name": "customerio-reactnative",
            "commit_sha": "4444444444444444444444444444444444444444",
            "dirty": False, "source_snapshot": None,
        })
        self.validate_temp(manifest, [self.native, self.wrapper], "missing framework peers")

        fcm = copy.deepcopy(self.manifest)
        fcm["provider_provenance"]["provider"] = "fcm"
        for stream in fcm["streams"]:
            stream["provider"] = "fcm"
        self.validate_temp(fcm, [self.native, self.wrapper], "missing framework peers")

    def test_fcm_token_observation_requires_firebase_peer_even_in_apn_run(self) -> None:
        native = copy.deepcopy(self.native)
        native[1].update({
            "owner": "fcm-messaging-delegate", "kind": "framework-callback",
            "callback": "fcm.registration-token-refreshed", "phase": "entry",
            "payload_summary": {
                "flags": {"has_fcm_token": True},
                "counts": {"fcm_token_characters": 152}, "enums": {},
            },
        })
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "fcm.registration-token-refreshed requires manifest framework firebase-ios-sdk-messaging",
        )

    def test_token_registration_requires_end_to_end_provider_chain(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "token-registration"
        manifest["streams"] = [manifest["streams"][0]]
        manifest["aggregate_assertions"] = []
        stream_id = manifest["streams"][0]["stream_id"]
        application = {
            "callback": "application.did-register-for-remote-notifications", "phase": "entry",
        }
        fcm = {"callback": "fcm.registration-token-refreshed", "phase": "entry"}
        customerio = {"callback": "customerio.register-device-token", "phase": "result"}

        manifest["provider_provenance"]["provider"] = "apn"
        _validate_scenario_acceptance(
            manifest, {stream_id: [application, customerio]}
        )
        with self.assertRaisesRegex(ContractError, "application.did-register.*observed 0"):
            _validate_scenario_acceptance(manifest, {stream_id: [customerio]})
        customerio_intent = {
            "callback": "customerio.register-device-token", "phase": "intent",
        }
        with self.assertRaisesRegex(ContractError, "phase=result seat, observed 0"):
            _validate_scenario_acceptance(
                manifest, {stream_id: [application, customerio_intent]}
            )
        _validate_scenario_acceptance(
            manifest, {stream_id: [application, customerio_intent, customerio]}
        )

        manifest["provider_provenance"]["provider"] = "fcm"
        _validate_scenario_acceptance(
            manifest, {stream_id: [application, fcm, customerio]}
        )
        for missing, records in (
            ("application.did-register", [fcm, customerio]),
            ("fcm.registration-token-refreshed", [application, customerio]),
            ("customerio.register-device-token phase=result seat", [application, fcm]),
        ):
            with self.subTest(missing=missing), self.assertRaisesRegex(
                ContractError, f"{missing}.*observed 0"
            ):
                _validate_scenario_acceptance(manifest, {stream_id: records})

    def test_named_delegate_peer_requires_exact_manifest_framework(self) -> None:
        for delegate_peer in ("expo-notifications", "react-native-push-notification"):
            with self.subTest(delegate_peer=delegate_peer):
                native = copy.deepcopy(self.native)
                native[1]["payload_summary"]["enums"]["delegate_peer"] = delegate_peer
                self.validate_temp(
                    self.manifest, [native, self.wrapper],
                    f"delegate_peer={delegate_peer} requires manifest framework",
                )

        manifest = copy.deepcopy(self.manifest)
        native = copy.deepcopy(self.native)
        native[1]["payload_summary"]["enums"]["delegate_peer"] = "customerio-messaging-push"
        manifest["frameworks"].append({
            "name": "customerio-messaging-push", "role": "sdk", "version": "3.13.1",
            "commit_sha": manifest["repositories"][0]["commit_sha"],
        })
        self.validate_temp(manifest, [native, self.wrapper])
        manifest["frameworks"][-1]["commit_sha"] = "3333333333333333333333333333333333333333"
        self.validate_temp(
            manifest, [native, self.wrapper], "commit mismatch for customerio-messaging-push"
        )

    def test_unaccounted_sequence_gap_is_invalid(self) -> None:
        native = copy.deepcopy(self.native)
        native[-1]["sequence"] = 6
        self.manifest["streams"][0]["receipt"]["last_assigned_sequence"] = 6
        self.manifest["streams"][0]["receipt"]["last_emitted_sequence"] = 6
        self.validate_temp(self.manifest, [native, self.wrapper], "sequence gap 1 is not accounted")

    def test_diagnostic_drop_can_account_for_missing_alias_ordinal(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        for record in records:
            record["recorder"]["buffer_capacity"] = 2
        for index in range(1, len(records)):
            records[index]["sequence"] += 1
            records[index]["recorder"]["dropped_records_total"] = 1
            records[index]["recorder"]["alias_counts"]["delivery"] = 2
            records[index]["recorder"]["buffer_high_watermark"] = 2
        records[2]["completion"]["parent_sequence"] = 3
        records[1]["correlation"]["delivery"] = "delivery-2"
        sync_receipt(manifest, 0, records)
        self.validate_temp(manifest, [records])

    def test_checked_diagnostic_drop_vectors(self) -> None:
        diagnostic_records = load_records("completion.valid-diagnostic-drop.ndjson")
        self.assertEqual(diagnostic_records[1]["correlation"]["delivery"], "delivery-2")
        self.assertEqual(diagnostic_records[2]["correlation"]["delivery"], "delivery-1")
        validate_capture(
            VECTORS / "manifest.diagnostic-drop-valid.json",
            [VECTORS / "completion.valid-diagnostic-drop.ndjson"],
            HERE,
        )
        with self.assertRaisesRegex(ContractError, "high-water to reach capacity"):
            validate_capture(
                VECTORS / "manifest.diagnostic-drop-valid.json",
                [VECTORS / "completion.invalid-drop-without-full-buffer.ndjson"],
                HERE,
            )

        impossible_manifest = _load_json(VECTORS / "manifest.diagnostic-drop-valid.json")
        impossible_records = load_records("completion.valid-diagnostic-drop.ndjson")
        for record in impossible_records:
            record["recorder"]["buffer_capacity"] = 3
            if record["sequence"] > 1:
                record["recorder"]["buffer_high_watermark"] = 3
        sync_receipt(impossible_manifest, 0, impossible_records)
        self.validate_temp(
            impossible_manifest, [impossible_records],
            r"drop-oldest accounting requires at least capacity \+ cumulative drops",
        )

        l2_manifest = _load_json(VECTORS / "manifest.valid.json")
        l2_native = load_records("native.valid.ndjson")
        l2_wrapper = load_records("wrapper.valid.ndjson")
        for record in l2_native[1:]:
            record["recorder"]["buffer_high_watermark"] = 6
        sync_receipt(l2_manifest, 0, l2_native)
        self.validate_temp(
            l2_manifest, [l2_native, l2_wrapper],
            "buffer high-water exceeds assigned sequence volume",
        )

    def test_missing_aliases_must_fit_drop_uncertainty(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        for record in records:
            record["recorder"]["buffer_capacity"] = 2
        for index in range(1, len(records)):
            records[index]["sequence"] += 1
            records[index]["recorder"]["dropped_records_total"] = 1
            records[index]["recorder"]["alias_counts"]["delivery"] = 3
            records[index]["recorder"]["buffer_high_watermark"] = 2
        records[2]["completion"]["parent_sequence"] = 3
        records[1]["correlation"]["delivery"] = "delivery-3"
        sync_receipt(manifest, 0, records)
        self.validate_temp(manifest, [records], "missing delivery aliases exceed .*dropped-record uncertainty")

    def test_overflow_claim_requires_namespace_at_capacity(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        records[1]["recorder"]["alias_overflow"] = True
        records[1]["recorder"]["alias_overflow_namespaces"] = ["delivery"]
        self.validate_temp(manifest, [records], "false delivery overflow below capacity")

    def test_closure_alias_is_forbidden_on_runtime_record(self) -> None:
        native = copy.deepcopy(self.native)
        native[1]["correlation"] = {"closure": "closure-1"}
        for record in native[1:]:
            record["recorder"]["alias_counts"]["closure"] = 1
        self.manifest["streams"][0]["receipt"]["alias_counts"]["closure"] = 1
        self.validate_temp(self.manifest, [native, self.wrapper], "closure aliases are fixture-only")

    def test_completion_nested_owner_is_fixture_only(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        records[2]["completion"]["owner"] = "sdk"
        self.validate_temp(manifest, [records], "schema violation at completion")

    def test_completion_creation_requires_closure_and_nonempty_outcome_series(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        records[1]["correlation"] = None
        self.validate_temp(manifest, [records], "schema violation at correlation")

        records = load_records("completion.valid-zero-call.ndjson")
        records = [records[0], records[1], records[-1]]
        records[-1]["sequence"] = 3
        sync_receipt(manifest, 0, records)
        self.validate_temp(
            manifest, [records], "every completion creation needs exactly one nonempty outcome series"
        )

    def test_negative_completion_requires_drop_free_observation_window(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        for record in records:
            record["recorder"]["buffer_capacity"] = 2
        for record in records[2:]:
            record["sequence"] += 1
            record["recorder"]["dropped_records_total"] = 1
            record["recorder"]["buffer_high_watermark"] = 2
        sync_receipt(manifest, 0, records)
        self.validate_temp(
            manifest, [records],
            "negative completion closure-1 requires zero drops from closure creation through final closeout",
        )

    def test_completion_parent_must_be_exact_fixture_control(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        records[2]["completion"]["parent_sequence"] = 1
        self.validate_temp(manifest, [records], "exact fixture-control seat")

    def test_completion_parent_is_stable_for_invocation_series(self) -> None:
        manifest = _load_json(VECTORS / "manifest.completion-valid.json")
        records = load_records("completion.valid-zero-call.ndjson")
        records[2]["completion"].update({
            "result": "invoked", "observed_call_count": 1, "call_index": 1,
        })
        second_parent = copy.deepcopy(records[1])
        second_parent.update({
            "sequence": 4, "monotonic_ms": 3003,
            "captured_at": "2026-08-11T17:00:02.500Z",
        })
        second_outcome = copy.deepcopy(records[2])
        second_outcome.update({
            "sequence": 5, "monotonic_ms": 3004,
            "captured_at": "2026-08-11T17:00:02.750Z",
        })
        second_outcome["completion"].update({
            "parent_sequence": 4, "observed_call_count": 2, "call_index": 2,
        })
        records[-1].update({
            "sequence": 6, "monotonic_ms": 3005,
            "captured_at": "2026-08-11T17:00:03Z",
        })
        records[3:3] = [second_parent, second_outcome]
        sync_receipt(manifest, 0, records)
        self.validate_temp(manifest, [records], "multiple creation records")

    def test_forwarding_and_passive_seats_have_exact_owners(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "integration": "expo", "runtime": "swift", "kind": "framework-callback",
            "owner": "expo-framework", "callback": "expo.app-delegate-did-finish-launching-forwarded",
            "phase": "entry", "payload_summary": {"flags": {}, "counts": {}, "enums": {}},
        })
        _validate_callback_rule(record)

    def test_cold_start_pull_is_result_not_callback_delivery(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "integration": "expo", "runtime": "swift", "kind": "framework-callback",
            "owner": "expo-framework", "callback": "expo.last-notification-response-pulled",
            "phase": "result", "scenario": "push-tap-cold", "payload_summary": {
                "flags": {"has_notification": True, "has_notification_response": True},
                "counts": {},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "expo-notifications", "app_state": "active",
                    "action_class": "default",
                },
            },
        })
        _validate_callback_rule(record)
        _validate_payload(record)
        record.update({
            "callback": "expo.notification-center-manager.did-receive-response-forwarded",
            "owner": "expo-notifications",
        })
        with self.assertRaisesRegex(ContractError, "incompatible phase=result"):
            _validate_callback_rule(record)
        record.update({
            "kind": "observer-notification", "owner": "rct-notification",
            "callback": "rct.instance-did-load-bundle-notification", "phase": "state-change",
        })
        _validate_callback_rule(record)

    def test_host_presentation_and_background_fetch_are_result_only(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "kind": "host-routing", "owner": "host", "callback": "host.present-notification",
            "phase": "intent",
        })
        with self.assertRaisesRegex(ContractError, "incompatible phase=intent"):
            _validate_callback_rule(record)
        record["callback"] = "host.background-fetch-completion-result"
        with self.assertRaisesRegex(ContractError, "incompatible phase=intent"):
            _validate_callback_rule(record)
        record["phase"] = "result"
        record["payload_summary"] = {"flags": {}, "counts": {}, "enums": {}}
        with self.assertRaisesRegex(ContractError, "background-fetch completion result"):
            _validate_payload(record)
        record.update({
            "callback": "host.present-notification",
            "payload_summary": {
                "flags": {"has_notification": True}, "counts": {},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "host",
                },
            },
        })
        with self.assertRaisesRegex(ContractError, "presentation_alert"):
            _validate_payload(record)

    def test_presentation_class_matches_exact_flags_and_count(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "push-foreground", "kind": "host-routing", "owner": "host",
            "callback": "host.present-notification", "phase": "result",
            "payload_summary": {
                "flags": {
                    "has_notification": True, "presentation_alert": False,
                    "presentation_badge": False, "presentation_sound": False,
                    "presentation_banner": False, "presentation_list": False,
                },
                "counts": {"presentation_options": 0},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "host", "presentation_class": "suppressed",
                },
            },
        })
        _validate_payload(record, "17.0")
        record["payload_summary"]["enums"]["presentation_class"] = "visible"
        with self.assertRaisesRegex(ContractError, "presentation_class must match"):
            _validate_payload(record, "17.0")
        record["payload_summary"]["flags"]["presentation_alert"] = True
        record["payload_summary"]["counts"]["presentation_options"] = 1
        _validate_payload(record, "17.0")

    def test_cold_scene_connection_options_require_scenario_safe_facts(self) -> None:
        base = copy.deepcopy(self.native[1])
        base.update({
            "owner": "scene-delegate", "callback": "scene.will-connect", "phase": "entry",
            "payload_summary": {
                "flags": {"has_scene": True}, "counts": {},
                "enums": {
                    "scene_state": "unattached", "scene_role": "application",
                    "app_state": "inactive",
                },
            },
        })
        cases = (
            (
                "custom-url-cold", "has_url",
                {
                    "flags": {"has_url": True},
                    "counts": {"url_path_components": 1, "url_query_items": 0},
                    "enums": {"url_scheme": "custom", "url_class": "custom-scheme"},
                },
            ),
            (
                "universal-link-cold", "has_user_activity",
                {
                    "flags": {"has_user_activity": True},
                    "counts": {"user_activities": 1},
                    "enums": {"activity_class": "web-browsing"},
                },
            ),
            (
                "quick-action-cold", "has_shortcut",
                {
                    "flags": {"has_shortcut": True}, "counts": {},
                    "enums": {"action_class": "default"},
                },
            ),
        )
        for scenario, missing_fact, additions in cases:
            with self.subTest(scenario=scenario):
                record = copy.deepcopy(base)
                record["scenario"] = scenario
                with self.assertRaisesRegex(ContractError, missing_fact):
                    _validate_payload(record, "17.0")
                for section in ("flags", "counts", "enums"):
                    record["payload_summary"][section].update(additions[section])
                _validate_payload(record, "17.0")

    def test_cold_scene_connection_options_are_defining_handoff_seats(self) -> None:
        cases = (
            (
                "custom-url-cold", "wrapper.app-received-url",
                {
                    "flags": {"has_url": True},
                    "counts": {"url_path_components": 1, "url_query_items": 0},
                    "enums": {"url_scheme": "custom", "url_class": "custom-scheme"},
                },
            ),
            (
                "universal-link-cold", "wrapper.app-received-user-activity",
                {
                    "flags": {"has_user_activity": True},
                    "counts": {"user_activities": 1},
                    "enums": {"activity_class": "web-browsing"},
                },
            ),
            (
                "quick-action-cold", "wrapper.app-received-quick-action",
                {
                    "flags": {"has_shortcut": True}, "counts": {},
                    "enums": {"action_class": "default"},
                },
            ),
        )
        for scenario, wrapper_callback, payload in cases:
            with self.subTest(scenario=scenario):
                manifest = copy.deepcopy(self.manifest)
                manifest["scenario"] = scenario
                native_id = manifest["streams"][0]["stream_id"]
                wrapper_id = manifest["streams"][1]["stream_id"]
                manifest["aggregate_assertions"] = [{
                    "name": "connection-options-handoff",
                    "relation": "equal-exact-count", "expected_count": 1,
                    "members": [
                        {"stream_id": native_id, "callback": "scene.will-connect", "phase": "entry"},
                        {"stream_id": wrapper_id, "callback": wrapper_callback, "phase": "entry"},
                    ],
                }]
                _validate_scenario_acceptance(
                    manifest,
                    {
                        native_id: [
                            {
                                "callback": "scene.will-connect", "phase": "entry",
                                "payload_summary": copy.deepcopy(payload),
                            },
                            {
                                "callback": "application.did-finish-launching", "phase": "entry",
                                "payload_summary": {"flags": {}, "counts": {}, "enums": {}},
                            },
                        ],
                        wrapper_id: [{
                            "callback": wrapper_callback, "phase": "entry",
                            "payload_summary": copy.deepcopy(payload),
                        }],
                    },
                )

    def test_swiftui_open_url_is_available_universal_link_seat_from_ios14(self) -> None:
        payload = {
            "flags": {"has_url": True},
            "counts": {"url_path_components": 1, "url_query_items": 0},
            "enums": {"url_scheme": "https", "url_class": "web"},
        }
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "universal-link-warm", "owner": "swiftui-scene",
            "callback": "swiftui.on-open-url", "phase": "entry",
            "payload_summary": copy.deepcopy(payload),
        })
        _validate_payload(record, "14.0")
        with self.assertRaisesRegex(ContractError, "requires iOS 14 or newer"):
            _validate_payload(record, "13.7")
        record["payload_summary"]["enums"].update({
            "url_scheme": "custom", "url_class": "custom-scheme",
        })
        with self.assertRaisesRegex(ContractError, "Universal Link URL seat requires"):
            _validate_payload(record, "14.0")

        manifest = copy.deepcopy(self.manifest)
        manifest["scenario"] = "universal-link-warm"
        native_id = manifest["streams"][0]["stream_id"]
        wrapper_id = manifest["streams"][1]["stream_id"]
        manifest["aggregate_assertions"] = [{
            "name": "swiftui-universal-link", "relation": "equal-exact-count",
            "expected_count": 1,
            "members": [
                {"stream_id": native_id, "callback": "swiftui.on-open-url", "phase": "entry"},
                {"stream_id": wrapper_id, "callback": "wrapper.app-received-url", "phase": "entry"},
            ],
        }]
        _validate_scenario_acceptance(
            manifest,
            {
                native_id: [{
                    "callback": "swiftui.on-open-url", "phase": "entry",
                    "payload_summary": copy.deepcopy(payload),
                }],
                wrapper_id: [{
                    "callback": "wrapper.app-received-url", "phase": "entry",
                    "payload_summary": copy.deepcopy(payload),
                }],
            },
        )

    def test_notification_response_and_presentation_facts_match_callback_seat(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "push-foreground", "callback": "notification-center.will-present",
            "payload_summary": {
                "flags": {"has_notification": True, "has_notification_response": True},
                "counts": {},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "host",
                },
            },
        })
        with self.assertRaisesRegex(ContractError, "is not a notification-response seat"):
            _validate_payload(record)

        record = copy.deepcopy(self.native[1])
        record["payload_summary"]["flags"]["presentation_banner"] = True
        with self.assertRaisesRegex(ContractError, "iOS 13 requires presentation_banner/list=false"):
            _validate_payload(record, "13.7")
        record["payload_summary"]["flags"]["presentation_banner"] = False
        with self.assertRaisesRegex(ContractError, "presentation facts are valid only"):
            _validate_payload(record, "17.0")

    def test_customerio_device_registration_uses_provider_specific_token_facts(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "provider": "fcm", "callback": "customerio.register-device-token",
            "payload_summary": {
                "flags": {"has_fcm_token": True},
                "counts": {"fcm_token_characters": 152}, "enums": {},
            },
        })
        _validate_payload(record)
        record["payload_summary"] = {
            "flags": {"has_device_token": True},
            "counts": {"device_token_bytes": 32}, "enums": {},
        }
        with self.assertRaisesRegex(ContractError, "requires .*has_fcm_token"):
            _validate_payload(record)

    def test_ios13_presentation_cannot_claim_banner_or_list(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "kind": "host-routing", "owner": "host", "callback": "host.present-notification",
            "phase": "result", "payload_summary": {
                "flags": {
                    "has_notification": True, "presentation_alert": False,
                    "presentation_badge": False, "presentation_sound": False,
                    "presentation_banner": True, "presentation_list": False,
                },
                "counts": {"presentation_options": 1},
                "enums": {
                    "notification_origin": "remote", "notification_class": "customerio",
                    "delegate_peer": "host",
                },
            },
        })
        with self.assertRaisesRegex(ContractError, "iOS 13 requires presentation_banner/list=false"):
            _validate_payload(record, "13.7")

    def test_payload_presence_values_are_logically_consistent(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "custom-url-warm", "callback": "customerio.route-deep-link",
            "payload_summary": {
                "flags": {"has_url": True},
                "counts": {"url_path_components": 1, "url_query_items": 0},
                "enums": {"url_scheme": "none", "url_class": "none"},
            },
        })
        with self.assertRaisesRegex(ContractError, "URL presence cannot use"):
            _validate_payload(record)

        record["payload_summary"]["enums"].update({
            "url_scheme": "https", "url_class": "web",
        })
        with self.assertRaisesRegex(ContractError, "custom URL scenario requires"):
            _validate_payload(record)

        record = copy.deepcopy(self.native[1])
        record["payload_summary"]["enums"]["notification_origin"] = "none"
        with self.assertRaisesRegex(ContractError, "notification presence cannot use"):
            _validate_payload(record)

    def test_framework_other_delegate_peer_is_diagnostic_only(self) -> None:
        wrapper = copy.deepcopy(self.wrapper)
        wrapper[1]["payload_summary"]["enums"]["delegate_peer"] = "framework-other"
        self.validate_temp(
            self.manifest, [self.native, wrapper], "requires an attested named delegate peer"
        )

    def test_customerio_deep_link_requires_full_url_facts(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "scenario": "custom-url-warm", "callback": "customerio.route-deep-link",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {}},
        })
        with self.assertRaisesRegex(ContractError, "has_url"):
            _validate_payload(record)

    def test_url_token_state_and_notification_payloads_are_required(self) -> None:
        record = copy.deepcopy(self.native[1])
        record.update({
            "callback": "application.open-url", "owner": "application-delegate",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {}},
        })
        with self.assertRaisesRegex(ContractError, "has_url"):
            _validate_payload(record)
        record["callback"] = "application.did-register-for-remote-notifications"
        with self.assertRaisesRegex(ContractError, "has_device_token"):
            _validate_payload(record)
        record.update({"callback": "application.did-become-active", "phase": "state-change"})
        with self.assertRaisesRegex(ContractError, "app_state"):
            _validate_payload(record)
        record.update({
            "callback": "scene.will-connect", "phase": "entry",
            "payload_summary": {"flags": {}, "counts": {}, "enums": {"app_state": "inactive"}},
        })
        with self.assertRaisesRegex(ContractError, "has_scene"):
            _validate_payload(record)
        record.update({
            "callback": "notification-center.did-receive-response", "phase": "entry",
            "payload_summary": {"flags": {"has_notification": True, "has_notification_response": True}, "counts": {}, "enums": {
                "notification_origin": "unknown", "notification_class": "unknown", "delegate_peer": "unknown"
            }},
        })
        with self.assertRaisesRegex(ContractError, "requires an attested named delegate peer"):
            _validate_payload(record)

    def test_rfc3339_format_is_asserted(self) -> None:
        native = copy.deepcopy(self.native)
        native[0]["captured_at"] = "2026-08-11T16:00:00"
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "schema violation at captured_at: .* is not a 'date-time'",
        )

        for value in ("2026-08-11", "2026-08-11T16:00:00"):
            with self.subTest(value=value), self.assertRaisesRegex(
                ContractError, "expected RFC3339 date-time with timezone"
            ):
                _parse_time(value, "probe")

    def test_schema_and_parser_share_canonical_uppercase_rfc3339(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        manifest["created_at"] = "2026-08-11t16:00:11z"
        self.validate_temp(
            manifest, [self.native, self.wrapper],
            "schema violation at created_at: .* does not match",
        )

        native = copy.deepcopy(self.native)
        native[0]["captured_at"] = "2026-08-11t16:00:00z"
        self.validate_temp(
            self.manifest, [native, self.wrapper],
            "schema violation at captured_at: .* does not match",
        )
        with self.assertRaisesRegex(ContractError, "expected RFC3339 date-time with timezone"):
            _parse_time("2026-08-11t16:00:00z", "probe")

    def test_cli_invalid_timestamp_returns_contract_error_without_traceback(self) -> None:
        native = copy.deepcopy(self.native)
        native[0]["captured_at"] = "2026-08-11T16:00:00"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest_path = root / "manifest.json"
            native_path = root / "native.ndjson"
            wrapper_path = root / "wrapper.ndjson"
            manifest_path.write_text(json.dumps(self.manifest), encoding="utf-8")
            for path, records in ((native_path, native), (wrapper_path, self.wrapper)):
                path.write_text(
                    "\n".join(
                        PREFIX + json.dumps(record, separators=(",", ":")) for record in records
                    ) + "\n",
                    encoding="utf-8",
                )
            result = subprocess.run(
                [
                    sys.executable, str(HERE / "validate_ios27_lifecycle_trace.py"),
                    str(manifest_path), str(native_path), str(wrapper_path),
                    "--schema-dir", str(HERE),
                ],
                check=False, capture_output=True, text=True,
            )
        self.assertEqual(result.returncode, 1)
        self.assertIn("INVALID:", result.stderr)
        self.assertIn("schema violation at captured_at", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertNotIn("TypeError", result.stderr)

    def test_duplicate_or_midstream_trace_markers_are_invalid(self) -> None:
        for marker_name in ("trace.scenario-start", "trace.scenario-end"):
            with self.subTest(marker=marker_name):
                manifest = copy.deepcopy(self.manifest)
                records = copy.deepcopy(self.native)
                marker = copy.deepcopy(records[0] if marker_name.endswith("start") else records[-1])
                marker.update({
                    "sequence": 3, "monotonic_ms": 1002,
                    "captured_at": "2026-08-11T16:00:03.500Z",
                })
                records[-1].update({
                    "sequence": 4, "monotonic_ms": 1003,
                    "captured_at": "2026-08-11T16:00:04Z",
                })
                records.insert(2, marker)
                self.make_native_single(manifest, records)
                sync_receipt(manifest, 0, records)
                self.validate_temp(
                    manifest, [records], "exactly one leading scenario-start and one final scenario-end"
                )


if __name__ == "__main__":
    unittest.main()
