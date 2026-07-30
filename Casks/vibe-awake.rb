# Homebrew cask definition.
#
# This file is kept here for reference, but Homebrew only reads casks from a tap
# repository. To publish it, create a repo named `homebrew-tap` and copy this file to
# `Casks/vibe-awake.rb` in it. Users then install with:
#
#   brew install --cask yamamoto7/tap/vibe-awake
#
# Update `version` and `sha256` for each release; Scripts/notarize.sh prints the checksum
# of the DMG it produces.
#
# The official homebrew-cask repository has notability requirements a brand new project
# will not meet, so a personal tap is the way in.

cask "vibe-awake" do
  version "1.0.0"
  sha256 "4216cd085421641c768b80f4d345b7f60d8ce8b08be599be6629fcfd0787a8d1"

  url "https://github.com/yamamoto7/vibe-awake/releases/download/v#{version}/VibeAwake-#{version}.dmg"
  name "Vibe Awake"
  desc "Keeps the Mac awake while an AI coding session is working"
  homepage "https://github.com/yamamoto7/vibe-awake"

  depends_on macos: ">= :ventura"

  app "Vibe Awake.app"

  # The privileged helper lives outside the app bundle, so it has to be removed explicitly.
  # Homebrew will ask for a password to delete the root-owned files.
  uninstall launchctl: "com.ychof.vibeawake.helper",
            delete:    [
              "/Library/LaunchDaemons/com.ychof.vibeawake.helper.plist",
              "/Library/Application Support/VibeAwake",
            ]

  zap trash: [
    "~/Library/Preferences/com.ychof.vibeawake.plist",
  ]
end
