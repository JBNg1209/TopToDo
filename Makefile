APP_NAME := TopToDo
APP_PATH := dist/$(APP_NAME).app

.PHONY: app architecture-check build check check-clt dmg doctor format-check run-app test ui-smoke validate clean-app

architecture-check:
	./Scripts/check-architecture.sh

build:
	swift build --product TopToDo

test:
	swift test

validate:
	swift run TopToDoValidation

format-check:
	xcrun swift-format lint --recursive Sources Tests

check: format-check architecture-check test validate build
	git diff --check

check-clt: format-check architecture-check validate build
	git diff --check

doctor:
	./Scripts/doctor.sh

app:
	./Scripts/build-app.sh

dmg:
	./Scripts/build-dmg.sh

run-app: app
	open "$(APP_PATH)"

ui-smoke: app
	./Scripts/ui-smoke.sh

clean-app:
	rm -rf dist
