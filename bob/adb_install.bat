::adb shell pm uninstall com.d954mas.game.defoldjam2023.dev
adb install -r ".\releases\dev\playmarket\DefoldJam2023 Dev\DefoldJam2023 Dev.apk"
adb shell monkey -p com.d954mas.game.defoldjam2023.dev -c android.intent.category.LAUNCHER 1
pause
