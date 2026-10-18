#
# ZeroG for Xiaomi Redmi Note 8 (ginkgo)
#
# SPDX-License-Identifier: Apache-2.0
#
# The device layer (device/xiaomi/ginkgo, sm6125-common, kernel, blobs) is used
# unmodified. Everything ZeroG-specific comes from vendor/zerog.
#

ZEROG_BUILD := ginkgo

# Device layer, as LineageOS defines it
$(call inherit-product, device/xiaomi/ginkgo/lineage_ginkgo.mk)

# ZeroG common layer
$(call inherit-product, vendor/zerog/config/common.mk)

PRODUCT_NAME := zerog_ginkgo
