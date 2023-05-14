if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
cd ../

java -jar bob/bob.jar --settings bob/settings/release_game.project_settings --archive  --texture-compression true --with-symbols --variant debug --platform=js-web --bo bob/releases/release/web -brhtml bob/releases/release/web/report.html clean resolve build bundle 