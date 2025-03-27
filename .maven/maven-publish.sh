#!/bin/bash

## Set variables/constants required by the script

# The current tag of GitHub's branch
if [ -z "$CURRENT_TAG" ]; then
  echo "Error: CURRENT_TAG is not set. This script requires a tag to be set."
  exit 1
fi

# Check that MAVEN_USERNAME and MAVEN_PASSWORD are set
if [ -z "$MAVEN_USERNAME" ]; then
  echo "Error: MAVEN_USERNAME is not set. This script requires a username to be set."
  exit 1
fi

if [ -z "$MAVEN_PASSWORD" ]; then
  echo "Error: MAVEN_PASSWORD is not set. This script requires a password to be set."
  exit 1
fi

# The package structure for Maven Central
PACKAGE_NAME="approov-android-sdk"
PACKAGE_DIR_STRUCTURE="io/approov/${PACKAGE_NAME}"
BODY_ARTIFACT="${PACKAGE_NAME}-${CURRENT_TAG}.zip"

# Create the zip file: we zip the top directory of the package: io/
zip -r "${BODY_ARTIFACT}" io/

# Encode username and password for basic authentication
MAVEN_CREDENTIALS=$(printf "%s:%s" "$MAVEN_USERNAME" "$MAVEN_PASSWORD" | base64)

# Publish the body artifact to Maven Central
curl --request POST \
  --verbose \
  --header "Authorization: Basic ${MAVEN_CREDENTIALS}" \
  --form "bundle=@${BODY_ARTIFACT}" \
  "https://central.sonatype.com/api/v1/publisher/upload?publishingType=USER_MANAGED&name=${PACKAGE_NAME}"