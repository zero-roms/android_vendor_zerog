# ZeroG vendor repository

**ZeroG** (zero gravity, weightless) is the lightweight everyday Android ROM.
Its sibling project is **ZeroK**, the offline cold-wallet ROM. The names are
close: every download page, flashing guide and first-boot screen states which
ROM it is. This repository is ZeroG.

This repository is the *common layer*: everything that makes a build ZeroG
rather than plain AOSP or LineageOS. Name, version, branding, configuration,
default apps, and later the modes and privacy features.

It contains no hardware support. Device trees, kernels and vendor blobs are the
*device layer* and live in their own repositories, referenced from the manifest
at `zero-roms/android`.

## Layout

| Path | Purpose |
| --- | --- |
| `config/version.mk` | ZeroG version string and build type |
| `config/common.mk` | Properties and configuration shared by every ZeroG device |
| `products/AndroidProducts.mk` | Registers the ZeroG build targets with the build system |
| `products/<device>/zerog_<device>.mk` | One product makefile per phone; inherits the device layer, adds the common layer |
| `build/tasks/zerog_package.mk` | Names the output zip `ZeroG-<version>.zip` |

## Building

```
repo init -u https://github.com/zero-roms/android.git -b zerog-24.0 --git-lfs
repo sync
source build/envsetup.sh
lunch zerog_ginkgo-cp2a-userdebug
m zerog
```

Base: Android 17, built from the LineageOS `lineage-24.0` branches.

## Licence

Apache-2.0, the same as the LineageOS vendor repository this is modelled on.
