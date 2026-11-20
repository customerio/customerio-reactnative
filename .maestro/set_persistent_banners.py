#!/usr/bin/env python3
# The BBSectionInfo record below is adapted from set_notification_permission.py in
# https://github.com/imranbarbhuiya/ios-sim-notification-permission
# under its MIT License:
#
# Copyright (c) 2026 imranbarbhuiya
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
"""Writes a simulator notification record that makes an app's banners persistent.

    set_persistent_banners.py <VersionedSectionInfo.plist> <bundle-id> <display-name>
    set_persistent_banners.py --check <VersionedSectionInfo.plist> <bundle-id>

iOS removes a temporary banner about six seconds after it appears, so a test tap that
lands later finds the Home screen instead. A persistent banner stays until it is tapped.
iOS keeps the setting in data/Library/BulletinBoard/VersionedSectionInfo.plist as one
NSKeyedArchiver-encoded BBSectionInfo per bundle id. This writes the record iOS 27.2
saves after a user allows notifications, with alertType 2 (Alert, which Settings shows
as the Persistent banner style) instead of 1 (Banner, the Temporary style).

SpringBoard rewrites the file from memory as it stops, so run_scene_push.sh stops it and
usernotificationsd before the write and starts them after. --check decodes the saved
record and fails unless it is still authorized with the persistent style, so a run shows
whether SpringBoard kept it. --check reads the file on disk, not SpringBoard's memory: an
iOS release that ignores alertType would still pass it and bring the late-tap failure
back. The live signal is `alertStyle: Alert` for the app in the simulator's device log.
"""

import os
import plistlib
import sys
import time
from plistlib import UID

AUTHORIZED = 2
PERSISTENT_ALERT_TYPE = 2
# Seconds between the Cocoa reference date (2001-01-01) and the Unix epoch.
COCOA_EPOCH = 978307200


def section_info(bundle_id: str, name: str) -> bytes:
    settings = {
        "$class": UID(4),
        "authorizationStatus": AUTHORIZED,
        "authorizationExpirationDate": UID(0),
        "lastUserGrantedAuthorizationDate": UID(0),
        "alertType": PERSISTENT_ALERT_TYPE,
        "pushSettings": 63,
        "showsInNotificationCenter": True,
        "showsInLockScreen": True,
        "showsOnExternalDevices": True,
        "notificationCenterSetting": 2,
        "lockScreenSetting": 2,
        "remoteNotificationsSetting": 2,
        "carPlaySetting": 0,
        "criticalAlertSetting": 0,
        "timeSensitiveSetting": 0,
        "userConfiguredTimeSensitiveSetting": False,
        "directMessagesSettingKey": 0,
        "userConfiguredDirectMessagesSetting": False,
        "announceSetting": 1,
        "announcePriority": 0,
        "bulletinGroupingSetting": 0,
        "contentPreviewSetting": 0,
        "prioritizationSetting": 2,
        "summarizationSetting": 2,
        "scheduledDeliverySetting": 1,
        "showsCustomSettingsLink": False,
        "muteAssertion": UID(0),
    }
    info = {
        "$class": UID(10),
        "sectionID": UID(2),
        "sectionInfoSettings": UID(3),
        "lastSettingChangeDate": UID(5),
        "appName": UID(7),
        "displayName": UID(8),
        "version": UID(9),
        "lastSettingSource": 2,
        "sectionType": 0,
        "sectionCategory": 0,
        "subsectionPriority": 0,
        "suppressFromSettings": False,
        "suppressedSettings": 0,
        "isRestricted": False,
        "isModificationAllowed": False,
        "hasEverBeenUserChanged": False,
        "isAppClip": False,
        "isLocked": False,
        "hideWeeApp": False,
        "customSettingsBundle": UID(0),
        "customSettingsDetailControllerClass": UID(0),
        "icon": UID(0),
        "subsections": UID(0),
        "subsectionID": UID(0),
        "managedSectionInfoSettings": UID(0),
        "factorySectionID": UID(0),
        "dataProviderIDs": UID(0),
        "pathToWeeAppPluginBundle": UID(0),
    }
    objects = [
        "$null",
        info,
        bundle_id,
        settings,
        {"$classname": "BBSectionInfoSettings", "$classes": ["BBSectionInfoSettings", "NSObject"]},
        {"NS.time": time.time() - COCOA_EPOCH, "$class": UID(6)},
        {"$classname": "NSDate", "$classes": ["NSDate", "NSObject"]},
        name,
        name,
        0,
        {"$classname": "BBSectionInfo", "$classes": ["BBSectionInfo", "NSObject"]},
    ]
    archive = {
        "$version": 100000,
        "$archiver": "NSKeyedArchiver",
        "$top": {"root": UID(1)},
        "$objects": objects,
    }
    return plistlib.dumps(archive, fmt=plistlib.FMT_BINARY)


def check(sections: dict, bundle_id: str) -> int:
    record = sections.get(bundle_id)
    if not isinstance(record, bytes):
        print(f"error: no notification record for {bundle_id}", file=sys.stderr)
        return 1
    archive = plistlib.loads(record)
    objects = archive["$objects"]
    info = objects[archive["$top"]["root"]]
    settings = objects[info["sectionInfoSettings"]]
    alert_type = settings.get("alertType")
    status = settings.get("authorizationStatus")
    print(f"{bundle_id} notification record: alertType={alert_type} authorizationStatus={status}")
    if alert_type != PERSISTENT_ALERT_TYPE or status != AUTHORIZED:
        print("error: notification banners are not persistent; a late banner tap would miss", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    args = sys.argv[1:]
    checking = args[:1] == ["--check"]
    if len(args) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    if checking:
        args = args[1:]
    path, bundle_id = args[0], args[1]
    with open(path, "rb") as handle:
        store = plistlib.load(handle)
    sections = store.get("sectionInfo")
    if not isinstance(sections, dict):
        print(f"error: {path} has no sectionInfo dictionary", file=sys.stderr)
        return 1
    if checking:
        return check(sections, bundle_id)
    sections[bundle_id] = section_info(bundle_id, args[2])
    with open(path + ".tmp", "wb") as handle:
        plistlib.dump(store, handle, fmt=plistlib.FMT_BINARY)
    os.replace(path + ".tmp", path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
