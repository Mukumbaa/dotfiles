#!/usr/bin/env lua

local app = arg[1]

os.execute("pkill -x " .. app)
os.execute("setsid uwsm-app -- " .. app .." >/dev/null 2>&1 &")
