APP_NAME := TopToDo
APP_PATH := dist/$(APP_NAME).app

.PHONY: app dmg run-app validate clean-app

app:
	./Scripts/build-app.sh

dmg:
	./Scripts/build-dmg.sh

run-app: app
	open "$(APP_PATH)"

validate:
	swift run TopToDoValidation
	swift build --product TopToDo

clean-app:
	rm -rf dist
