# AncestryClone Installation Guide for Alternative Stores

This guide provides instructions for installing AncestryClone through various alternative iOS app stores. Choose the method that works best for your situation.

## Table of Contents
- [Comparison of Installation Methods](#comparison-of-installation-methods)
- [AltStore Installation](#altstore-installation)
- [Scarlet Installation](#scarlet-installation)
- [AppDB Installation](#appdb-installation)
- [Sideloadly Installation](#sideloadly-installation)
- [SignTools Installation](#signtools-installation)
- [Troubleshooting](#troubleshooting)

## Comparison of Installation Methods

| Method | Pros | Cons | Requires Computer | Certificate Duration |
|--------|------|------|-------------------|----------------------|
| AltStore | Easy to refresh, reliable | Requires computer connection every 7 days | Yes, for refresh | 7 days |
| Scarlet | No refreshing needed, permanent | Requires iOS ≤15.7.1 or specific devices | No | Permanent |
| AppDB | Simple, one-click install | Paid service for reliable use | No | 1 year (paid) |
| Sideloadly | Free, flexible | Manual installation, 7-day cert | Yes | 7 days |
| SignTools | Self-hosted signing | Complex setup | Yes, for setup | Varies |

## AltStore Installation

### Requirements
- iOS/iPadOS 15.0 or later
- AltStore installed on your device
- Computer with AltServer running (Mac or Windows)

### Installation Steps
1. Open this URL on your iOS device: [altstore://source?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/altstore-manifest.json](altstore://source?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/altstore-manifest.json)

2. If the above direct link doesn't open AltStore, follow these steps:
   - Open AltStore on your iOS device
   - Go to the "Browse" tab
   - Tap "+" in the top-right corner
   - Enter this URL: `https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/altstore-manifest.json`
   - Find AncestryClone and tap "GET"

3. After installation, open Settings → General → VPN & Device Management
   - Find and trust the developer certificate

### Refreshing
- You'll need to refresh the app every 7 days
- Connect to a computer running AltServer
- Open AltStore and tap "Refresh All"

## Scarlet Installation

### Requirements
- iOS device with Scarlet (TrollStore) installed
  - iOS 14.0-15.7.1 on any device, or
  - iOS 16.0-16.5 on arm64e devices (iPhone XS/XR and newer)

### Installation Steps
1. Open this URL on your iOS device with Scarlet installed:
   [scarlet://install?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/scarlet.json](scarlet://install?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/scarlet.json)

2. If the direct link doesn't work, follow these steps:
   - Open Scarlet on your device
   - Go to "Sources" tab
   - Tap "Add Source"
   - Enter: `https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/scarlet.json`
   - Find AncestryClone in the list and tap "GET"

3. The app will be installed permanently with no need to refresh certificates.

## AppDB Installation

### Requirements
- iOS 15.0 or later
- AppDB app or website access
- AppDB PRO subscription for reliable installation (recommended)

### Installation Steps
1. If you have AppDB installed, open this URL:
   [appdb://install?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/appdb.json](appdb://install?url=https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/appdb.json)

2. Alternatively:
   - Visit [appdb.to](https://appdb.to) on your iOS device
   - Log in to your account
   - Search for "AncestryClone" or paste this URL in your browser:
     `https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/appdb.json`
   - Tap "Install" and follow the prompts

3. If using AppDB PRO, your app will be signed with a 1-year enterprise certificate.

## Sideloadly Installation

### Requirements
- Computer (Mac or Windows)
- Sideloadly app installed on your computer
- Apple ID

### Installation Steps
1. Download Sideloadly from [sideloadly.io](https://sideloadly.io) and install it
2. Download the AncestryClone IPA file: [AncestryClone.ipa](https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/AncestryClone.ipa)
3. Connect your iOS device to your computer
4. Open Sideloadly
5. Drag and drop the AncestryClone.ipa file into Sideloadly
6. Enter your Apple ID and password when prompted
7. Click "Start" to begin the installation
8. After installation, trust the developer certificate in Settings → General → VPN & Device Management

### Refreshing
- You'll need to repeat this process every 7 days using a free Apple ID
- If using a paid Apple Developer account, the certificate lasts for 1 year

## SignTools Installation

### Requirements
- Self-hosted SignTools server or access to one
- Basic understanding of iOS app signing

### Installation Steps
1. If you have SignTools set up, use the direct IPA URL in your configuration:
   `https://github.com/arvindcr4/AncestryClone/releases/download/v1.0.0/AncestryClone.ipa`

2. If you're using a public SignTools instance:
   - Visit the SignTools web interface
   - Upload the IPA or provide the URL above
   - Follow the service's specific instructions for signing and installation

3. After installation, trust the certificate in Settings → General → VPN & Device Management

## Troubleshooting

### Common Issues

#### "Unable to Install" Error
- Make sure you have an internet connection
- If using AltStore, ensure AltServer is running
- If using Scarlet, verify your iOS version is supported
- For AppDB, make sure your device is linked to your account

#### App Crashes on Launch
- Delete the app and reinstall
- Make sure you've trusted the developer certificate
- Verify your iOS version meets the minimum requirements (iOS 15.0+)

#### "Unable to Verify App" Error
- Trust the developer certificate in Settings → General → VPN & Device Management
- If the certificate isn't listed, the installation may have failed; try reinstalling

#### Certificate Revoked
- Apple occasionally revokes certificates used for sideloading
- If this happens, you'll need to reinstall using a new certificate
- Scarlet installations are immune to certificate revocations

### Support

If you encounter issues not covered here, please reach out:

- GitHub Issues: [github.com/arvindcr4/AncestryClone/issues](https://github.com/arvindcr4/AncestryClone/issues)
- Email: support@ancestryclone.example.com

---

Last Updated: April 23, 2025

