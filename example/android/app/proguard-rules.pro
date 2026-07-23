# Tink (via androidx.security:security-crypto, pulled in by the Bearound
# Telemetry SDK) references javax.annotation compile-time annotations that are
# not present at runtime. Safe to ignore.
-dontwarn javax.annotation.**
