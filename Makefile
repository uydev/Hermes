.PHONY: dev backend-install backend-dev backend-test backend-build client-build client-build-release package clean

# Simple portfolio-friendly commands.
# Requires: Node 18+, Xcode, and (optionally) Docker.

dev:
	@echo "Starting backend (dev)" 
	@$(MAKE) -s backend-dev

backend-install:
	cd backend && npm install

backend-dev:
	cd backend && npm run dev

backend-test:
	cd backend && npm test

backend-build:
	cd backend && npm run build

client-build:
	xcodebuild -project client-macos/Hermes.xcodeproj -scheme Hermes -configuration Debug -destination 'platform=macOS' build

client-build-release:
	xcodebuild -project client-macos/Hermes.xcodeproj -scheme Hermes -configuration Release -destination 'platform=macOS' build

package:
	bash scripts/package-macos.sh

clean:
	rm -rf dist
