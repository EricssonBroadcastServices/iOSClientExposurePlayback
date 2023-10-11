## Playback Analytics for Downloaded Assets

The SDK will automatically store analytics for offline playback in local storage and flush them periodically if the device has connected to an internet connection.

Optionally, client developers can implement offline playback analytics to be flushed as a background event. The SDK will check if there are any locally stored events, and if found, will send them to the analytics server.

To configure your app to allow background tasks, enable the background capabilities that you need, and then create a list of unique identifiers for each task.

### Configure Background Processing

1. Add the capability: **Background processing**
2. Add the **BGTaskSchedulerPermittedIdentifier** key as **com.emp.ExposurePlayback.SampleApp.analyticsFlush** to the Info.plist

Read more about background processing in Apple's documentation: [Using background tasks to update your app](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background/using_background_tasks_to_update_your_app)

Check SDK Sample application for sample implementation [SDK Sample App](https://github.com/EricssonBroadcastServices/iOSClientSDKSampleApp)

```swift
class AppDelegate: {

    let appRefreshTaskId = "com.emp.ExposurePlayback.SampleApp.analyticsFlush"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: self.appRefreshTaskId, using: nil) { task in
            self.handleFlusingOfflineAnalytics(task: task as! BGProcessingTask)      
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.scheduleAppRefresh(minutes: 2)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.cancelAllPendingBGTask()
    }

    func cancelAllPendingBGTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }

    func scheduleAppRefresh(minutes: Int) {
        let seconds = TimeInterval(minutes * 60)
        let request = BGProcessingTaskRequest(identifier: self.appRefreshTaskId )
        request.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        request.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh task \(error.localizedDescription)")
        }
    }

    func handleFlushingOfflineAnalytics(task: BGProcessingTask) {
        // Schedule a new refresh task: Define the minutes
        scheduleAppRefresh(minutes: 2)

        let manager = iOSClientExposure.BackgroundAnalyticsManager()
        manager.flushOfflineAnalytics()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            self.cancelAllPendingBGTask()
        }
    }
}

