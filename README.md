# octave-ci

Shared continuous integration for GNU Octave packages.

One reusable workflow builds a package from a commit, installs it and runs
its tests on Linux, Windows and macOS.  A package adopts it by adding a
single file to its own repository.

The Windows part is what this repository also holds data for: GitHub offers
no Octave on a Windows runner, so each release here carries GNU's Windows
build of Octave unchanged, and a composite action installs it.  Linux uses
the official Octave containers and macOS uses Homebrew, so neither needs
anything stored here.

## Adopting it

Add `.github/workflows/tests.yml` to the package repository:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: tests-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    uses: pr0m1th3as/octave-ci/.github/workflows/package-test.yml@v1
```

That is the whole of it for a package that depends on nothing but Octave.
It needs no secrets and no other file.  Four jobs run: Linux on Octave
11.1.0 and 11.3.0, Windows on 11.3.0, and macOS on whatever version
Homebrew currently ships.

If the package depends on other Octave packages, name them in the order
they must be installed:

```yaml
jobs:
  test:
    uses: pr0m1th3as/octave-ci/.github/workflows/package-test.yml@v1
    with:
      dependencies: 'datatypes'
```

Two settings to check once, in the package repository:

- **Actions permissions.**  Settings, Actions, General: the repository must
  allow actions and reusable workflows from outside itself.  A repository
  restricted to its own actions will refuse the call.
- **Pushing the file.**  GitHub rejects a push that adds or changes anything
  under `.github/workflows/` unless the credential carries the `workflow`
  scope.  An SSH remote has no such limit; a personal access token needs the
  scope added.

### What the package has to provide

- A `DESCRIPTION` file with a `Name:` line.  The workflow reads the package
  name from it and uses it for `pkg load` and `pkg test`.
- Tests that `pkg test` finds, that is, tests inside the installed files.
- Every file the package needs committed to git.  Each job builds the
  archive with `git archive` from the tested commit, so uncommitted files
  are not there, and any `export-ignore` in `.gitattributes` takes files out
  of the archive as well.
- Tests that run without a display.  The runners are headless and Octave is
  started without its graphical interface, so a test that opens a figure
  will fail.
- Dependencies published on Octave Packages.  They are installed with
  `pkg install -forge`, which reaches the index, not a git repository.

Compiled sources are built on all three platforms.  Every platform's
toolchain is present and this repository's own tests use a package with a
`.cc` file to prove it.

## Inputs
The following table list the available input arguments to the CI along with
their defaults, which are written above exactly as a caller writes them.

| Input | Default | Meaning |
|-------|---------|---------|
| `path` | `'.'` | The package's root, if not the repository's |
| `linux-versions` | `'["11.1.0", "11.3.0"]'` | Test on Linux with these Octave containers |
| `windows-versions` | `'["11.1.0", "11.3.0"]'` | Test on Windows with these Octave builds |
| `macos` | `true` | Test on macOS with Homebrew's Octave |
| `dependencies` | `''` | Packages to install first, space separated |

 * `linux-versions` names tags of the `ghcr.io/gnu-octave/octave` container.
 * `windows-versions` names releases of this repository.
 * `macos` always runs on whichever Octave version Homebrew currently ships.

A package that requires testing a specific Octave on Linux and does not want
the macOS job:

```yaml
jobs:
  test:
    uses: pr0m1th3as/octave-ci/.github/workflows/package-test.yml@v1
    with:
      linux-versions: '["11.3.0"]'
      macos: false
```

Note that with the above example, both `"11.1.0"` and `"11.3.0"` Octave
versions are deployed on the Windows runners

Windows is the platform that can be turned off, with an empty list:

```yaml
    with:
      windows-versions: '[]'
```

Linux cannot be turned off.  An empty `linux-versions` is an error rather
than a run with no Linux jobs, so a typo there cannot pass for a green run.

`path` is left alone when the repository is the package, which is the usual
case.  It names the package's own root folder, for a repository that holds
more than the package.  This repository is one: `tests/ciprobe` is a package
inside a repository that is not a package, and its workflow calls

```yaml
    with:
      path: tests/ciprobe
```

Only that folder is archived, so anything outside it is absent when the tests
run.  `DESCRIPTION` always sits at the package's root; `path` says where that
root is, it does not move `DESCRIPTION` within the package.

## What each job does

1. checks out the commit and builds `package.tar.gz` with `git archive`
   (`pkg install` refuses a plain folder, so an archive is needed);
2. installs each dependency with `pkg install -forge -local`;
3. installs the package from the archive, loads it and runs `pkg test`;
4. prints every failing test from Octave's test log, grouped under the file
   it came from;
5. uploads the test log and the full output of `pkg test` as an artifact,
   whether the job passed or failed, kept for 14 days;
6. fails if no test passed, if any test failed, or if any regression was
   reported.

The last point is worth stating plainly: Octave exits successfully even when
tests fail, so the job reads the counts in the `Summary:` block instead of
trusting the exit status.

The artifacts are named `test-logs-linux-<version>`,
`test-logs-windows-<version>` and `test-logs-macos`.  Jobs are independent,
so one platform failing does not cancel the others.

## Platforms

| Platform | Octave | How |
|----------|--------|-----|
| Linux | one job per `linux-versions` entry | Octave container |
| Windows | one job per `windows-versions` entry | the `windows` action |
| macOS | current | `brew install octave` |

## Checking a run

Everything below uses the GitHub CLI, `gh`, from a clone of the package.
`git` itself cannot reach GitHub Actions, and the same information is on the
repository's Actions tab in a browser.

List the last runs of the package's own workflow file, with their IDs:

```
gh run list --workflow tests.yml --limit 5
```

Follow one that is still running:

```
gh run watch <run-id>
```

Show the jobs of a finished run, whether each passed, and their job IDs:

```
gh run view <run-id>
```

### Reading a job's log

`gh run view --log` prints nothing for these jobs, because they come from a
reusable workflow held in another repository.  Ask the API for the log
instead, with a job ID from `gh run view`:

```
gh api repos/<owner>/<package>/actions/jobs/<job-id>/logs
```

That log already contains the failing tests: the job prints each failed
block under the file it came from before it fails, so a short failure often
needs nothing else.

### Getting `fntests.log`

Every job uploads Octave's own test log whether it passed or failed.  It is
kept for 14 days.  Download all four at once, each into a folder named after
its job:

```
gh run download <run-id> --dir ci-logs
```

or one platform on its own:

```
gh run download <run-id> --name test-logs-linux-11.3.0 --dir ci-logs
```

Give `--dir` a name of its own; some versions of `gh` refuse `--dir .` with
a path traversal error.  The artifact names are
`test-logs-linux-<version>`, `test-logs-windows-<version>` and
`test-logs-macos`.

Each folder holds two files:

- `fntests.log`, Octave's full test log, named `test_suite.log` from Octave
  12, with every test file listed and every failure reported in full;
- `test.log`, everything `pkg install` and `pkg test` wrote, which is where
  an installation or compilation failure shows up.

Failures are marked in `fntests.log` by a line starting with `!!!!!`, and
the test that produced one begins at the `*****` line above it:

```
grep -n '^!!!!!' ci-logs/test-logs-linux-11.3.0/fntests.log
```

The paths in the log are the runner's, and point inside the installed copy
of the package, not the checkout.

## The Windows action on its own

A package that wants to build its own Windows job, rather than use the
reusable workflow, can install Octave with the action directly:

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

The action:

1. downloads the Octave archive from a release of this repository, or
   restores it from the cache, and checks its SHA-256 checksum;
2. extracts it to `C:\octave-ci`, leaving out the bundled packages, their
   package list, and the folders package tests never use: documentation,
   CMake modules, Qt, LLVM and wxWidgets headers, and the MSYS Python and
   terminfo;
3. stops the job if `pkg list` still finds any package.

The bundled packages are left out so that the only package present is the
one under test, whose own copy would otherwise sit beside an older one from
the archive.

It puts `octave-launch.exe` on the path and returns its full path in the
`octave` output.  It takes about a minute.

### Available versions

| Version | Release |
|---------|---------|
| 11.1.0  | [`octave-11.1.0`][r-11.1.0] |
| 11.3.0  | [`octave-11.3.0`][r-11.3.0] |

[r-11.1.0]: https://github.com/pr0m1th3as/octave-ci/releases/tag/octave-11.1.0
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

- GNU Octave 11.1.0:
  <https://ftp.gnu.org/gnu/octave/octave-11.1.0.tar.xz>, built by MXE Octave
  at revision `daf53bace29b`:
  <https://hg.octave.org/mxe-octave/rev/daf53bace29b>
- GNU Octave 11.3.0:
  <https://ftp.gnu.org/gnu/octave/octave-11.3.0.tar.xz>, built by MXE Octave
  at revision `8837c9048e1a`:
  <https://hg.octave.org/mxe-octave/rev/8837c9048e1a>

Each revision is recorded in its archive's `HG-ID` file.

## This repository's own tests

`tests/ciprobe` is a small package that exists only to be installed and
tested by the workflows here.  It has a `DESCRIPTION`, a function with
tests, and a `.cc` file, so a run of `test-package.yml` proves the whole
path on every platform, compilation included, without depending on a real
package.  `test-windows.yml` tests the Windows action by itself.

The `v1` tag moves only to a commit whose self-tests are green.

## License

The files in this repository are licensed under the GNU General Public
License, version 3 or later.  See `COPYING`.
