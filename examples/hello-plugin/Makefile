ASC_CLI = ../..
BUILD = $(ASC_CLI)/.build/arm64-apple-macosx/debug
MODULES = $(ASC_CLI)/.build/debug/Modules
CHECKOUTS = $(ASC_CLI)/.build/checkouts
SOURCES = $(shell find Sources/HelloPlugin -name "*.swift")
OUTPUT = .build/HelloPlugin.plugin
PLUGIN_DIR = $(HOME)/.asc/plugins

.PHONY: build install clean

build:
	@echo "Building HelloPlugin.plugin..."
	@# Collect include paths
	$(eval INCLUDES := -I $(MODULES))
	$(eval INCLUDES += $(shell find "$(BUILD)" -maxdepth 1 -name "*.build" -not -name "*-tool.build" -type d | while read dir; do \
		if [ -f "$$dir/module.modulemap" ]; then echo "-I $$dir"; \
		elif [ -d "$$dir/include" ]; then echo "-I $$dir/include"; fi; \
	done))
	$(eval INCLUDES += $(shell find "$(CHECKOUTS)" -path "*/include" -type d 2>/dev/null | sed 's/^/-I /'))
	@rm -rf "$(OUTPUT)"
	@mkdir -p "$(OUTPUT)/ui"
	swiftc $(SOURCES) \
		-module-name HelloPlugin \
		-emit-library -o "$(OUTPUT)/HelloPlugin.dylib" \
		$(INCLUDES) \
		-Xlinker -undefined -Xlinker dynamic_lookup \
		-O \
		-target arm64-apple-macos14.0
	@cp plugin/manifest.json "$(OUTPUT)/manifest.json"
	@cp -r plugin/ui/* "$(OUTPUT)/ui/" 2>/dev/null || true
	@echo "Built: $(OUTPUT) ($$(du -sh "$(OUTPUT)/HelloPlugin.dylib" | cut -f1) dylib)"

install: build
	@mkdir -p "$(PLUGIN_DIR)"
	@rm -rf "$(PLUGIN_DIR)/HelloPlugin.plugin"
	@cp -r "$(OUTPUT)" "$(PLUGIN_DIR)/HelloPlugin.plugin"
	@echo "Installed to $(PLUGIN_DIR)/HelloPlugin.plugin"

clean:
	@rm -rf .build
	@rm -rf "$(PLUGIN_DIR)/HelloPlugin.plugin"
	@echo "Cleaned"
