# AOSPA KernelSU LKM Builder — Marble

[![KernelSU LKM](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml/badge.svg?branch=main)](https://github.com/tekocheng/aospa-lkm-builder/actions/workflows/build-lkm.yml)

A GitHub Actions builder for **KernelSU and NoMount Loadable Kernel Modules (LKM)** on the AOSPA kernel for **Xiaomi marble** (POCO F5 / Redmi Note 12 Turbo).

This repository is intentionally LKM-only. It does not build or package a kernel Image, boot.img, AnyKernel3 ZIP, or flashable kernel installer.

## KernelSU variants

Run **Actions → KernelSU LKM → Run workflow**, select the AOSPA source branch (`calcite` by default, `beryl`, or `vauxite`), then select one KernelSU variant. **KernelSU-Official is the default**; the other four are optional alternatives:

| Workflow choice | Upstream repository | Tracked branch | Build output |
| --- | --- | --- | --- |
| `KernelSU-Official` **(default)** | [tiann/KernelSU](https://github.com/tiann/KernelSU) | `main` | `kernelsu.ko` |
| `KOWX712` | [KOWX712/KernelSU](https://github.com/KOWX712/KernelSU) | `master` | `kernelsu.ko` |
| `BakaSU` | [Baka-SU/BakaSU](https://github.com/Baka-SU/BakaSU) | `main` | `kernelsu.ko` |
| `SukiSU-Ultra` | [SukiSU-Ultra/SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) | `main` | `kernelsu.ko` |
| `KernelSU-Next` | [KernelSU-Next/KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) | `dev` | `kernelsu.ko` |

Each choice is mapped to a reviewed commit SHA in the workflow. The setup script checks out that exact revision instead of silently building whatever happens to be at the branch head. To update a variant, review the upstream changes and update its SHA in the **Resolve KernelSU variant** step.

> These are alternative KernelSU implementations. Build and use only one variant at a time; do not mix their kernel modules or manager applications.

## NoMount companion LKM

NoMount is built as a **companion LKM** in the same run as the selected KernelSU variant. It is not another KernelSU choice and does not replace KernelSU. The workflow pins [maxsteeel/nomount](https://github.com/maxsteeel/nomount) to commit `bf1847f98fed382369c43bfd652cd93774b9b8e3`, applies its kernel setup, enables `CONFIG_NOMOUNT=m`, and produces `nomount.ko` alongside `kernelsu.ko`.

Both modules are required outputs. The job fails when either module is absent, empty, or its expected kernel configuration is not enabled.

## Run a build

1. Open the repository's **Actions** tab.
2. Select **KernelSU LKM**.
3. Click **Run workflow**.
4. Choose `beryl` or `vauxite` as the AOSPA source branch.
6. Choose the desired KernelSU variant.
5. Wait for the job to finish and download its artifact.

The artifact name includes the selected variant, for example `kernelsu-lkm-KOWX712`.

Each artifact contains:

- `kernelsu.ko` — the selected KernelSU LKM.
- `nomount.ko` — the pinned NoMount companion LKM.
- `build-info.txt` — build type, selected variant, exact KernelSU commit, selected AOSPA branch, builder commit, toolchain, and source revisions.
- `resolved-manifest.xml` — exact Repo project revisions synchronized for that run.

## Build environment

- Device target: `marble`.
- Manifest: [tekocheng/aospa-kernel](https://github.com/tekocheng/aospa-kernel).
- Kernel source: [aospa-shadedark/android_kernel_xiaomi_sm8450](https://github.com/aospa-shadedark/android_kernel_xiaomi_sm8450), selectable branch `calcite` (default), `beryl`, or `vauxite`.
- Marble device kernel tree: [aospa-shadedark/android_device_xiaomi_marble-kernel](https://github.com/aospa-shadedark/android_device_xiaomi_marble-kernel), synced on the same selected branch (`uvite`, `beryl`, or `vauxite`).
- Runner: GitHub-hosted Ubuntu 22.04.
- Compiler: Clang `clang-r596125`.
- Python: `3.12`.
- Build mode: `./build.sh marble --only-modules`.
- KernelSU config: `CONFIG_KSU=m`.
- NoMount config: `CONFIG_NOMOUNT=m`.
- Clang is cached between runs; common setup and Repo synchronization are maintained in a local composite action.

The workflow validates that both `out/kernelsu.ko` and `out/nomount.ko` exist and are non-empty, and checks that both `CONFIG_KSU=m` and `CONFIG_NOMOUNT=m` are enabled before uploading. A missing module or disabled configuration causes the job to fail.

## Source layout

```text
.
├── .github/
│   ├── actions/
│   │   └── setup-build/
│   │       └── action.yml
│   └── workflows/
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

## Compatibility notes

- An LKM is built against the kernel source and configuration synchronized during that workflow run. It is not a universal module.
- The workflow does not build the matching kernel Image. Use a compatible AOSPA marble kernel separately.
- Compare `build-info.txt` and `resolved-manifest.xml` with the kernel build you intend to use. If the kernel source, configuration, symbol versions, or relevant toolchain differ, rebuild the LKM against the matching source state.
- The five KernelSU variants are alternatives, not add-ons to install together. NoMount is built separately as the companion LKM for the selected variant.
- This repository builds the selected KernelSU LKM and NoMount LKM; it does not package manager APKs or flashable ZIPs.

## Updating variants

The workflow deliberately pins each upstream revision for repeatability. To update a variant:

1. Review the upstream repository and select a known-good commit.
2. Confirm its `kernel/setup.sh` supports selecting a commit SHA.
3. Update the corresponding repository, branch, and SHA in **Resolve KernelSU variant**.
4. Run the LKM workflow and inspect the complete build log and artifact metadata.

Do not automatically follow upstream branches in production builds: a branch update can change kernel integration and break compatibility without any changes in this builder.

## Cleanup workflow

**Cleanup Workflow Runs** can be started manually from Actions. It manages completed GitHub Actions run history according to its configured retention mode. It does not delete source code or releases.

## Credits

- AOSPA ShadeDark kernel and build infrastructure contributors.
- The maintainers of [KernelSU Official](https://github.com/tiann/KernelSU), [KOWX712/KernelSU](https://github.com/KOWX712/KernelSU), [BakaSU](https://github.com/Baka-SU/BakaSU), [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra), and [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next).
- [NoMount](https://github.com/maxsteeel/nomount) upstream maintainers.

## Disclaimer

For development and testing. Loading an incompatible kernel module can cause instability or boot problems. Verify device and kernel compatibility, keep a known-good recovery path, and make backups before making system-level changes.
