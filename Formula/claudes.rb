# Homebrew formula for `claudes`.
#
# To ship it as a tap:
#   1. Tag a release:  git tag v0.1.0 && git push --tags
#   2. Get the tarball sha256:
#        curl -sL https://github.com/thomascailhol/claudes/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
#   3. Fill `url` + `sha256` below and copy this file to the tap repo
#      github.com/thomascailhol/homebrew-tap (Formula/claudes.rb).
#   4. Install:  brew install thomascailhol/tap/claudes
#
class Claudes < Formula
  desc "Run multiple isolated Claude Desktop instances on macOS"
  homepage "https://github.com/thomascailhol/claudes"
  url "https://github.com/thomascailhol/claudes/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"

  # Icons render crisply with rsvg-convert; the tool also falls back to
  # ImageMagick or the built-in qlmanage, but librsvg gives the best result.
  depends_on "librsvg"

  def install
    libexec.install "claudes"
    bin.install_symlink libexec/"claudes"
  end

  test do
    assert_match "claudes #{version}", shell_output("#{bin}/claudes version")
  end
end
