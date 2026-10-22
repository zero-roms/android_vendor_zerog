#
# ZeroG version
#
# SPDX-License-Identifier: Apache-2.0
#
# ZEROG_BUILD is the device codename, set by the product makefile before this
# file is read. ZEROG_BUILDTYPE may be set in the environment: UNOFFICIAL
# (default, local builds), EXPERIMENTAL, or RELEASE.
#

# Included early by each product makefile (LineageOS's version string needs
# ZEROG_SEMVER) and again from common.mk; evaluate once.
ifndef ZEROG_VERSION_MK_INCLUDED
ZEROG_VERSION_MK_INCLUDED := true

ZEROG_VERSION_MAJOR := 0
ZEROG_VERSION_MINOR := 2
ZEROG_VERSION_PATCH := 0

ZEROG_BUILD_DATE := $(shell date -u +%Y%m%d)

ifndef ZEROG_BUILDTYPE
    ZEROG_BUILDTYPE := UNOFFICIAL
endif
ifeq ($(filter RELEASE EXPERIMENTAL UNOFFICIAL,$(ZEROG_BUILDTYPE)),)
    ZEROG_BUILDTYPE := UNOFFICIAL
endif

ZEROG_SEMVER  := $(ZEROG_VERSION_MAJOR).$(ZEROG_VERSION_MINOR).$(ZEROG_VERSION_PATCH)
ZEROG_VERSION := $(ZEROG_SEMVER)-$(ZEROG_BUILD_DATE)-$(ZEROG_BUILDTYPE)-$(ZEROG_BUILD)

endif # ZEROG_VERSION_MK_INCLUDED
