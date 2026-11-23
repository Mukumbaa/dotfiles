#!/usr/bin/env lua

-- Durata massima degli appunti: 3 ore (10800 secondi). Cambia il "3" se vuoi altre durate.
local DEFAULT_TTL_SECONDS = 2 * 3600

local home = os.getenv("HOME")
if not home then os.exit(1) end

local cache_dir = home .. "/.cache/cliphist"
local ttl_file = cache_dir .. "/ttl.tsv"
local thumb_dir = "/tmp/qs_clip_thumbs"

local mode = arg[1] or "list"
local ttl_seconds = tonumber(arg[2]) or DEFAULT_TTL_SECONDS

local function ensure_cache_dir()
    os.execute('mkdir -p "' .. cache_dir .. '"')
end

-- =========================================================================
-- MODALITÀ 1: STORE (chiamata da wl-paste quando copi qualcosa)
-- =========================================================================
if mode == "store" then
    local p_before = io.popen("cliphist list 2>/dev/null | head -n1")
    local line_before = p_before and p_before:read("*l") or ""
    if p_before then p_before:close() end
    local id_before = line_before:match("^(%d+)\t")

    -- Esegue cliphist store ereditando stdin direttamente da wl-paste (testo e immagini)
    os.execute("cliphist store")

    local p_after = io.popen("cliphist list 2>/dev/null | head -n1")
    local line_after = p_after and p_after:read("*l") or ""
    if p_after then p_after:close() end
    local id_after = line_after:match("^(%d+)\t")

    if id_after and id_after ~= id_before then
        local f = io.open(ttl_file, "a")
        if not f then
            ensure_cache_dir()
            f = io.open(ttl_file, "a")
        end
        if f then
            f:write(id_after .. "\t" .. os.time() .. "\n")
            f:close()
        end
    end
    os.exit(0)
end

-- =========================================================================
-- MODALITÀ 2: PRUNE / LIST (pulisce gli scaduti ed eventualmente stampa la lista)
-- =========================================================================
local now = os.time()
local timestamps = {}

local f = io.open(ttl_file, "r")
if f then
    for line in f:lines() do
        local id, ts = line:match("^(%d+)\t(%d+)")
        if id and ts then
            timestamps[id] = tonumber(ts)
        end
    end
    f:close()
end

local entries = {}
local p = io.popen("cliphist list 2>/dev/null")
if p then
    for line in p:lines() do
        local id = line:match("^(%d+)\t")
        if id then
            table.insert(entries, { id = id, line = line })
        end
    end
    p:close()
end

local kept_timestamps = {}
local expired_ids = {}
local valid_lines = {}

for _, item in ipairs(entries) do
    -- Se una voce preesistente non aveva timestamp, parte il conteggio da ora
    local ts = timestamps[item.id] or now
    if (now - ts) >= ttl_seconds then
        table.insert(expired_ids, item.id)
    else
        table.insert(kept_timestamps, item.id .. "\t" .. ts)
        if mode == "list" then
            table.insert(valid_lines, item.line)
        end
    end
end

-- Elimina da cliphist e da /tmp/qs_clip_thumbs le voci scadute
if #expired_ids > 0 then
    local rm_patterns = {}
    for _, eid in ipairs(expired_ids) do
        local d = io.popen("cliphist delete 2>/dev/null", "w")
        if d then
            d:write(eid .. "\t\n")
            d:close()
        end
        table.insert(rm_patterns, thumb_dir .. "/" .. eid .. ".*")
    end
    os.execute("rm -f " .. table.concat(rm_patterns, " ") .. " 2>/dev/null")
end

-- Aggiorna ttl.tsv in modo atomico (elimina anche vecchi ID non più esistenti)
local tmp_file = ttl_file .. ".tmp"
local wf = io.open(tmp_file, "w")
if not wf then
    ensure_cache_dir()
    wf = io.open(tmp_file, "w")
end
if wf then
    if #kept_timestamps > 0 then
        wf:write(table.concat(kept_timestamps, "\n") .. "\n")
    end
    wf:close()
    os.rename(tmp_file, ttl_file)
end

if mode == "list" then
    local count = 0
    for _, l in ipairs(valid_lines) do
        print(l)
        count = count + 1
        if count >= 150 then break end
    end
end
