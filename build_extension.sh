#!/usr/bin/env bash
# Maven-free build of the GhidraMCP Ghidra extension.
#
# Produces target/GhidraMCP-<ghidraVersion>.zip, installable via
# Ghidra > File > Install Extensions. Mirrors what `mvn package assembly:single`
# does, but needs only a JDK + the Ghidra install (no Maven). The extension
# version is stamped to your local Ghidra version so it loads without a
# compatibility warning.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"
: "${GHIDRA_INSTALL_DIR:?set GHIDRA_INSTALL_DIR to your Ghidra install directory}"

GV=$(grep -h '^application.version' "$GHIDRA_INSTALL_DIR"/Ghidra/application.properties | cut -d= -f2)
echo "Building GhidraMCP for Ghidra $GV"

CP=$(find "$GHIDRA_INSTALL_DIR" -name '*.jar' | tr '\n' ':')
rm -rf target/classes target/stage target/GhidraMCP.jar
mkdir -p target/classes

javac -proc:none -cp "$CP" -d target/classes \
    src/main/java/com/lauriewired/GhidraMCPPlugin.java
jar cf target/GhidraMCP.jar -C target/classes .

# Stage the extension layout: GhidraMCP/{extension.properties, Module.manifest, lib/}
mkdir -p target/stage/GhidraMCP/lib
sed -e "s/^version=.*/version=$GV/" -e "s/^ghidraVersion=.*/ghidraVersion=$GV/" \
    src/main/resources/extension.properties > target/stage/GhidraMCP/extension.properties
cp src/main/resources/Module.manifest target/stage/GhidraMCP/Module.manifest
cp target/GhidraMCP.jar target/stage/GhidraMCP/lib/GhidraMCP.jar

OUT="target/GhidraMCP-$GV.zip"
rm -f "$OUT"
if command -v zip >/dev/null; then
    ( cd target/stage && zip -qr "../GhidraMCP-$GV.zip" GhidraMCP )
else
    ( cd target/stage && python3 -c "import shutil; shutil.make_archive('../GhidraMCP-$GV','zip','.', 'GhidraMCP')" )
fi
echo "built: $HERE/$OUT"
