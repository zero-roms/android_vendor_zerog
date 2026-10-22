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

# Apps removed from the LineageOS set (see ROM_PLAN.md cut list).
PRODUCT_PACKAGES += \
    ZeroGRemovedPackages
