#!/bin/bash

# Input: new version number (e.g., 1.1.3)
APP_NAME="AlexSideBar"
BASE_PATH="/Users/danieledrisian/Desktop/AlexSideBar"
APP_PATH="$BASE_PATH/releases/$VERSION"
DMG_FILE="${APP_PATH}/${APP_NAME}.dmg"
GITHUB_REPO="DanielEdrisian/AlexSideBar-Public"
ALPHA_TAG="alpha"

# Check if version is provided
if [ -z "$VERSION" ]; then
  echo "Please provide the new version number (e.g., ./release_github_alpha.sh 1.1.3)"
  exit 1
fi

# Create DMG
echo "Creating DMG..."
create-dmg \
  --volname "${APP_NAME} Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 200 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 600 185 \
  --codesign "Developer ID Application: Daniel Edrisian (W2PUF8XW54)" \
  --notarize "Developer ID Application: Daniel Edrisian (W2PUF8XW54)" \
  "$DMG_FILE" \
  "$APP_PATH/"

if [ $? -ne 0 ]; then
  echo "Error: Failed to create DMG."
  exit 1
fi

# Check if the DMG file exists
if [ ! -f "$DMG_FILE" ]; then
  echo "Error: DMG file not found at $DMG_FILE"
  exit 1
fi

# Update or create the alpha tag
echo "Updating or creating the alpha tag..."
git tag -f $ALPHA_TAG
if [ $? -ne 0 ]; then
  echo "Error: Failed to update or create the alpha tag."
  exit 1
fi

echo "Pushing updated alpha tag to remote..."
git push origin $ALPHA_TAG -f
if [ $? -ne 0 ]; then
  echo "Error: Failed to push updated alpha tag to remote."
  exit 1
fi

# Create or update the release
echo "Creating or updating GitHub release for alpha tag..."
gh release delete $ALPHA_TAG --yes --repo "$GITHUB_REPO" 2>/dev/null
gh release create $ALPHA_TAG \
  --repo "$GITHUB_REPO" \
  --title "Alpha Release $VERSION" \
  --notes "This is the latest alpha release (version $VERSION)" \
  --target main
if [ $? -ne 0 ]; then
  echo "Error: Failed to create or update GitHub release."
  exit 1
fi

# Upload the DMG file to the release
echo "Uploading DMG file to the release..."
gh release upload $ALPHA_TAG "$DMG_FILE" \
  --repo "$GITHUB_REPO" \
  --clobber
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload DMG file to GitHub release."
  exit 1
fi

echo "Release for alpha tag updated with version $VERSION and DMG file uploaded to GitHub release successfully."

# Generate appcast
echo "Generating appcast..."
/Users/danieledrisian/Library/Developer/Xcode/DerivedData/AlexSideBar-hdijgyskmgzdbqengtnwylypmkfw/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast "$APP_PATH"
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate appcast."
  exit 1
fi

echo "Appcast generated successfully."

# Modify the appcast.xml file to update the enclosure URL
echo "Updating enclosure URL in appcast.xml..."
sed -i '' 's|url="https://danieledrisian.github.io/AlexSideBar-Public/AlexSideBar.dmg"|url="https://github.com/DanielEdrisian/AlexSideBar-Public/releases/download/alpha/AlexSideBar.dmg"|' "$APP_PATH/appcast.xml"
if [ $? -ne 0 ]; then
  echo "Error: Failed to update enclosure URL in appcast.xml."
  exit 1
fi

# Copy appcast.xml to the repo directory and upload to GitHub
echo "Copying appcast.xml to repo directory and uploading to GitHub..."
cp "$APP_PATH/appcast.xml" "appcast_alpha.xml"
git add appcast_alpha.xml
git commit -m "Update appcast_alpha.xml for version $VERSION"
git push origin main
if [ $? -ne 0 ]; then
  echo "Error: Failed to upload appcast_alpha.xml to GitHub repo."
  exit 1
fi

echo "appcast_alpha.xml uploaded to GitHub repo successfully." 