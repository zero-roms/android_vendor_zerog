#
# ZeroG common configuration, inherited by every ZeroG product makefile.
#
# SPDX-License-Identifier: Apache-2.0
#
# Phase 1 skeleton: identity only. App set, tuning, modes and privacy features
# arrive in later phases, each as its own file included from here.
#

include vendor/zerog/config/version.mk

# Identity visible to apps and in Settings > About phone
PRODUCT_SYSTEM_PROPERTIES += \
    ro.zerog.version=$(ZEROG_VERSION) \
    ro.zerog.semver=$(ZEROG_SEMVER) \
    ro.zerog.build.date=$(ZEROG_BUILD_DATE) \
    ro.zerog.build.type=$(ZEROG_BUILDTYPE) \
    ro.zerog.device=$(ZEROG_BUILD) \
    ro.zerog.display.version=ZeroG-$(ZEROG_SEMVER)

# LineageOS writes ro.lineage.display.version into the product partition's
# build.prop, which loads after ours, and Android 17's build rejects a second
# definition. The About screen therefore gets ZeroG through LineageOS's own
# TARGET_UNOFFICIAL_BUILD_ID hook, set in each product makefile. A proper
# "ZeroG version" entry needs a Settings patch (Phase 3 branding).

# Resource overlays shared by every ZeroG device
PRODUCT_PACKAGE_OVERLAYS += vendor/zerog/overlay

# Apps removed from the LineageOS set (see ROM_PLAN.md cut list).
PRODUCT_PACKAGES += \
    ZeroGRemovedPackages

# Third-party apps, built from source (prebuilt/apps/build-fossify.sh,
# prebuilt/apps/build-notallyx.sh)
PRODUCT_PACKAGES += \
    FossifyFileManager \
    FossifyGallery \
    NotallyX

# Third-party apps kept with their publishers' signatures; the APKs are not in
# git and are put in place by prebuilt/apps/fetch-prebuilts.sh. Cromite
# replaces Jelly.
PRODUCT_PACKAGES += \
    Cromite

# Google build (Phase 3A). Build with ZEROG_GAPPS=false for the vanilla
# variant without any Google software (Phase 3D).
ZEROG_GAPPS ?= true
ifeq ($(ZEROG_GAPPS),true)
$(call inherit-product, vendor/zerog/config/gapps.mk)
endif
