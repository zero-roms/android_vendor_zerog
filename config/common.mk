#
# ZeroS common configuration, inherited by every ZeroS product makefile.
#
# SPDX-License-Identifier: Apache-2.0
#
# Phase 1 skeleton: identity only. App set, tuning, modes and privacy features
# arrive in later phases, each as its own file included from here.
#

include vendor/zeros/config/version.mk

# Identity visible to apps and in Settings > About phone
PRODUCT_SYSTEM_PROPERTIES += \
    ro.zeros.version=$(ZEROS_VERSION) \
    ro.zeros.semver=$(ZEROS_SEMVER) \
    ro.zeros.build.date=$(ZEROS_BUILD_DATE) \
    ro.zeros.build.type=$(ZEROS_BUILDTYPE) \
    ro.zeros.device=$(ZEROS_BUILD) \
    ro.zeros.display.version=ZeroS-$(ZEROS_SEMVER)

# LineageOS writes ro.lineage.display.version into the product partition's
# build.prop, which loads after ours, and Android 17's build rejects a second
# definition. The About screen therefore gets ZeroS through LineageOS's own
# TARGET_UNOFFICIAL_BUILD_ID hook, set in each product makefile. A proper
# "ZeroS version" entry needs a Settings patch (Phase 3 branding).

# Boot animation: design B1 "orbit" in black, white and red (chosen 24 October
# 2026). LineageOS's bootanimation.zip module copies this file instead of
# generating its own (vendor/lineage/bootanimation, prebuilt_file hook); the
# dark-theme variant is a link to the same file. Rebuild with
# bootanimation/make-bootanimation.sh.
TARGET_BOOTANIMATION := vendor/zeros/bootanimation/bootanimation.zip

# Resource overlays shared by every ZeroS device
PRODUCT_PACKAGE_OVERLAYS += vendor/zeros/overlay

# Apps removed from the LineageOS set (see ROM_PLAN.md cut list).
PRODUCT_PACKAGES += \
    ZeroSRemovedPackages

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

# Google build (Phase 3A). Build with ZEROS_GAPPS=false for the vanilla
# variant without any Google software (Phase 3D).
ZEROS_GAPPS ?= true
ifeq ($(ZEROS_GAPPS),true)
$(call inherit-product, vendor/zeros/config/gapps.mk)
endif
