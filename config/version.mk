#
# ZeroG version
#
# SPDX-License-Identifier: Apache-2.0
#
# ZEROG_BUILD is the device codename, set by the product makefile before this
# file is read. ZEROG_BUILDTYPE may be set in the environment: UNOFFICIAL
# (default, local builds), EXPERIMENTAL, or RELEASE.
#

ZEROG_VERSION_MAJOR := 0
ZEROG_VERSION_MINOR := 1
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
