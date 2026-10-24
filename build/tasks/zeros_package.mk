#
# ZeroS package target
#
# SPDX-License-Identifier: Apache-2.0
#
# `m zeros` builds the OTA zip and copies it as ZeroS-<version>.zip next to
# LineageOS's lineage-*.zip. A copy, not a hard link: the OTA tool rewrites its
# output file in place, so a link made by an earlier build would silently take
# on the next build's bytes (seen 22 October 2026 with 0.1.0 and 0.2.0).
#

ifneq ($(filter zeros_%,$(TARGET_PRODUCT)),)

ZEROS_TARGET_PACKAGE := $(PRODUCT_OUT)/ZeroS-$(ZEROS_VERSION).zip

.PHONY: zeros
zeros: $(INTERNAL_OTA_PACKAGE_TARGET) $(DEFAULT_GOAL)
	$(hide) rm -f $(ZEROS_TARGET_PACKAGE)
	$(hide) cp $(INTERNAL_OTA_PACKAGE_TARGET) $(ZEROS_TARGET_PACKAGE)
	$(hide) $(SHA256) $(ZEROS_TARGET_PACKAGE) | sed "s|$(PRODUCT_OUT)/||" > $(ZEROS_TARGET_PACKAGE).sha256sum
	@echo "ZeroS package: $(ZEROS_TARGET_PACKAGE)" >&2

endif
