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
    ro.zerog.display.version=ZeroG\ $(ZEROG_SEMVER)

# Reuse LineageOS's display slot so the About screen shows ZeroG without a
# framework change. Replaced by ZeroG's own About entries in Phase 4.
PRODUCT_SYSTEM_PROPERTIES += \
    ro.lineage.display.version=ZeroG\ $(ZEROG_VERSION)
