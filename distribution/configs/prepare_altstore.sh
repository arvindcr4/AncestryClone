#!/bin/bash

# prepare_altstore.sh
# Script to prepare AncestryClone for AltStore distribution
# 
# Created on: 2025-04-23

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration
APP_NAME="AncestryClone"
BUNDLE_ID="com.example.AncestryClone"
SCHEME_NAME="AncestryClone"
WORKSPACE_NAME="AncestryClone.xcworkspace"
PROJECT_NAME="AncestryClone.xcodeproj"
VERSION="1.0.0"
BUILD_NUMBER="1"
DEVELOPMENT_TEAM="YOUR_TEAM_ID" # Replace with your actual team ID
OUTPUT_DIR="./altstore_build"
ALTSTORE_MANIFEST="altstore-manifest.json"

# Determine the correct paths based on current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Check if we're in the correct directory structure
if [[ "$(basename "$PROJECT_ROOT")" == "AncestryClone" && -d "../AncestryClone" ]]; then
    # We're likely in a subdirectory of the main project
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
    echo -e "${YELLOW}Detected we're in a subdirectory, using parent as project root${NC}"
fi

# Check for the existence of the project file
if [[ -f "$PROJECT_ROOT/$PROJECT_NAME" ]]; then
    echo -e "Found project at: $PROJECT_ROOT/$PROJECT_NAME"
elif [[ -f "$PROJECT_ROOT/$WORKSPACE_NAME" ]]; then
    echo -e "Found workspace at: $PROJECT_ROOT/$WORKSPACE_NAME"
else
    echo -e "${RED}Error: Could not find project or workspace in $PROJECT_ROOT${NC}"
    echo -e "Please run this script from the project root directory"
    exit 1
fi

# Set path to Info.plist
INFO_PLIST_PATH="$PROJECT_ROOT/Info.plist"

# Try to find Info.plist if it's not in the expected location
if [[ ! -f "$INFO_PLIST_PATH" ]]; then
    echo -e "${YELLOW}Info.plist not found at expected location, searching...${NC}"
    FOUND_PLIST=$(find "$PROJECT_ROOT" -name "Info.plist" -type f | head -1)
    if [[ -n "$FOUND_PLIST" ]]; then
        INFO_PLIST_PATH="$FOUND_PLIST"
        echo -e "Found Info.plist at: $INFO_PLIST_PATH"
    else
        echo -e "${RED}Error: Could not find Info.plist${NC}"
        echo -e "Please ensure Info.plist exists in your project"
        exit 1
    fi
fi

# Set absolute paths for other important files
ENTITLEMENTS_FILE="$PROJECT_ROOT/$APP_NAME.entitlements"
ALTSTORE_MANIFEST_PATH="$PROJECT_ROOT/$ALTSTORE_MANIFEST"
OUTPUT_DIR="$PROJECT_ROOT/$OUTPUT_DIR"

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Preparing AncestryClone for AltStore Distribution ===${NC}"
echo -e "Version: $VERSION ($BUILD_NUMBER)"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if we have a workspace or just a project
if [ -e "$WORKSPACE_NAME" ]; then
    XCODE_PROJECT_PARAM="-workspace $WORKSPACE_NAME"
else
    XCODE_PROJECT_PARAM="-project $PROJECT_NAME"
fi

# Step 1: Update build number and version
echo -e "\n${YELLOW}=== Updating version and build number ===${NC}"
if [[ -f "$INFO_PLIST_PATH" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST_PATH" || 
        /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$INFO_PLIST_PATH"
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFO_PLIST_PATH" || 
        /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$INFO_PLIST_PATH"
    
    echo -e "Updated version and build number in $INFO_PLIST_PATH"
else
    echo -e "${RED}Error: Info.plist not found at $INFO_PLIST_PATH${NC}"
    exit 1
fi

# Step 2: Create entitlements file if it doesn't exist
echo -e "\n${YELLOW}=== Setting up entitlements ===${NC}"

if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo -e "Creating entitlements file..."
    cat > "$ENTITLEMENTS_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.personal-information.photos-library</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array/>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.developer.ubiquity-kvstore-identifier</key>
    <string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.example.AncestryClone</string>
    </array>
</dict>
</plist>
EOF
    echo -e "Entitlements file created at $ENTITLEMENTS_FILE"
else
    echo -e "Entitlements file already exists, checking for required entries..."
    
    # Make sure app groups are properly set
    if ! grep -q "com.apple.security.application-groups" "$ENTITLEMENTS_FILE"; then
        echo -e "${YELLOW}Warning: App groups entitlement not found, adding it...${NC}"
        /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups array" "$ENTITLEMENTS_FILE"
        /usr/libexec/PlistBuddy -c "Add :com.apple.security.application-groups:0 string group.com.example.AncestryClone" "$ENTITLEMENTS_FILE"
    fi
fi

# Step 3: Clean build folder
echo -e "\n${YELLOW}=== Cleaning build folder ===${NC}"
rm -rf "$PROJECT_ROOT/build"
cd "$PROJECT_ROOT"
xcodebuild clean $XCODE_PROJECT_PARAM -scheme "$SCHEME_NAME" -configuration Release || {
    echo -e "${RED}Clean failed. Check if the scheme exists with: xcodebuild -list${NC}"
    xcodebuild -list
    exit 1
}

# Step 4: Archive the application
echo -e "\n${YELLOW}=== Archiving application ===${NC}"
ARCHIVE_PATH="$OUTPUT_DIR/$APP_NAME.xcarchive"
xcodebuild archive $XCODE_PROJECT_PARAM \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_IDENTITY="Apple Development" \
    CODE_SIGN_STYLE="Automatic" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    MARKETING_VERSION="$VERSION" \
    || { echo -e "${RED}Archive failed${NC}"; exit 1; }

# Step 5: Create exportOptions.plist for development distribution
echo -e "\n${YELLOW}=== Creating export options ===${NC}"
EXPORT_OPTIONS_PATH="$OUTPUT_DIR/exportOptions.plist"
cat > "$EXPORT_OPTIONS_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

# Step 6: Export IPA
echo -e "\n${YELLOW}=== Exporting IPA file ===${NC}"
IPA_DIR="$OUTPUT_DIR/ipa"
mkdir -p "$IPA_DIR"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -exportPath "$IPA_DIR" \
    || { echo -e "${RED}Export failed${NC}"; exit 1; }

# Step 7: Copy and update the AltStore manifest
echo -e "\n${YELLOW}=== Updating AltStore manifest ===${NC}"
if [[ -f "$ALTSTORE_MANIFEST_PATH" ]]; then
    cp "$ALTSTORE_MANIFEST_PATH" "$OUTPUT_DIR/"
    echo -e "Copied manifest from $ALTSTORE_MANIFEST_PATH to $OUTPUT_DIR/"
else
    echo -e "${RED}Warning: AltStore manifest not found at $ALTSTORE_MANIFEST_PATH${NC}"
    echo -e "Creating a basic manifest file in the output directory..."
    
    # Create a basic manifest if it doesn't exist
    cat > "$OUTPUT_DIR/$ALTSTORE_MANIFEST" << EOF
{
    "name": "AncestryClone",
    "bundleIdentifier": "$BUNDLE_ID",
    "developerName": "AncestryClone Team",
    "version": "$VERSION",
    "versionDate": "$(date +%Y-%m-%d)",
    "versionDescription": "Initial release",
    "downloadURL": "https://example.com/downloads/AncestryClone.ipa",
    "size": 0,
    "minOSVersion": "15.0"
}
EOF
    echo -e "Created basic manifest at $OUTPUT_DIR/$ALTSTORE_MANIFEST"
fi

# Update the manifest file with the actual IPA file size
IPA_PATH="$IPA_DIR/$APP_NAME.ipa"
IPA_SIZE=$(stat -f%z "$IPA_PATH")
TMP_MANIFEST="$OUTPUT_DIR/tmp_manifest.json"
cat "$OUTPUT_DIR/$ALTSTORE_MANIFEST" | sed "s/\"size\": [0-9]*/\"size\": $IPA_SIZE/" > "$TMP_MANIFEST"
mv "$TMP_MANIFEST" "$OUTPUT_DIR/$ALTSTORE_MANIFEST"

# Update the version in the manifest file
cat "$OUTPUT_DIR/$ALTSTORE_MANIFEST" | sed "s/\"version\": \"[0-9.]*\"/\"version\": \"$VERSION\"/" > "$TMP_MANIFEST"
mv "$TMP_MANIFEST" "$OUTPUT_DIR/$ALTSTORE_MANIFEST"

# Step 8: Validate the IPA for AltStore compatibility
echo -e "\n${YELLOW}=== Validating IPA for AltStore compatibility ===${NC}"

# Check file size (AltStore has a limit of 300MB)
IPA_SIZE_MB=$((IPA_SIZE / 1024 / 1024))
if [ $IPA_SIZE_MB -gt 300 ]; then
    echo -e "${RED}Warning: IPA file size is $IPA_SIZE_MB MB, which exceeds AltStore's 300MB limit${NC}"
    echo -e "${YELLOW}You may need to reduce app size or use app thinning${NC}"
else
    echo -e "IPA size: $IPA_SIZE_MB MB (under the 300MB limit)"
fi

# Check for required frameworks that might not be compatible
FRAMEWORKS_DIR="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app/Frameworks"
if [ -d "$FRAMEWORKS_DIR" ]; then
    echo -e "Checking frameworks for compatibility..."
    ls -la "$FRAMEWORKS_DIR"
    
    # List of frameworks known to cause issues with AltStore
    PROBLEMATIC_FRAMEWORKS=("Firebase" "GoogleAnalytics")
    
    for framework in "${PROBLEMATIC_FRAMEWORKS[@]}"; do
        if find "$FRAMEWORKS_DIR" -name "*$framework*" | grep -q .; then
            echo -e "${YELLOW}Warning: Found potentially problematic framework: $framework${NC}"
            echo -e "${YELLOW}This may cause issues with AltStore distribution${NC}"
        fi
    done
fi

# Final summary
echo -e "\n${GREEN}=== Build Complete ===${NC}"
echo -e "IPA file: $IPA_PATH"
echo -e "Size: $IPA_SIZE_MB MB"
echo -e "AltStore manifest: $OUTPUT_DIR/$ALTSTORE_MANIFEST"
echo -e "\n${YELLOW}Instructions:${NC}"
echo -e "1. Upload the IPA file to your hosting service"
echo -e "2. Update the 'downloadURL' in the manifest file to point to your hosted IPA"
echo -e "3. Upload the manifest file to your server"
echo -e "4. Share the manifest URL with your users to add to AltStore"

# Print QR code for easy addition to AltStore (if qrencode is available)
if command -v qrencode &> /dev/null; then
    echo -e "\n${YELLOW}QR Code for AltStore (replace with your actual hosting URL):${NC}"
    echo "https://example.com/manifests/$ALTSTORE_MANIFEST" | qrencode -t ANSIUTF8
fi

echo -e "\n${GREEN}Done!${NC}"

