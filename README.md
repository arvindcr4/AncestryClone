# AncestryClone

A powerful genealogy app with comprehensive iPad support for exploring your family history.

## 📱 Installation

Visit our [installation page](https://github.com/arvindcr4/AncestryClone/releases/latest) to install AncestryClone through your preferred method:

- **[AltStore](distribution/docs/ALTSTORE_README.md)** - Most reliable, 7-day refresh required
- **[Scarlet](distribution/docs/ALTERNATIVE_STORES.md#scarlet-installation)** - Permanent installation (iOS ≤15.7.1)
- **[AppDB](distribution/docs/ALTERNATIVE_STORES.md#appdb-installation)** - Simple installation process
- **[Direct IPA](https://github.com/arvindcr4/AncestryClone/releases/latest/download/AncestryClone.ipa)** - Manual sideloading

## 🌟 Features

- Comprehensive family tree visualization
- iPad-optimized interface with split view
- Multi-window support
- Apple Pencil support
- iCloud sync
- Advanced search capabilities

## 📋 Requirements

- iOS/iPadOS 15.0 or later
- Compatible with iPhone and iPad
- Some features require iPad-specific capabilities

## 📚 Documentation

- [User Guide](distribution/docs/USER_GUIDE.md)
- [iPad Support](distribution/docs/IPAD_SUPPORT.md)
- [Alternative Stores](distribution/docs/ALTERNATIVE_STORES.md)

## 🏗 Project Structure

```
AncestryClone/
├── Core/                 # Core functionality
│   ├── Models/          # Data models
│   ├── Persistence/     # Data persistence
│   └── Services/        # Business logic
├── Features/            # App features
│   └── FamilyTree/      # Family tree functionality
├── distribution/        # Distribution files
│   ├── configs/         # Store configurations
│   ├── docs/           # Documentation
│   └── releases/       # Release artifacts
└── .github/            # GitHub configuration
```

## 🚀 Release Process

1. Update version in `distribution/configs/altstore-manifest.json`
2. Create a new GitHub release
3. GitHub Actions will automatically:
   - Build and package the release
   - Update documentation
   - Deploy to all distribution channels

### 📦 Continuous Deployment

Every push to the `main` branch triggers a GitHub Actions workflow that
runs [Fastlane](https://fastlane.tools) to build the app and upload the
beta to TestFlight. Store your App Store Connect API key in the repository
secrets as `APP_STORE_CONNECT_API_KEY` for the workflow to authenticate.

## 💬 Support

- [GitHub Issues](https://github.com/arvindcr4/AncestryClone/issues)
- [Installation Help](distribution/docs/ALTERNATIVE_STORES.md#troubleshooting)
- Email: support@ancestryclone.example.com

## 📅 Version History

### 1.0.0 (April 23, 2025)
- Initial release
- Comprehensive iPad support
- Multiple installation methods
- Enhanced tree visualization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

⭐️ If you find AncestryClone useful, please star the repository!

