# AOSPA Kernel Builder — Marble

[![Kernel Image](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-image.yml/badge.svg?branch=main)](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-image.yml)
[![KernelSU LKM](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml/badge.svg?branch=main)](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml)

GitHub Actions build environment for the **AOSPA kernel targeting Xiaomi marble** (POCO F5 / Redmi Note 12 Turbo).

This project uses **KernelSU in LKM mode**. The raw kernel image and KernelSU LKM modules are built in separate workflows. The LKM must be used with a compatible kernel built from the matching source revisions.

## Features

- AOSPA kernel source synchronized through Repo and the project's manifest.
- KernelSU configured as a loadable module (`CONFIG_KSU=m`).
- Separate manual workflows for the kernel image and LKM modules.
- NoMount built as a companion LKM in the module workflow.
- Clang toolchain `clang-r596125`, with GitHub Actions caching.
- Build metadata recording source revisions, toolchain, workflow run, and relevant kernel configuration.
- Required artifact checks to prevent missing or empty Image / LKM files from being uploaded as successful builds.
- Runner disk cleanup, swap setup, explicit job timeouts, and limited workflow permissions.

> **Device scope:** The GitHub Actions workflows are configured for `marble`. The local build script contains a `cupid` target case, but these workflows do not currently provide a complete Cupid build configuration.

## Workflows and artifacts

Both workflows are started manually through the **Actions** tab and run on GitHub-hosted Ubuntu 22.04.

| Workflow | Build mode | Artifact | Contents |
| --- | --- | --- | --- |
| Kernel Image | `./build.sh marble --only-kernel` | `kernel-image` | Raw `Image` + `build-info.txt` |
| KernelSU LKM Module | `./build.sh marble --only-modules` | `ksu-lkm-module` | `kernelsu.ko`, `nomount.ko` + `build-info.txt` |

### Run a build

1. Open **Actions** in the repository.
2. Select **Kernel Image**, then click **Run workflow**.
3. Select **KernelSU LKM Module**, then click **Run workflow**.
4. Download the artifacts from their respective completed workflow runs.
5. Keep the two `build-info.txt` files and compare their source revisions before using the modules with the kernel.

The image workflow produces a raw kernel `Image`. It does **not** create a `boot.img`, AnyKernel3 ZIP, or flashable installer. The module workflow produces standalone `.ko` files; it does not package a KernelSU manager APK or a flashable module ZIP.

**Important:** Both workflows synchronize their source trees independently. If upstream branches move between runs, the kernel and LKM builds may use different source revisions. Always compare the metadata and rebuild both artifacts when the relevant kernel source or configuration differs.

## Source layout

```text
.
├── .github/
│   └── workflows/
│       ├── build-image.yml
│       ├── build-lkm.yml
│       └── cleanup.yml
├── android_kernel_xiaomi_sm8450/
│   ├── build.sh
│   └── scripts/
│       └── setlocalversion
├── scripts/
│   └── write-build-info.sh
├── manifest.xml
└── README.md
```

The manifest assembles the kernel source, build tools, device trees, vendor modules, and supporting build projects. The local `android_kernel_xiaomi_sm8450/` directory contains the project-specific build script and `setlocalversion` override copied into the synchronized kernel tree.

## Build script options

The script runs from the synchronized kernel source directory and requires `.build.rc` containing `SRC_ROOT=<path-to-AOSPA-source>`. The GitHub Actions workflows create this file automatically.

| Command | Purpose |
| --- | --- |
| `./build.sh marble --only-kernel` | Build and stage the kernel Image |
| `./build.sh marble --only-modules` | Build kernel modules and stage vendor module outputs |
| `./build.sh marble --only-dtb` | Build DTBs / DTBO |
| `./build.sh marble --only-config` | Generate kernel configuration only |
| `./build.sh marble` | Full build: Image, modules, and DTBs |
| `./build.sh marble --no-lto` | Disable Clang Full LTO |
| `./build.sh marble --clean` | Clean output directory and the local modules checkout |

The Actions workflows currently use only the image-only and modules-only modes.

## KernelSU and NoMount

- KernelSU is configured as `CONFIG_KSU=m` and delivered as `kernelsu.ko`.
- NoMount is configured as a separate module and delivered as `nomount.ko`.
- KernelSU is pinned to commit `dbb73665d103da40c7ecbd21ba3b5ac76eb95784` in both workflows.
- NoMount is pinned to commit `bf1847f98fed382369c43bfd652cd93774b9b8e3` in the LKM workflow.
- The build script now stops if either required module is missing or empty.
- The modules must match the kernel build they are intended to run with. Do not assume an LKM from an unrelated kernel build is compatible.

This repository does **not** currently integrate SUSFS. It also does not configure Magisk integration or flashable ZIP packaging.

## Reproducibility and build metadata

Each artifact includes `build-info.txt`, which records:

- Device target and build type.
- Workflow name, run ID, attempt, and builder commit.
- Clang toolchain directory and pinned KernelSU / NoMount revisions.
- Git revisions for the kernel, build tools, device trees, and vendor modules.
- Relevant options from the generated kernel `.config`.

KernelSU and NoMount are pinned so their setup scripts do not silently follow a moving branch. The AOSPA manifest is still initialized from its upstream `main` branch; the recorded component revisions provide a trace of what Repo synchronized for each run.

The Clang cache is keyed by runner OS and toolchain directory. Build jobs have a six-hour timeout, use Bash strict mode in setup/build steps, and fail artifact upload when expected files are absent.

## Cleanup workflow

**Cleanup Workflow Runs** can be started manually from Actions.

- `keep`: number of newest completed workflow runs to retain (default: `3`).
- `mode=all-finished`: delete completed runs beyond the retention window.
- `mode=failed-only`: delete failed or non-success completed runs beyond the retention window while preserving successful runs.

This workflow deletes GitHub Actions run history. It does not delete source code or releases.

## Further improvement opportunities

The workflows are more reproducible and validate their key outputs, but a few changes should be approached separately and tested before adoption:

1. Pin the AOSPA manifest repository itself to a reviewed commit or release tag, rather than tracking `main`.
2. Consider extracting the duplicated environment setup into a reusable workflow or composite action once the current build path is stable.
3. Add a controlled build matrix only when another device has a verified manifest, defconfig, DTB selection, and artifact layout.
4. Add a test build on a self-hosted runner or a dedicated validation branch before changing the compiler, LTO mode, or build flags.

## Credits

- AOSPA ShadeDark kernel and build infrastructure contributors.
- [KernelSU](https://github.com/tiann/KernelSU) upstream maintainers.
- [NoMount](https://github.com/maxsteeel/nomount) upstream maintainers.

The local build script retains its original copyright notice.

## Disclaimer

For development and testing. An incompatible kernel image or module can cause boot failure or data loss. Verify the device target, keep a known-good recovery path, and make a backup before flashing or loading modules.
