#!/bin/sh
# Print the path of a JDK that can build Traccar (Java 21 or newer).
# Used by the Makefile so that `make` targets work even when the default
# `java` on PATH is older. Exits with status 1 when no suitable JDK is found.

MIN=21

major() {
    "$1/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -n 1
}

ok() {
    [ -n "$1" ] && [ -x "$1/bin/java" ] && v=$(major "$1") && [ -n "$v" ] && [ "$v" -ge "$MIN" ]
}

# 1. JAVA_HOME, if already set and recent enough.
if ok "$JAVA_HOME"; then echo "$JAVA_HOME"; exit 0; fi

# 2. The java on PATH.
if command -v java >/dev/null 2>&1; then
    home=$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^ *java.home = //p')
    if ok "$home"; then echo "$home"; exit 0; fi
fi

# 3. macOS registered JDKs.
if [ -x /usr/libexec/java_home ]; then
    home=$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home -v "$MIN+" 2>/dev/null)
    if ok "$home"; then echo "$home"; exit 0; fi
fi

# 4. Common install locations (Homebrew, SDKMAN, Linux packages). Java 21 first, like CI.
for home in \
    /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    "$HOME"/.sdkman/candidates/java/21* \
    /usr/lib/jvm/*21* \
    /opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home \
    /opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home \
    "$HOME"/.sdkman/candidates/java/* \
    /usr/lib/jvm/*; do
    if ok "$home"; then echo "$home"; exit 0; fi
done

echo "No JDK $MIN or newer found. Install Temurin 21 (see .java-version) or set JAVA_HOME." >&2
exit 1
