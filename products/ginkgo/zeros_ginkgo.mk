#
# ZeroS for Xiaomi Redmi Note 8 (ginkgo)
#
# SPDX-License-Identifier: Apache-2.0
#
# The device layer (device/xiaomi/ginkgo, sm6125-common, kernel, blobs) is used
# unmodified. Everything ZeroS-specific comes from vendor/zeros.
#

ZEROS_BUILD := ginkgo

# LineageOS's version string expects the device codename in LINEAGE_BUILD,
# which its `breakfast` helper exports. We use plain `lunch`, so set it here.
LINEAGE_BUILD := $(ZEROS_BUILD)

# ZeroS version, needed now: LineageOS's version.mk (read while inheriting the
# device below) appends TARGET_UNOFFICIAL_BUILD_ID to its version string, which
# is what Settings > About phone shows.
include vendor/zeros/config/version.mk
TARGET_UNOFFICIAL_BUILD_ID := ZeroS-$(ZEROS_SEMVER)

# Device layer, as LineageOS defines it
$(call inherit-product, device/xiaomi/ginkgo/lineage_ginkgo.mk)

# ZeroS common layer
$(call inherit-product, vendor/zeros/config/common.mk)

# ginkgo-only resource fixes (status bar insets for the rounded corners).
# Product overlays take precedence over the device tree's vendor overlays.
PRODUCT_PACKAGE_OVERLAYS += vendor/zeros/products/ginkgo/overlay

PRODUCT_NAME := zeros_ginkgo
