#
# ZeroS build targets
#
# SPDX-License-Identifier: Apache-2.0
#
# One product makefile per supported phone, under products/<codename>/.
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/ginkgo/zeros_ginkgo.mk

COMMON_LUNCH_CHOICES := \
    zeros_ginkgo-cp2a-userdebug \
    zeros_ginkgo-cp2a-user
