#!/bin/bash
# Ensure the script fails on errors
set -e

# Retrieve the tag from GITHUB_REF
if [ -z "$GITHUB_REF" ]; then
    echo "Error: GITHUB_REF is not set. This script requires a GitHub tag to be present."
    exit 1
fi

# Extract the tag name from GITHUB_REF
#CURRENT_TAG=$(echo "$GITHUB_REF" | sed 's|refs/tags/||')
CURRENT_TAG=3.4.0
# Check if the extracted tag matches the expected format (e.g., x.y.z)
if [[ ! "$CURRENT_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Current Git tag ($CURRENT_TAG) does not match the required format (x.y.z)."
    exit 1
fi

# The version of the package that will be built
VERSION="${CURRENT_TAG}"
echo "VERSION: ${VERSION}"

# Package name and directory structure for Maven Central
PACKAGE_NAME="approov-android-sdk"
PACKAGE_DIR_STRUCTURE="io/approov/${PACKAGE_NAME}"
FILE_PREFIX="${PACKAGE_NAME}-${VERSION}"

# PGP Signing Key and Password (Set in CI/CD environment)
if [ -z "$PGP_KEY_ID" ]; then
    echo "Error: PGP_KEY_ID is not set."
    exit 1
fi

if [ -z "$GPG_PASSWORD" ]; then
    echo "Error: GPG_PASSWORD is not set."
    exit 1
fi

# Paths to required files
AAR_PATH="../approov-sdk/approov-sdk.aar"
JAVADOC_JAR_PATH="../approov-sdk/javadoc.jar"
POM_FILE_PATH="../approov-sdk/pom.xml"

# Verify existence of required files
for file in "$AAR_PATH" "$JAVADOC_JAR_PATH" "$POM_FILE_PATH"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found - $file"
        exit 1
    fi
done

# Update POM file with the correct version
#sed -i "s/VERSION_PLACEHOLDER/${VERSION}/g" "$POM_FILE_PATH"

# Create destination directory
DESTINATION_DIR="${PACKAGE_DIR_STRUCTURE}/${VERSION}"
mkdir -p "$DESTINATION_DIR"

# Copy and rename required files
cp "$JAVADOC_JAR_PATH" "$DESTINATION_DIR/${FILE_PREFIX}-javadoc.jar"
cp "$AAR_PATH" "$DESTINATION_DIR/${FILE_PREFIX}.aar"
cp "$POM_FILE_PATH" "$DESTINATION_DIR/${FILE_PREFIX}.pom"

# Sign the files using GPG
for file in "${DESTINATION_DIR}/${FILE_PREFIX}-javadoc.jar" "${DESTINATION_DIR}/${FILE_PREFIX}.aar" "${DESTINATION_DIR}/${FILE_PREFIX}.pom"; do
    gpg --batch --yes --passphrase "$GPG_PASSWORD" --pinentry-mode loopback --output "$file.asc" --detach-sign --local-user "$PGP_KEY_ID" "$file"
done

# Generate hash files
for algo in sha1 sha256 sha512 md5; do
    for file in "${DESTINATION_DIR}/${FILE_PREFIX}-javadoc.jar" "${DESTINATION_DIR}/${FILE_PREFIX}.aar" "${DESTINATION_DIR}/${FILE_PREFIX}.pom"; do
        output_file="${file}.${algo}"
        if [ "$algo" == "md5" ]; then
            md5sum "$file" | awk '{print $1}' > "$output_file"
        else
            shasum -a "${algo#sha}" "$file" | awk '{print $1}' > "$output_file"
        fi
    done
done

echo "Build and signing complete: Files are in ${DESTINATION_DIR}"
