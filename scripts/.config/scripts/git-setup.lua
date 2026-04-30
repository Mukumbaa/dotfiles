#!/usr/bin/env lua

-- Funzione per verificare se la stringa non è vuota dopo aver rimosso tutti gli spazi bianchi
local function not_empty_trimmed(str)
    return #str:gsub("%s", "") > 0
end

-- Nome Git
io.write("Git name: ")
local git_name = io.read()
if git_name and not_empty_trimmed(git_name) then
    os.execute('git config --global user.name "' .. git_name .. '"')
    print("Git name done: " .. git_name)
else
    print("Empty name")
end

-- Email Git
io.write("Git email: ")
local git_email = io.read()
if git_email and not_empty_trimmed(git_email) then
    os.execute('git config --global user.email "' .. git_email .. '"')
    print("Git email done: " .. git_email)
else
    print("Empty email")
end

-- Autenticazione GitHub CLI
os.execute("gh auth login")
