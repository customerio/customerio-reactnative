#  `UserNotifications` Framework

The `UserNotifications` framework is an iOS framework that displays push notifications and handles when they are interacted with (such as clicking on them). 

Our SDK's push notification features are dependent on this framework to function. 

# Automated tests 

In order for us to write automated tests around our SDK's push features, we need to de-couple our SDK's code away from the `UserNotifications` framework. This is for 2 reasons: 
1. Some data types in the `UserNotifications` framework cannot be constructed. The constructors are not public. 
2. If you try to run tests for a Swift package such as this SDK, you will receive exceptions from the test runner because `UserNotifications` framework is not available without running the tests inside of a host iOS app. 

For these reasons, we have to take a different approach to test our SDK's code. Our approach is to treat the `UserNotifications` framework as a dependency, de-couple our code away from it, and mock it in our tests. 

This directory in our SDK's code is the code that connects our SDK's code to the iOS `UserNotifications` framework. The code in this directory is only executed in production, not in our automated tests. Code that interacts with the `UserNotifications` framework should be kept in this directory, abstracted away from the SDK. 
