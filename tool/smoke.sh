#!/usr/bin/env bash
# Launches the release APK on an emulator, exercises scrolling and navigation,
# and records screenshots, logcat, ANR traces and frame stats into ./report.
set -u
R=report; mkdir -p $R
# Every adb call gets a timeout so a hung emulator still produces a report instead of eating the job.
adb() { timeout 60 command adb "$@"; }
PKG=com.hijabstyle.app
shot() { adb exec-out screencap -p > "$R/$1.png"; }
swipe_up() { adb shell input swipe 540 1700 540 700 250; sleep 1.2; }
swipe_down() { adb shell input swipe 540 700 540 1700 250; sleep 1.2; }
# Tap the first node whose content-desc/text matches $1 (Flutter semantics are visible to uiautomator).
tap() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb shell cat /sdcard/ui.xml > "$R/ui-last.xml"
  local b; b=$(python3 - "$1" "$R/ui-last.xml" <<'PY'
import re,sys
pat,f=sys.argv[1],sys.argv[2]
x=open(f,encoding='utf-8',errors='ignore').read()
for n in re.finditer(r'<node [^>]*>',x):
    s=n.group(0)
    d=' '.join(re.findall(r'(?:content-desc|text)="([^"]*)"',s))
    if re.search(pat,d):
        m=re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',s)
        if m:
            a=list(map(int,m.groups())); print((a[0]+a[2])//2,(a[1]+a[3])//2); break
PY
)
  echo "tap '$1' -> ${b:-NOT FOUND}" >> $R/steps.txt
  [ -n "$b" ] && adb shell input tap $b && sleep 2.5
}
alive() { echo "$1: pid=$(adb shell pidof $PKG) focus=$(adb shell dumpsys window | grep -m1 mCurrentFocus)" >> $R/steps.txt; }

adb shell settings put global window_animation_scale 1
adb install -r smoke.apk > $R/install.txt 2>&1
adb logcat -c
# Stream logcat from the start so logs survive even if the device stops answering later.
command adb logcat -v time > $R/logcat-stream.txt 2>&1 &
adb shell am start -W -n $PKG/com.hijabstyle.hijab_style.MainActivity > $R/start.txt 2>&1
sleep 6; shot 00-launch-6s
sleep 14
alive launch; shot 01-launch
for i in 1 2 3 4 5 6; do swipe_up; done
alive scrolled; shot 02-scrolled
for i in 1 2 3; do swipe_down; done
shot 03-back-up
tap 'Style of the day|لفة اليوم'; alive detail; shot 04-detail
swipe_up; swipe_up; shot 05-detail-scrolled
tap 'Start step by step|ابدئي خطوة بخطوة'; alive follow; shot 06-follow
tap '^(Next|التالي)'; tap '^(Next|التالي)'; shot 07-follow-next
adb shell input keyevent KEYCODE_BACK; sleep 2
adb shell input keyevent KEYCODE_BACK; sleep 2
alive after-back; shot 08-after-back
tap '^(Explore|استكشفي)'; swipe_up; swipe_up; alive explore; shot 09-explore
tap '^(Favorites|المفضلة)'; shot 10-favorites
tap '^(Settings|الإعدادات)'; swipe_up; alive settings; shot 11-settings
tap '^(Home|الرئيسية)'; swipe_up; swipe_up; swipe_up; shot 12-home-again
# Random input like Play's review robot: 4000 taps/swipes/back presses inside the app only.
adb shell monkey -p $PKG -s 2026 --throttle 120 --pct-syskeys 0 --pct-appswitch 0 --ignore-security-exceptions -v 4000 > $R/monkey.txt 2>&1
alive after-monkey; shot 13-after-monkey
tail -3 $R/monkey.txt >> $R/steps.txt
sleep 5
adb shell dumpsys gfxinfo $PKG > $R/gfxinfo.txt
adb logcat -d > $R/logcat.txt
grep -E "ANR in|Application Not Responding|FATAL EXCEPTION|E/flutter|Skipped [0-9]+ frames|Input dispatching timed out" $R/logcat.txt > $R/problems.txt || true
adb shell dumpsys activity anr > $R/anr.txt 2>&1 || true
adb shell ls /data/anr >> $R/anr.txt 2>&1 || true
echo done >> $R/steps.txt
# Fail the job when the app crashed or hung, so a broken release build can't look green.
if grep -qE "FATAL EXCEPTION|ANR in $PKG|E/flutter" $R/logcat.txt || grep -q "CRASH\|NOT RESPONDING" $R/monkey.txt || [ -z "$(adb shell pidof $PKG)" ]; then
  echo "SMOKE FAILED" >> $R/steps.txt; exit 1
fi
