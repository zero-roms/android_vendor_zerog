#
# ZeroG package target
#
# SPDX-License-Identifier: Apache-2.0
#
# `m zerog` builds the OTA zip and copies it as ZeroG-<version>.zip next to
# LineageOS's lineage-*.zip. A copy, not a hard link: the OTA tool rewrites its
# output file in place, so a link made by an earlier build would silently take
# on the next build's bytes (seen 22 October 2026 with 0.1.0 and 0.2.0).
#

ifneq ($(filter zerog_%,$(TARGET_PRODUCT)),)

ZEROG_TARGET_PACKAGE := $(PRODUCT_OUT)/ZeroG-$(ZEROG_VERSION).zip

.PHONY: zerog
zerog: $(INTERNAL_OTA_PACKAGE_TARGET) $(DEFAULT_GOAL)
	$(hide) rm -f $(ZEROG_TARGET_PACKAGE)
	$(hide) cp $(INTERNAL_OTA_PACKAGE_TARGET) $(ZEROG_TARGET_PACKAGE)
	$(hide) $(SHA256) $(ZEROG_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(ZEROG_TARGET_PACKAGE).sha256sum
	@echo "ZeroG package: $(ZEROG_TARGET_PACKAGE)" >&2

endif
