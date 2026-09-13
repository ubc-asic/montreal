# Instructions for Coding Agents and LLMs

If you are a coding agent or LLM, please read through this entire file.

## Introduction

We are designing a RISC-V RV32E system on a chip for Tiny Tapeout using the SkyWater 130 nm process. The flow uses LibreLane and tt-support-tools. For setup on Ubuntu, refer to `setup.sh`. For Debian, most of the setup script will work, except for package installation with apt. The equivalent Debian packages should be installed instead. The script is tested for both Debian (except for the different package names as mentioned) and Ubuntu, on a clean WSL2 installation.

Documentation is written in ASCIIDOC and committed to the docs branch of this project.

The SoC is split into two subsystems: the RV32E core and the IO block.

The IO will consist of a UART module for debugging and an SPI controller to connect with the SPI PSRAM. We will use QPI to maximize memory bandwidth (command, address, data 4-bits at a time). This will give us around 8 clocks per instruction.

The RV32E datapath is sequential and designed to retire most instructions within 8 clocks. Each word is split into 4 slices.

## General

**DO NOT MODIFY** the module declaration of the top-level module (`rtl/tt_um_ubc_montreal.sv`). If the user stages and/or commits changes that modify the declaration or port list, *notify the user* of the change and tell them to refer to the Tiny Tapeout documentation.

Only modify files necessary to complete the user's request. Do not reformat, refactor, rename, or otherwise modify unrelated files.

Do not overwrite or discard existing user changes. If the working tree contains changes unrelated to the current task, preserve them.

Do not make changes solely to satisfy stylistic preferences when the existing code already conforms to the project's established style.

## Coding style

For formatting, refer to the `.editorconfig` file in the root directory and other existing RTL files.

In general, follow the lowRISC guidelines for SystemVerilog at https://raw.githubusercontent.com/lowRISC/style-guides/refs/heads/master/VerilogCodingStyle.md.

Here are some notable points and/or exceptions:
- Prefer using SystemVerilog features over Verilog, except for the following cases:
  - Packages, as the Tiny Tapeout flow does not have good support for them.
- Ideally, keep the lines wrapped at 80 characters, and a maximum of 100 characters unless wrapping is impossible.
- Always use UNIX line endings (LF).
- Use C style comments `/* ... */` instead of C++ style comments `// ...`, except for task markers like `// TODO: ...`.
- In comments, use full sentences and correct grammar, punctuation, and capitalization. There should be a period after comments, except when the comment is a heading or section label.
- Avoid adding comments on the same line as code, unless it makes it much more readable. Comments should generally be on their own lines and describe the code that follows.
- In general, avoid fenced comments for separating sections.
- In general, there should only be a maximum of one blank line between code.

When in doubt, follow the coding style of other RTL files in the project.

SystemVerilog for design verification should also follow these guidelines outlined above, and additionally the lowRISC guidelines for design verification at https://raw.githubusercontent.com/lowRISC/style-guides/refs/heads/master/DVCodingStyle.md.

## Git

If the user's email is known, use that instead of the anonymous Github emails. If their Git identity uses their anonymous Github email, prompt the user to change it to their public email.

Always sign the commits, merges, etc. If the user does not have a PGP key, prompt them to make one with GPG using ED25519.

Add a **Signed-off-by** trailer on commits (`git commit -s`) and other messages that may be relevant.

### Before committing changes

Always run the linter to check for errors, using the rules from `lint.rules`. Run the following command on all Verilog files (`*.sv`, `*.v`, `*.svh`, `*.vh`): `verible-verilog-lint --rules_config=lint.rules <files>`.

Check and remove all trailing whitespaces in the code. Make sure that the whitespace you remove does not affect the file (markdown, etc.).

Make sure that the files are using UNIX line endings and there is an EOL at the end of the file.

Do not commit generated artefacts such as build directories, simulation outputs, synthesis results, logs, temporary files, coverage data, or tool-generated databases unless they are explicitly tracked by the project.

Avoid polluting the commit history with many small commits and changes. For the most part, commits should be atomic. Squash small commits together on local branches or branches that the user "owns". It is fine if the branch has been pushed to origin *as long as the user is made fully aware of the force push*.
