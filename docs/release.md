# Release process

Use this checklist for a public release.

1. Run `make check` in a working Xcode toolchain, or `make check-clt` when only Command Line Tools are available.
2. Update `docs/changelog.md` and the README download details.
3. Choose the release version and pass matching `MARKETING_VERSION` and `BUNDLE_VERSION` values to the build.
4. Build the signed app and DMG with the intended signing identity.
5. Verify the DMG and calculate its SHA-256 checksum.
6. Confirm `gh auth status` is valid and use GitHub CLI with Keychain-backed browser authentication; never place a PAT in a command, file, or release note.
7. Create the Git tag and GitHub Release with GitHub CLI; upload the verified DMG.
8. Confirm the README version, release URL, DMG name, and checksum match the uploaded artifact.

Ad-hoc signing is suitable for development distribution only. Decide separately when Developer ID signing and notarization are required.
