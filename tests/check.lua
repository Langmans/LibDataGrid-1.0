-- LibDataGrid's checks, run from the repository root with Lua 5.1:
--
--   lua tests/check.lua           lint, then the tests with the coverage check
--   lua tests/check.lua test      the tests; extra arguments go to busted, e.g.
--                                 `test --filter=options` (a partial run skips the coverage check)
--   lua tests/check.lua lint      StyLua format check, WoW Lua LS, then whether docs/api is current
--   lua tests/check.lua format    formats all Lua with StyLua
--   lua tests/check.lua libs      fetches Libs/ from the .pkgmeta externals
--   lua tests/check.lua docs      writes the API docs into docs/api (the pre-commit hook runs it)
--
-- busted, luacov and stylua are looked up next to the Lua interpreter running this script
-- (.lua/bin after tests/setup-lua.ps1), else on PATH (CI). Exits non-zero on any failure.

package.path = "./?.lua;" .. package.path
local sh = require("tests.sh")

-- The file that declares the library's MINOR.
local LIBRARY_FILE = "LibDataGrid-1.0.lua"

local useColor = not os.getenv("NO_COLOR")
local function paint(code)
    return function(text)
        return useColor and ("\27[" .. code .. "m" .. text .. "\27[0m") or text
    end
end
local green, red, yellow, bold = paint(32), paint(31), paint(33), paint(1)

local failed = false
local function report(ok, label)
    print(ok and green("ok - " .. label) or red("not ok - " .. label))
    if not ok then failed = true end
end

-- arg[-1] is the interpreter; its directory holds the tools a local setup installed.
local binDir = arg[-1] and arg[-1]:match("^(.*)[/\\][^/\\]+$")

---The command for a tool: the copy next to the interpreter if there is one, else its bare name.
---@param name string
---@return string
local function tool(name)
    for _, suffix in ipairs(sh.windows and { ".bat", ".exe" } or { "" }) do
        local path = binDir and (binDir .. "/" .. name .. suffix)
        if path and sh.exists(path) then return path end
    end
    return name
end

local function libs()
    if require("tests.libs").fetch() then print("Libs/ fetched from the .pkgmeta externals") end
end

---Totals from coverage/lcov.info, printed per file. On GitHub Actions the same table also goes
---to the run's summary page (GITHUB_STEP_SUMMARY). Returns the percentage.
---@return number
local function coverageReport()
    local text = sh.read("coverage/lcov.info")
    -- A file can come twice: once as the tests ran it (Providers/TomTom.lua), once from
    -- includeuntestedfiles under its Windows path (Providers\TomTom.lua, all zeros). Merged by
    -- name, a line counts as hit when either record hit it.
    ---@type string[], table<string, table<number, number>>
    local files, counts = {}, {}
    for record in text:gmatch("SF:.-end_of_record") do
        local file = record:match("^SF:([^\r\n]+)"):gsub("\\", "/")
        if not counts[file] then
            files[#files + 1] = file
            counts[file] = {}
        end
        local lines = counts[file]
        for line, count in record:gmatch("DA:(%d+),(%d+)") do
            local n = tonumber(line) --[[@as number]]
            lines[n] = math.max(lines[n] or 0, tonumber(count) --[[@as number]])
        end
    end
    local hit, total = 0, 0
    local rows = {}
    print(bold("\nCoverage (lines hit / executable):"))
    for _, file in ipairs(files) do
        local numbers = {}
        for n in pairs(counts[file]) do
            numbers[#numbers + 1] = n
        end
        table.sort(numbers)
        local lh, lf = 0, #numbers
        local missed = {}
        for _, n in ipairs(numbers) do
            if counts[file][n] > 0 then
                lh = lh + 1
            else
                missed[#missed + 1] = tostring(n)
            end
        end
        local pct = lf > 0 and 100 * lh / lf or 100
        local color = pct >= 100 and green or pct >= 90 and yellow or red
        local note = #missed > 0 and red("  missed: " .. table.concat(missed, ", ")) or ""
        print(("  %s  %3d/%-3d %s%s"):format(color(("%5.1f%%"):format(pct)), lh, lf, file, note))
        rows[#rows + 1] = ("| %s | %d/%d | %.1f%% | %s |"):format(file, lh, lf, pct, table.concat(missed, ", "))
        hit, total = hit + lh, total + lf
    end
    local pct = total > 0 and 100 * hit / total or 100
    print(("  %s  %d/%d total"):format((pct >= 100 and green or red)(("%5.1f%%"):format(pct)), hit, total))

    local summary = os.getenv("GITHUB_STEP_SUMMARY")
    if summary then
        local file = assert(io.open(summary, "a"))
        file:write(("## Line coverage: %.1f%% (%d/%d)\n\n"):format(pct, hit, total))
        file:write("| File | Lines | Coverage | Missed lines |\n|---|---|---|---|\n")
        file:write(table.concat(rows, "\n"), "\n\n")
        file:close()
    end
    return pct
end

---busted writes each test's place as classname='tests/x_spec.lua:27'. Report readers take a
---classname for a dotted class path and cannot find the file in it, so the file and line move
---to the file and line attributes JUnit readers use for annotations; the classname keeps the
---spec's name.
local function fixJunit()
    if not sh.exists("coverage/junit.xml") then return end
    local xml = sh.read("coverage/junit.xml"):gsub("classname='([^']-):(%d+)'", function(path, line)
        path = path:gsub("\\", "/")
        local name = path:match("([^/]+)%.lua$") or path
        return ("classname='%s' file='%s' line='%s'"):format(name, path, line)
    end)
    sh.write("coverage/junit.xml", xml)
end

local function test(extra)
    libs()
    sh.mkdir("coverage")
    os.remove("coverage/luacov.stats.out")
    local full = #extra == 0
    -- The JUnit report goes to coverage/junit.xml for CI; the terminal gets the usual output.
    local argv = { tool("busted"), "--Xoutput", "coverage/junit.xml" }
    if full then argv[#argv + 1] = "--coverage" end
    for _, a in ipairs(extra) do
        argv[#argv + 1] = a
    end
    report(sh.run(argv, true), "busted")
    fixJunit()
    -- Every executable line of the library's own files must run in some test. A partial run covers
    -- only part and is not held to it.
    if full and sh.exists("coverage/luacov.stats.out") then
        sh.run({ tool("luacov"), "-r", "lcov" })
        local pct = coverageReport()
        report(pct >= 100, ("line coverage %.1f%%, must be 100%%"):format(pct))
    end
end

---WoW Lua LS: WOWLUA_LS, else the newest copy of its VS Code extension.
---@return string? binary
---@return string label
local function findLanguageServer()
    local env = os.getenv("WOWLUA_LS")
    if env then return env, "WOWLUA_LS" end
    local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
    local extensions = home .. "/.vscode/extensions"
    local newest
    for _, name in ipairs(sh.list(extensions)) do
        local version = name:match("^tradeskillmaster%.wowlua%-ls%-([%d.]+)$")
        if version then
            local key = version:gsub("%d+", function(n)
                return ("%05d"):format(tonumber(n))
            end)
            if not newest or key > newest.key then newest = { key = key, name = name } end
        end
    end
    if not newest then return nil, "not installed" end
    local platform = sh.windows and "win32-x64/wowlua_ls.exe" or "linux-x64/wowlua_ls"
    return extensions .. "/" .. newest.name .. "/server/" .. platform, newest.name
end

-- Where the API docs go: generated by WoW Lua LS from the docblocks, never edited by hand.
local API_DOCS = "docs/api"

---The library's classes: every `---@class LibDataGrid...` in the annotations and in the files
---lib.xml loads. The LS's own stubs for other libraries (CallbackHandler) stay out of the docs.
---@return string[]
local function docClasses()
    local files = { "annotations/LibDataGrid.lua" }
    local xml = sh.read("lib.xml"):gsub("<!%-%-.-%-%->", "")
    for path in xml:gmatch('file="([^"]+)"') do
        files[#files + 1] = (path:gsub("\\", "/"))
    end
    local classes, seen = {}, {}
    for _, file in ipairs(files) do
        for name in sh.read(file):gmatch("%-%-%-@class (LibDataGrid%w*)") do
            if not seen[name] then
                seen[name] = true
                classes[#classes + 1] = name
            end
        end
    end
    table.sort(classes)
    return classes
end

---Writes the API docs into dir, emptied first. False when the LS failed.
---@param binary string
---@param dir string
---@return boolean
local function writeDocs(binary, dir)
    sh.rmtree(dir)
    local argv = { binary, "doc", "--out-dir", dir }
    for _, class in ipairs(docClasses()) do
        argv[#argv + 1] = "--class"
        argv[#argv + 1] = class
    end
    argv[#argv + 1] = "."
    local output, ok = sh.capture(argv)
    if not ok then io.write(output) end
    return ok
end

---Whether two folders of generated docs hold the same files with the same text, line endings
---aside; the files that differ.
---@param a string
---@param b string
---@return string[]
local function docsDiffer(a, b)
    local names, differ = {}, {}
    for _, dir in ipairs({ a, b }) do
        for _, name in ipairs(sh.list(dir)) do
            names[name] = true
        end
    end
    for name in pairs(names) do
        local function text(dir)
            local path = dir .. "/" .. name
            return sh.exists(path) and (sh.read(path):gsub("\r\n", "\n")) or nil
        end
        if text(a) ~= text(b) then differ[#differ + 1] = name end
    end
    table.sort(differ)
    return differ
end

---The docs command: writes docs/api. Used by the pre-commit hook (.githooks/pre-commit).
local function docs()
    local binary, label = findLanguageServer()
    if not binary or not sh.exists(binary) then
        report(false, "WoW Lua LS not found (" .. label .. "), cannot write the API docs")
        return
    end
    report(writeDocs(binary, API_DOCS), "API docs written to " .. API_DOCS)
end

---Part of lint: docs/api must be what the docblocks give now, so the docs cannot fall behind.
---@param binary string
local function checkDocs(binary)
    print(bold("# API docs"))
    local fresh = ".cache/api-docs"
    if not writeDocs(binary, fresh) then
        report(false, "API docs could not be generated")
        return
    end
    local differ = docsDiffer(fresh, API_DOCS)
    sh.rmtree(fresh)
    local ok = #differ == 0
    if not ok then print(red("  out of date: " .. table.concat(differ, ", "))) end
    report(ok, "API docs up to date (`lua tests/check.lua docs` writes them)")
end

local function lint()
    -- The LS reads the libraries' types from Libs/, so fetch them first.
    libs()
    print(bold("# StyLua"))
    report(sh.run({ tool("stylua"), "--check", "." }, true), "StyLua")

    local binary, label = findLanguageServer()
    print(bold("# WoW Lua LS (" .. label .. ")"))
    if not binary or not sh.exists(binary) then
        -- Without it the check is skipped locally, but under CI a skip would pass unnoticed.
        if os.getenv("CI") then
            report(false, "WoW Lua LS not found")
        else
            print(yellow("skip - WoW Lua LS: VS Code extension tradeskillmaster.wowlua-ls not found"))
        end
        return
    end
    local output, ok = sh.capture({ binary, "check", "." })
    io.write(output)
    report(ok, "WoW Lua LS")
    -- Every symbol must resolve to a type. README > Development says how to find one that does not.
    local coverage = tonumber(output:match("Type coverage:%s*([%d.]+)%%"))
    report(coverage == 100, ("type coverage %s%%, must be 100%%"):format(tostring(coverage)))
    checkDocs(binary)
end

---On a CI run for a tag (the Release workflow runs these checks first): the tag must be the
---library's MINOR. Any other run has no tag to check.
local function releaseTag()
    if os.getenv("GITHUB_REF_TYPE") ~= "tag" then return end
    local version = require("tests.version")
    local ok, message = version.checkTag(os.getenv("GITHUB_REF_NAME") or "", version.minor(LIBRARY_FILE))
    report(ok, message)
end

local command = arg[1] or "all"
local extra = { select(2, unpack(arg)) }
if command == "all" then
    releaseTag()
    lint()
    test({})
elseif command == "test" then
    test(extra)
elseif command == "lint" then
    lint()
elseif command == "format" then
    report(sh.run({ tool("stylua"), "." }, true), "StyLua format")
elseif command == "libs" then
    libs()
elseif command == "docs" then
    docs()
else
    print("unknown command: " .. command)
    failed = true
end
os.exit(failed and 1 or 0)
