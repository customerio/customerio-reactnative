import CioInternalCommon
import Foundation

class TrackingModuleHookProvider: ModuleHookProvider {
    private let sdkInitializedUtil = SdkInitializedUtilImpl()

    private var diGraph: DIGraph? {
        sdkInitializedUtil.postInitializedData?.diGraph
    }

    var profileIdentifyHook: ProfileIdentifyHook? {
        nil
    }

    var screenTrackingHook: ScreenTrackingHook? {
        nil
    }
}
