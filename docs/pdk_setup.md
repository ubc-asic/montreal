# SKY130 PDK setup (for `make area`)

`make area` maps the design onto real SKY130 standard cells to report area,
via a liberty file supplied by [volare](https://github.com/efabless/volare).
This is a one-time setup per machine.

## Quick path

Run this in the **same shell you use to run `make`** (e.g. your WSL/OSS CAD
Suite terminal, not a separate Windows shell):

```bash
flows/scripts/install_pdk.sh
```

If it reports that `volare` was just installed, open a new shell (or
`source ~/.bashrc`) and run the script again to actually fetch the PDK.

Then confirm:

```bash
make area
```

## Manual steps

1. Install [pipx](https://pipx.pypa.io/) (isolates `volare` from your system
   Python — plain `pip install volare` will fail with
   `externally-managed-environment` on Debian/Ubuntu, including WSL):
   ```bash
   sudo apt install -y pipx
   pipx install volare
   pipx ensurepath
   ```
2. Open a new shell so the `PATH` update takes effect.
3. Enable the PDK version pinned in `flows/common.mk` (`PDK_VERSION`):
   ```bash
   volare enable --pdk sky130 <PDK_VERSION from flows/common.mk>
   ```
4. Verify it resolved correctly:
   ```bash
   volare path --pdk sky130 <PDK_VERSION>
   ```
   This should print a real, existing directory. If `make area` still can't
   find the `.lib` file afterwards, check that this path actually exists
   (`ls` it) — a `volare enable` that didn't run to completion will still
   let `volare path` print a path, just not one that exists yet.

## Notes

- `PDK_VERSION` is pinned in `flows/common.mk` so everyone on the project
  gets identical area numbers from the same PDK release. Don't `volare
  enable` a different version without updating that pin.
- On WSL: install and run `volare` *inside* WSL, not on the Windows side.
  `volare` invoked via Windows/WSL interop prints a Windows-style path
  (`C:/Users/...`) that `yosys` (running in WSL) can't read directly.
- `PDK_ROOT`/`PDK`/`SKY130_LIB` in `flows/common.mk` can all be overridden
  on the command line if your setup differs, e.g.:
  ```bash
  make area PDK_ROOT=/path/to/.volare/volare/sky130/versions/<hash>
  ```