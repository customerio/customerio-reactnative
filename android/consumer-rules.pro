# Location and geofence modules are optional compileOnly dependencies.
# When not enabled, R8 must not fail on their missing classes.
-dontwarn io.customer.location.**
-dontwarn io.customer.geofence.**
