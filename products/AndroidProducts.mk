#
# ZeroG build targets
#
# SPDX-License-Identifier: Apache-2.0
#
# One product makefile per supported phone, under products/<codename>/.
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/ginkgo/zerog_ginkgo.mk

COMMON_LUNCH_CHOICES := \
    zerog_ginkgo-cp2a-userdebug \
    zerog_ginkgo-cp2a-user
