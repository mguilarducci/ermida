# System packages on macOS, installed by bin/setup with `brew bundle`. Arch/Omarchy gets the same ones
# from [bootstrap.packages] in .mise.toml. Chrome for system tests is installed by bin/setup only when
# no Chrome or Chromium app is present, since Homebrew refuses to install over one it did not install.
brew "vips"
brew "libyaml"
# psql for bin/rails dbconsole; keg-only, so linked onto PATH
brew "libpq", link: true
