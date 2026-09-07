# OSS CAD Suite Setup (Windows via WSL)

This project's build flows (`flows/lint.mk`, `flows/synth.mk`, `dv/formal/**/*.sby`)
need `yosys`, `verilator`, and `sby`, which all ship together in the
[YosysHQ OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build). On
Windows, run it through WSL rather than the native Windows build — the repo's
Makefiles assume a POSIX shell.

## 1. Install WSL

If you don't already have WSL, open PowerShell as Administrator and run:

```powershell
wsl --install
```

This installs WSL2 with Ubuntu by default and prompts a reboot. After reboot,
launch "Ubuntu" from the Start menu once to finish first-time setup (create a
Linux username/password).

If WSL is already installed, just open it:

```powershell
wsl
```

## 2. Clone the repo (WSL-native, not `/mnt/c`)

You can access your Windows files from WSL under `/mnt/c/...`, and the repo
will work there. But `/mnt/c` goes through the 9p filesystem bridge, which is
noticeably slow for the many small file reads that `lint`/`synth`/`sby` do.
Prefer a WSL-native clone under your Linux home directory:

```bash
cd ~
git clone <repo-url> montreal
cd montreal
```

If you'd rather keep using your existing Windows checkout instead of cloning
again, you can `cd` into it from WSL:

```bash
cd /mnt/c/Users/<you>/Documents/github_repos/montreal
```

Both work; the WSL-native clone is just faster for iterative lint/synth runs.

## 3. Download and install OSS CAD Suite

From inside WSL (**not** a Windows path — install into your Linux home so the
binaries aren't going through `/mnt/c`):

```bash
cd ~
```

Grab the latest Linux x64 release tarball from the
[oss-cad-suite-build releases page](https://github.com/YosysHQ/oss-cad-suite-build/releases)
— pick the asset named `oss-cad-suite-linux-x64-<date>.tgz`. Either fetch it
directly from WSL:

```bash
curl -LO https://github.com/YosysHQ/oss-cad-suite-build/releases/download/<date>/oss-cad-suite-linux-x64-<date>.tgz
```

or, if you downloaded it in your Windows browser instead, it'll land in your
Windows Downloads folder, which is reachable from WSL under `/mnt/c`. Copy it
into your WSL home (don't extract it from `/mnt/c` directly — same 9p
slowdown as before):

```bash
cp /mnt/c/Users/<you>/Downloads/oss-cad-suite-linux-x64-<date>.tgz ~/
```

Extract it:

```bash
tar xzf oss-cad-suite-linux-x64-<date>.tgz
```

This creates `~/oss-cad-suite/`.

## 4. Source the environment

The suite doesn't install onto your `PATH` automatically — you need to source
its environment script in every new shell session before using it:

```bash
source ~/oss-cad-suite/environment
```

To avoid doing this manually every time, add it to your shell rc file so new
WSL shells pick it up automatically:

```bash
echo 'source ~/oss-cad-suite/environment' >> ~/.bashrc
```

## 5. Verify the install

```bash
yosys -V
verilator --version
sby -h
```

Each should print a version/help banner instead of "command not found".

## 6. Run the repo's flows

From the repo root in WSL:

```bash
make lint          # verilator --lint-only over rtl/filelist.f
make lint_wall      # same, with -Wall
make cellcount      # yosys cell count report
```

Formal proofs (`sby`) are run per-testbench, e.g.:

```bash
sby -f dv/formal/regfile/regfile.sby
sby -f dv/formal/simple_alu/simple_alu.sby
```

## Notes

- Re-run `source ~/oss-cad-suite/environment` (or open a new shell, if you
  added it to `~/.bashrc`) any time `yosys`/`verilator`/`sby` aren't found —
  it's a plain env var/PATH setup, not a persistent install.
- If you edit files from Windows tools (VS Code, etc.) against the WSL-native
  clone, point your editor's WSL/Remote extension at `~/montreal` rather than
  editing through `\\wsl$\...` from a native Windows app when possible, to
  avoid the same cross-filesystem slowdown.
- Output directories (`make`'s `$(OUTPUT_DIR)`, default `output/`) are
  generated — no need to commit anything from there.
