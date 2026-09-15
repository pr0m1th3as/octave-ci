# octave-ci

Continuous integration support for GNU Octave packages.

## Windows

The `windows` action installs GNU Octave on a GitHub-hosted Windows runner,
so a package can be built and tested there.  It leaves out the Octave Forge
packages that come bundled with the Windows build of Octave, so that only
the package under test is installed.

```yaml
jobs:
  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v5
      - uses: pr0m1th3as/octave-ci/windows@v1
        with:
          version: '11.3.0'
      - shell: bash
        run: |
          git archive --format=tar.gz --prefix=package/ -o package.tar.gz HEAD
          archive="$(cygpath -w "$PWD/package.tar.gz")"
          octave-launch --no-gui --eval "pkg ('install', '-local', '$archive')"
```

`pkg install` takes a package archive, not a folder, so the example builds
one from the checked-out commit first.

The action:

1. downloads the Octave archive from a release of this repository, or
   restores it from the cache, and checks its SHA-256 checksum;
2. extracts it to `C:\octave-ci`, leaving out the bundled packages, their
   package list, and the folders package tests never use: documentation,
   CMake modules, Qt, LLVM and wxWidgets headers, and the MSYS Python and
   terminfo;
3. stops the job if `pkg list` still finds any package.

It puts `octave-launch.exe` on the path and returns its full path in the
`octave` output.

### Available versions

| Version | Release |
|---------|---------|
| 11.3.0  | [`octave-11.3.0`][r-11.3.0] |

[r-11.3.0]: https://github.com/pr0m1th3as/octave-ci/releases/tag/octave-11.3.0

## The Octave archives

Each release holds a Windows build of Octave exactly as GNU publishes it at
<https://ftp.gnu.org/gnu/octave/windows/>, together with GNU's signature and
a SHA-256 checksum.  To check an archive against the GNU keyring:

```
curl -O https://ftp.gnu.org/gnu/gnu-keyring.gpg
gpgv --keyring ./gnu-keyring.gpg octave-11.3.0-w64.7z.sig octave-11.3.0-w64.7z
```

GNU Octave and the software distributed with it are free software.  The
source code for each archive is available from:

- GNU Octave 11.3.0:
  <https://ftp.gnu.org/gnu/octave/octave-11.3.0.tar.xz>
- MXE Octave, which built the Windows archive, at revision `8837c9048e1a`
  (recorded in the archive's `HG-ID` file):
  <https://hg.octave.org/mxe-octave/rev/8837c9048e1a>

## License

The files in this repository are licensed under the GNU General Public
License, version 3 or later.  See `COPYING`.
