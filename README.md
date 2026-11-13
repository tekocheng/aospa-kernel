# AOSPA Kernel Builder — Marble

[![Kernel Image](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-image.yml/badge.svg?branch=main)](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-image.yml)
[![KernelSU LKM](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml/badge.svg?branch=main)](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml)

A GitHub Actions build environment for the **AOSPA kernel targeting Xiaomi marble** (Poco F5 / Redmi Note 12 Turbo).

This project focuses on **KernelSU in LKM mode**. The kernel image and KernelSU module are built as separate artifacts so the LKM can be installed independently of the kernel image.

## Highlights

- AOSPA kernel source and build layout for the **marble** target.
- KernelSU from the official [tiann/KernelSU](https://github.com/tiann/KernelSU) repository, configured as a loadable kernel module.
- Separate workflows for the kernel image and KernelSU LKM.
- [NoMount](https://github.com/maxsteeel/nomount) built as an additional companion module.
- Clang toolchain `clang-r596125`.
- Repo-based source synchronization using the project's [manifest.xml](manifest.xml).
- GitHub Actions disk-space cleanup, swap setup, and Clang caching.

> **Scope:** The GitHub Actions workflows are wired for `marble`. Although the build script contains another target case, that does not mean the other device is supported by these workflows.

## Build workflows

Both workflows are started manually with `workflow_dispatch`. They run on GitHub-hosted `ubuntu-22.04` runners.

| Workflow | What it builds | Artifact | Files |
| --- | --- | --- | --- |
| **Kernel Image** | Kernel image only (`--only-kernel`) | `kernel-image` | `Image` |
| **KernelSU LKM Module** | Kernel modules (`--only-modules`) | `ksu-lkm-module` | `kernelsu.ko`, `nomount.ko` |

### Run a build

1. Open the repository's **Actions** tab.
2. Select **Kernel Image** and click **Run workflow**.
3. Select **KernelSU LKM Module** and click **Run workflow**.
4. Open each completed run and download its artifact from the **Artifacts** section.

The two workflows are intentionally separate. The image workflow produces a raw kernel `Image`; it does **not** package a `boot.img`, AnyKernel3 ZIP, or flashable installer. The LKM workflow produces the two `.ko` files listed above.

For a matching setup, use artifacts built from compatible source revisions and the same manifest state. The workflows synchronize their sources independently, so upstream branches can move between separate runs.

## Source layout

```text
.
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── build-image.yml
│       ├── build-lkm.yml
│       └── cleanup.yml
├── android_kernel_xiaomi_sm8450/
│   ├── build.sh
│   └── scripts/
│       └── setlocalversion
├── manifest.xml
└── README.md
```

The manifest assembles the AOSPA kernel build environment, including the kernel source, kernel build tools, device trees, and vendor modules. The local `android_kernel_xiaomi_sm8450/` directory provides the project-specific build script and `setlocalversion` override copied into the synchronized kernel tree by the workflows.

## Build script

The build script expects to run from the kernel source directory and requires a valid `.build.rc` containing `SRC_ROOT=<path-to-AOSPA-source>`. The GitHub Actions workflows create this file automatically.

Available modes:

| Command | Purpose |
| --- | --- |
| `./build.sh marble --only-kernel` | Build the kernel image |
| `./build.sh marble --only-modules` | Build kernel modules and stage module outputs |
| `./build.sh marble --only-dtb` | Build DTBs / DTBO |
| `./build.sh marble --only-config` | Generate the kernel configuration only |
| `./build.sh marble` | Run the full build: image, modules, and DTBs |
| `./build.sh marble --no-lto` | Disable Clang Full LTO for the build |
| `./build.sh marble --clean` | Clean the output directory before building |

The workflow currently uses only the image-only and modules-only modes.

## KernelSU and module notes

- KernelSU is configured with `CONFIG_KSU=m`; the LKM is delivered separately as `kernelsu.ko`.
- `nomount.ko` is a separate companion module. It is not the KernelSU manager or a replacement for KernelSU.
- The LKM must match the kernel it is intended to run with. Use the matching build outputs and follow the installation procedure supported by your KernelSU manager and device setup.
- This repository does **not** currently integrate SUSFS. The previous README mentioned SUSFS as broken, but the current workflows do not fetch or apply SUSFS patches.
- No Magisk integration or flashable ZIP packaging is configured here.

## Cleanup workflow

The **Cleanup Workflow Runs** workflow can be started manually from the Actions tab. It supports:

- `keep`: number of newest completed workflow runs to retain (default: `3`).
- `mode=all-finished`: delete completed runs beyond the retention window.
- `mode=failed-only`: delete failed or non-success completed runs beyond the retention window, while skipping successful runs.

This workflow deletes GitHub Actions run history; it does not delete source code, releases, or build artifacts independently.

## Maintainer notes

A few improvements would make builds more reproducible and easier to debug:

1. **Pin KernelSU to a commit SHA.** The workflows currently install from the moving `main` branch. Pinning a revision ensures the image and LKM builds use the same KernelSU source.
2. **Fail when required modules are missing.** The build script currently prints an error if `kernelsu.ko` or `nomount.ko` cannot be found, but it does not explicitly stop the build at that point. A strict check before artifact upload would prevent incomplete artifacts from looking like successful builds.
3. **Share common workflow setup.** The two build workflows repeat most environment, Repo, and Clang setup steps. A reusable workflow or composite action could reduce duplication.
4. **Align the Python versions.** The image and LKM workflows currently request slightly different Python versions.
5. **Pin manifest revisions for release builds.** The manifest currently tracks named branches for several projects. Recording exact revisions for release builds would improve traceability.

These are recommendations only; the workflows have not been changed as part of this README update.

## Credits

- AOSPA ShadeDark kernel and build infrastructure contributors.
- [KernelSU](https://github.com/tiann/KernelSU) by its upstream maintainers.
- [NoMount](https://github.com/maxsteeel/nomount) by its upstream maintainers.
- The local build script retains the original copyright notice in the source file.

## Disclaimer

This project is provided for development and testing. Kernel builds, modules, and installation procedures can cause boot failures or data loss when used with an incompatible device, kernel, or ROM. Verify the target and keep a known-good recovery path before flashing or loading modules.
