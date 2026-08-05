# Release process

Use this checklist for a public release.

1. Run `make check` in a working toolchain.
2. Update `docs/changelog.md` and the README download details.
3. Choose the release version and pass matching `MARKETING_VERSION` and `BUNDLE_VERSION` values to the build.
4. Build the signed app and DMG with the intended signing identity.
5. Verify the DMG and calculate its SHA-256 checksum.
6. Create the Git tag and GitHub Release; upload the verified DMG.
7. Confirm the README version, release URL, DMG name, and checksum match the uploaded artifact.

Ad-hoc signing is suitable for development distribution only. Decide separately when Developer ID signing and notarization are required.
