-- BloxBot — single-file bundle. Delta PC + Delta mobile primary.
-- Entry: paste `loadstring(game:HttpGet(<raw URL>))()` in any executor.

local ROOT = {
    core = {}, ui = {}, ui_vendor = {}, config = {}, game = {},
    mechanics = {}, models = {}, input = {}, comms = {},
}
local function mod(tbl, name, src) tbl[name] = { Source = src } end

--------------------------------------------------------------------
-- core/log.lua
--------------------------------------------------------------------
mod(ROOT.core, "log", [==[
local Log = {}
Log.__index = Log
local LEVELS = { debug = 10, info = 20, warn = 30, error = 40 }
function Log.new(prefix, level)
    local self = setmetatable({}, Log)
    self.prefix = prefix or "[BloxBot]"
    self.level = LEVELS[level or "info"] or LEVELS.info
    return self
end
function Log:_emit(tag, ...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    local msg = self.prefix .. " [" .. tag .. "] " .. table.concat(parts, " ")
    if tag == "error" then warn(msg) else print(msg) end
end
function Log:debug(...) if self.level <= LEVELS.debug then self:_emit("debug", ...) end end
function Log:info(...)  if self.level <= LEVELS.info  then self:_emit("info", ...)  end end
function Log:warn(...)  if self.level <= LEVELS.warn  then self:_emit("warn", ...)  end end
function Log:error(...) if self.level <= LEVELS.error then self:_emit("error", ...) end end
function Log:set_level(name) self.level = LEVELS[name] or self.level end
return Log
]==])

--------------------------------------------------------------------
-- core/result.lua
--------------------------------------------------------------------
mod(ROOT.core, "result", [==[
local Result = {}
Result.__index = Result
local function new(ok, value, code)
    return setmetatable({ ok = ok, value = value, code = code }, Result)
end
Result.ok  = function(v) return new(true, v, nil) end
Result.err = function(e, code) return new(false, e, code or "E_UNKNOWN") end
function Result:is_ok() return self.ok end
function Result:is_err() return not self.ok end
function Result:unwrap()
    if not self.ok then
        error(("Result:unwrap on err [%s]: %s"):format(tostring(self.code), tostring(self.value)), 2)
    end
    return self.value
end
function Result:unwrap_or(d) if self.ok then return self.value end return d end
function Result:err_or(d) if not self.ok then return self.value end return d end
return Result
]==])

--------------------------------------------------------------------
-- core/compat.lua
--------------------------------------------------------------------
mod(ROOT.core, "compat", [==[
local UIS = game:GetService("UserInputService")
local function safe(fn) local ok, v = pcall(fn) if ok then return v end return nil end
local function probe_executor_name()
    local c = {
        { "Delta",   function() return rawget(_G,"delta") or rawget(_G,"DeltaAPI") end },
        { "ArceusX", function() return rawget(_G,"Arceus") or rawget(_G,"ArceusX") end },
        { "Synapse", function() return rawget(_G,"syn") ~= nil end },
        { "Wave",    function() return rawget(_G,"wave") ~= nil end },
        { "Fluxus",  function() return rawget(_G,"fluxus") ~= nil end },
        { "Solara",  function() return rawget(_G,"solara") ~= nil end },
        { "AWP",     function() return rawget(_G,"awp") ~= nil end },
        { "Codex",   function() return rawget(_G,"codex") ~= nil end },
        { "Hydrogen",function() return rawget(_G,"Hydrogen") ~= nil end },
        { "Electron",function() return rawget(_G,"electron") ~= nil end },
        { "Swift",   function() return rawget(_G,"Swift") ~= nil end },
    }
    for _, p in ipairs(c) do if safe(p[2]) then return p[1] end end
    return "Unknown"
end
local compat = { has = {}, executor_name = "Unknown" }
compat.has.virtual_user = safe(function() return type(VirtualUser) == "table" and type(VirtualUser.Input) == "table" end) == true
compat.has.mousemoverel = safe(function() return type(mousemoverel) == "function" end) == true
compat.has.keypress     = safe(function() return type(keypress) == "function" end) == true
compat.has.gethui      = safe(function() return type(gethui) == "function" end) == true
compat.has.protectgui  = safe(function() return type(protectgui) == "function" end) == true
compat.has.syn_protect = safe(function() local s=rawget(_G,"syn") return type(s)=="table" and type(s.protect_gui)=="function" end) == true
compat.has.writefile  = safe(function() return type(writefile) == "function" end) == true
compat.has.readfile   = safe(function() return type(readfile) == "function" end) == true
compat.has.isfile     = safe(function() return type(isfile) == "function" end) == true
compat.has.makefolder = safe(function() return type(makefolder) == "function" end) == true
compat.has.request      = safe(function() return type(request) == "function" end) == true
compat.has.http_request = safe(function() return type(http_request) == "function" end) == true
compat.has.syn_request  = safe(function() local s=rawget(_G,"syn") return type(s)=="table" and type(s.request)=="function" end) == true
compat.has.drawing            = safe(function() return type(Drawing) == "table" end) == true
compat.has.queue_on_teleport  = safe(function() return type(queue_on_teleport) == "function" end) == true
compat.has.getcustomasset     = safe(function() return type(getcustomasset) == "function" end) == true
compat.is_synapse = rawget(_G,"syn") ~= nil
compat.is_delta   = (rawget(_G,"delta") ~= nil) or (rawget(_G,"DeltaAPI") ~= nil)
compat.is_mobile  = (UIS.TouchEnabled and not UIS.MouseEnabled)
compat.executor_name = probe_executor_name()
function compat.supports(f)
    local h = compat.has
    if f=="fileio"      then return h.writefile and h.readfile end
    if f=="http"        then return h.request or h.http_request or h.syn_request end
    if f=="ui_protect"  then return h.gethui or h.protectgui or h.syn_protect end
    if f=="pc_input"    then return h.virtual_user or (h.mousemoverel and h.keypress) end
    if f=="touch_input" then return h.virtual_user end
    return false
end
function compat.report()
    local out = {}
    local keys = {"virtual_user","mousemoverel","keypress","gethui","protectgui","syn_protect",
        "writefile","readfile","isfile","makefolder","request","http_request","syn_request",
        "drawing","queue_on_teleport","getcustomasset"}
    for _, k in ipairs(keys) do
        out[#out+1] = string.format("%-20s %s", k, self.has[k] and "OK" or "MISSING")
    end
    out[#out+1] = string.format("%-20s %s", "executor", self.executor_name)
    out[#out+1] = string.format("%-20s %s", "mobile", tostring(self.is_mobile))
    return table.concat(out, "\n")
end
return compat
]==])

--------------------------------------------------------------------
-- core/device.lua
--------------------------------------------------------------------
mod(ROOT.core, "device", [==[
local UIS = game:GetService("UserInputService")
local function vss()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize then return math.min(cam.ViewportSize.X, cam.ViewportSize.Y) end
    return 720
end
return function(compat, config)
    local d = { kind="pc", touch=false, short_side=720, low_power=false, frame_budget_ms=1.0 }
    d.touch = UIS.TouchEnabled and not UIS.MouseEnabled
    d.short_side = vss()
    local forced = config and config:get("force_device") or "auto"
    if forced=="pc" then d.kind="pc"
    elseif forced=="mobile" then d.kind="mobile"
    else d.kind = d.touch and "mobile" or "pc" end
    d.low_power = (d.short_side < 720) or (compat.is_delta and d.kind=="mobile")
    d.frame_budget_ms = config and (config:get("frame_budget_ms")
        or (d.kind=="mobile" and 2.0 or 1.0)) or (d.kind=="mobile" and 2.0 or 1.0)
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            d.short_side = vss(); d.low_power = d.short_side < 720
        end)
    end
    return d
end
]==])

--------------------------------------------------------------------
-- core/config.lua
--------------------------------------------------------------------
mod(ROOT.core, "config", [==[
local HttpService = game:GetService("HttpService")
local DEFAULTS = {
    ui_lib="native", theme="dark", force_device="auto",
    frame_budget_ms=nil, active_model="botimus_crime", active_mode="1v1",
    humanize_enabled=true, humanize_jitter=0.15, humanize_delay_ms=25,
    ui_bounds={x=100,y=100,w=620,h=460},
    backend="auto",
    webhook_url="",  -- FILL: Olivia's webhook (paste URL, or set at runtime)
    log_level="info",
}
local Config = {}
Config.__index = Config
function Config.new(compat, device, log)
    local self = setmetatable({}, Config)
    self._compat=compat; self._device=device; self._log=log; self._data={}
    self._persistent = compat.supports and compat.supports("fileio") or false
    for k,v in pairs(DEFAULTS) do self._data[k]=type(v)=="table" and self:_copy(v) or v end
    if self._data.frame_budget_ms==nil then self._data.frame_budget_ms=device.frame_budget_ms end
    if not self._persistent then log:warn("config: no filesystem — session-only") end
    return self
end
function Config:_copy(t) local o={} for k,v in pairs(t) do o[k]=type(v)=="table" and self:_copy(v) or v end return o end
function Config:get(k) if k==nil then return self:_copy(self._data) end return self._data[k] end
function Config:set(k,v)
    if k==nil then for kk,vv in pairs(v or {}) do self._data[kk]=vv end return true end
    self._data[k]=v; return true
end
function Config:reset()
    for k in pairs(self._data) do self._data[k]=nil end
    for k,v in pairs(DEFAULTS) do self._data[k]=type(v)=="table" and self:_copy(v) or v end
    if self._data.frame_budget_ms==nil then self._data.frame_budget_ms=self._device.frame_budget_ms end
end
function Config:save(path)
    if not self._persistent then self._log:warn("config: no fs") return false,"no fs" end
    path = path or "BloxBot/config.json"
    local ok,err = pcall(function()
        if makefolder and not isfolder("BloxBot") then makefolder("BloxBot") end
        writefile(path, HttpService:JSONEncode(self._data))
    end)
    if not ok then self._log:error("config save:", tostring(err)) return false,tostring(err) end
    return true
end
function Config:load(path)
    if not self._persistent then self._log:warn("config: no fs") return false,"no fs" end
    path = path or "BloxBot/config.json"
    local ok,data = pcall(function() if isfile and not isfile(path) then return nil end return readfile(path) end)
    if not ok or not data then return false,"no file" end
    local dok,dec = pcall(function() return HttpService:JSONDecode(data) end)
    if not dok or type(dec)~="table" then return false,"decode" end
    for k,v in pairs(dec) do self._data[k]=v end
    return true
end
return Config
]==])

--------------------------------------------------------------------
-- game/constants.lua
--------------------------------------------------------------------
mod(ROOT.game, "constants", [==[
return {
    service = {
        run_service="RunService", user_input="UserInputService",
        players="Players", workspace="Workspace",
        text_service="TextService", tween="TweenService", http="HttpService",
    },
    ball = { name="Ball", class="BasePart" },
    teams = { red="RedTeam", blue="BlueTeam" },
    arenas = { folder="Arenas", fallback="Workspace" },
    goal = { name="Goal", attr_team="Team" },
    boost_pads = { folder="BoostPads", attr_amount="Boost" },
    timing = {
        flip_reset_window=0.12, air_dribble_pop_window=0.08,
        musty_flick_window=0.15, pogo_window=0.20, preflip_lead=0.30,
    },
    input = {
        jump_key=Enum.KeyCode.Space, boost_key=Enum.KeyCode.LeftShift,
        roll_left=Enum.KeyCode.Q, roll_right=Enum.KeyCode.E,
    },
}
]==])

--------------------------------------------------------------------
-- game/reader.lua
--------------------------------------------------------------------
mod(ROOT.game, "reader", [==[
local Players = game:GetService("Players")
local function sg(fn, f) local ok,v=pcall(fn) if ok then return v end return f end
return function(constants, compat, log)
    local r = {}
    local function find_ball()
        return sg(function()
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and d.Name==constants.ball.name then return d end
            end
        end)
    end
    local function find_char()
        local lp = Players.LocalPlayer
        if not lp then return nil end
        return lp.Character
    end
    local function find_arena()
        return sg(function()
            return workspace:FindFirstChild(constants.arenas.folder)
                or workspace:FindFirstChild(constants.arenas.fallback)
        end)
    end
    function r.read()
        local s = { ok=true, missing={}, ball=find_ball(), char=find_char(), arena=find_arena(), now=os.clock() }
        if not s.ball then s.missing[#s.missing+1]="ball" end
        if not s.char then s.missing[#s.missing+1]="char" end
        if not s.arena then s.missing[#s.missing+1]="arena" end
        s.ok = #s.missing==0
        return s
    end
    function r.report()
        local s = r.read()
        local lines = {}
        for _,k in ipairs(s.missing) do lines[#lines+1]="MISSING "..k end
        if #lines==0 then lines[#lines+1]="all paths OK" end
        return table.concat(lines, "\n")
    end
    return r
end
]==])

--------------------------------------------------------------------
-- game/state.lua
--------------------------------------------------------------------
mod(ROOT.game, "state", [==[
return function(reader, constants, log)
    local s = {}
    function s.compose()
        local raw = reader.read()
        local gs = {
            now=raw.now, ball=raw.ball, char=raw.char,
            humanoid = raw.char and raw.char:FindFirstChildOfClass("Humanoid") or nil,
            root_part = raw.char and raw.char:FindFirstChild("HumanoidRootPart") or nil,
            missing=raw.missing, ok=raw.ok,
            ball_pos = raw.ball and raw.ball.Position or Vector3.zero,
            ball_vel = raw.ball and raw.ball.AssemblyLinearVelocity or Vector3.zero,
            my_pos = raw.char and raw.char:FindFirstChild("HumanoidRootPart")
                and raw.char.HumanoidRootPart.Position or Vector3.zero,
            my_vel = raw.char and raw.char:FindFirstChild("HumanoidRootPart")
                and raw.char.HumanoidRootPart.AssemblyLinearVelocity or Vector3.zero,
        }
        gs.dist_to_ball = (gs.ball_pos - gs.my_pos).Magnitude
        return gs
    end
    return s
end
]==])

--------------------------------------------------------------------
-- mechanics/*.lua
--------------------------------------------------------------------
mod(ROOT.mechanics, "aerial", [==[
return { name="aerial", compute=function(gs, opts)
    opts = opts or {}
    local reach = opts.reach or 40
    local dy = gs.ball_pos.Y - gs.my_pos.Y
    if gs.dist_to_ball > reach then return { jump=false, boost=false, move=Vector3.zero } end
    local m = (gs.ball_pos - gs.my_pos)
    if m.Magnitude > 0.01 then m = m.Unit end
    return { jump = dy > 5, boost = dy > 10, move = Vector3.new(m.X, math.max(0, m.Y), m.Z) }
end }
]==])

mod(ROOT.mechanics, "air_dribble", [==[
return { name="air_dribble", compute=function(gs, opts)
    opts = opts or {}
    local above = opts.above or 15
    local dy = gs.ball_pos.Y - gs.my_pos.Y
    if dy < -5 then return { pop=false, boost=false } end
    local h = (gs.ball_pos - gs.my_pos) * Vector3.new(1,0,1)
    return { pop = gs.dist_to_ball < 12 and dy < 20, boost = dy > above,
             drift = h.Magnitude > 0.01 and h.Unit or Vector3.zero }
end }
]==])

mod(ROOT.mechanics, "flip_reset", [==[
return { name="flip_reset", compute=function(gs, opts)
    opts = opts or {}
    local dy = gs.ball_pos.Y - gs.my_pos.Y
    return { trigger = gs.dist_to_ball < 6 and dy > -2 and dy < 6,
             window = opts.window or 0.12, roll = opts.roll or "auto" }
end }
]==])

mod(ROOT.mechanics, "musty_flick", [==[
return { name="musty_flick", compute=function(gs, opts)
    opts = opts or {}
    local above = gs.ball_pos.Y - gs.my_pos.Y
    return { trigger = above > 8 and above < 22 and gs.dist_to_ball < 10,
             window = opts.window or 0.15 }
end }
]==])

mod(ROOT.mechanics, "triple_pop", [==[
return { name="triple_pop", compute=function(gs, opts)
    opts = opts or {}
    return { pops_planned = opts.n or 3, aerial = gs.dist_to_ball < 30,
             boost = gs.ball_pos.Y > gs.my_pos.Y + 5 }
end }
]==])

mod(ROOT.mechanics, "pogo", [==[
return { name="pogo", compute=function(gs, opts)
    opts = opts or {}
    return { trigger = gs.ball_pos.Y > gs.my_pos.Y and gs.dist_to_ball < 18,
             window = opts.window or 0.20 }
end }
]==])

mod(ROOT.mechanics, "preflip", [==[
return { name="preflip", compute=function(gs, opts)
    opts = opts or {}
    local lead = opts.lead or 0.30
    return { predicted_ball = gs.ball_pos + gs.ball_vel * lead, lead = lead }
end }
]==])

mod(ROOT.mechanics, "demo_chase", [==[
return { name="demo_chase", compute=function(gs, opts)
    opts = opts or {}
    return { demo_score = 0, threshold = opts.threshold or 0.6 }
end }
]==])

--------------------------------------------------------------------
-- models/IModel.lua
--------------------------------------------------------------------
mod(ROOT.models, "IModel", [==[
local IModel = {}
IModel.__index = IModel
function IModel.new(opts) return setmetatable({ opts = opts or {} }, IModel) end
function IModel:name() return "" end
function IModel:on_tick(gs, intent) end
function IModel:reset() end
return IModel
]==])

--------------------------------------------------------------------
-- models/*.lua
--------------------------------------------------------------------
mod(ROOT.models, "botimus_crime", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={reset_window=0.12} }, { __index = IModel })
function M:name() return "botimus_crime" end
function M:on_tick(gs, i)
    local fr = mech.flip_reset.compute(gs, { window=self.opts.reset_window })
    if fr.trigger then i:queue({ flip_reset=true, window=fr.window }) end
    local ad = mech.air_dribble.compute(gs, {})
    if ad.pop then i:queue({ jump=true }) end
    if ad.boost then i:queue({ boost=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "nyx", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={roll_bias="auto"} }, { __index = IModel })
function M:name() return "nyx" end
function M:on_tick(gs, i)
    local ad = mech.air_dribble.compute(gs, {})
    if ad.pop then i:queue({ jump=true }) end
    if ad.boost then i:queue({ boost=true }) end
    if ad.drift and ad.drift.Magnitude > 0 then
        i:queue({ roll=self.opts.roll_bias, drift=ad.drift })
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "wolvot_v1", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={flip_reset_prob=0.25} }, { __index = IModel })
function M:name() return "wolvot_v1" end
function M:on_tick(gs, i)
    local pf = mech.preflip.compute(gs, { lead=0.30 })
    i:queue({ preflip=true, predicted=pf.predicted_ball })
    if math.random() < self.opts.flip_reset_prob then
        local fr = mech.flip_reset.compute(gs, {})
        if fr.trigger then i:queue({ flip_reset=true }) end
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "wolvot_v31", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={pops=3} }, { __index = IModel })
function M:name() return "wolvot_v31" end
function M:on_tick(gs, i)
    local tp = mech.triple_pop.compute(gs, { n=self.opts.pops })
    if tp.aerial then i:queue({ aerial=true, pops_planned=tp.pops_planned }) end
    if tp.boost then i:queue({ boost=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "wolvot_v4", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "wolvot_v4" end
function M:on_tick(gs, i)
    local fr = mech.flip_reset.compute(gs, {})
    if fr.trigger then i:queue({ flip_reset=true }) end
    local mf = mech.musty_flick.compute(gs, {})
    if mf.trigger then i:queue({ musty_flick=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "nox", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={resets=3} }, { __index = IModel })
function M:name() return "nox" end
function M:on_tick(gs, i)
    for _=1, self.opts.resets do
        local fr = mech.flip_reset.compute(gs, {})
        if fr.trigger then i:queue({ flip_reset=true }) end
    end
    local pg = mech.pogo.compute(gs, {})
    if pg.trigger then i:queue({ pogo=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "ripple", [==[
local IModel = require_IModel()
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "ripple" end
function M:on_tick(gs, i)
    -- FILL: awaiting behavior spec. Registered no-op.
end
function M:reset() end
return M
]==])

mod(ROOT.models, "mechanoid", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "mechanoid" end
function M:on_tick(gs, i)
    local ad = mech.air_dribble.compute(gs, {})
    if ad.pop then i:queue({ jump=true, roll="auto" }) end
    local fr = mech.flip_reset.compute(gs, {})
    if fr.trigger then i:queue({ flip_reset=true, roll="auto" }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "classybot", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "classybot" end
function M:on_tick(gs, i)
    if gs.dist_to_ball < 8 and gs.ball_pos.Y - gs.my_pos.Y < 5 then
        i:queue({ flick=true, ground_first=true })
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "galaxybot", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "galaxybot" end
function M:on_tick(gs, i)
    local fr = mech.flip_reset.compute(gs, {})
    if fr.trigger then i:queue({ flip_reset=true, arsenal=true }) end
    local mf = mech.musty_flick.compute(gs, {})
    if mf.trigger then i:queue({ musty_flick=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "chorusfruit", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={n=3} }, { __index = IModel })
function M:name() return "chorusfruit" end
function M:on_tick(gs, i)
    local tp = mech.triple_pop.compute(gs, { n=self.opts.n })
    if tp.aerial then i:queue({ aerial=true, pops_planned=tp.pops_planned }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "yukan_velo", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={reaction_ms=80, jitter_ms=30} }, { __index = IModel })
function M:name() return "yukan_velo" end
function M:on_tick(gs, i)
    local j = math.random() * self.opts.jitter_ms / 1000
    i:queue({ reaction_delay=self.opts.reaction_ms/1000 + j })
    local ad = mech.air_dribble.compute(gs, {})
    if ad.pop then i:queue({ jump=true }) end
    if math.random() < 0.10 then
        local fr = mech.flip_reset.compute(gs, {})
        if fr.trigger then i:queue({ flip_reset=true }) end
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "buttbot", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={} }, { __index = IModel })
function M:name() return "buttbot" end
function M:on_tick(gs, i)
    local tp = mech.triple_pop.compute(gs, { n=3 })
    if tp.aerial then i:queue({ aerial=true, pops_planned=3 }) end
    local fr = mech.flip_reset.compute(gs, {})
    if fr.trigger then i:queue({ flip_reset=true }) end
    local mf = mech.musty_flick.compute(gs, {})
    if mf.trigger then i:queue({ musty_flick=true }) end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "bliss", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={demo_threshold=0.6} }, { __index = IModel })
function M:name() return "bliss" end
function M:on_tick(gs, i)
    local dc = mech.demo_chase.compute(gs, { threshold=self.opts.demo_threshold })
    if dc.demo_score > dc.threshold then
        i:queue({ demo=true })
    else
        local fr = mech.flip_reset.compute(gs, {})
        if fr.trigger then i:queue({ flip_reset=true }) end
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

mod(ROOT.models, "yogie", [==[
local IModel = require_IModel(); local mech
local M = setmetatable({ opts={angle_margin=15} }, { __index = IModel })
function M:name() return "yogie" end
function M:on_tick(gs, i)
    local role = "rotator"
    if gs.ball_pos.Y > gs.my_pos.Y + 20 then role = "support" end
    if gs.dist_to_ball < 12 then role = "striker" end
    i:queue({ role=role })
    local pf = mech.preflip.compute(gs, { lead=0.30 })
    if role == "striker" then
        i:queue({ pass_first=false, predicted=pf.predicted_ball })
    else
        i:queue({ pass_first=true })
    end
end
function M:reset() end
function M:bind(m) mech = m end
return M
]==])

--------------------------------------------------------------------
-- models/registry.lua
--------------------------------------------------------------------
mod(ROOT.models, "registry", [==[
return function(modules, mech, log)
    local reg = {}
    local names = {"botimus_crime","nyx","wolvot_v1","wolvot_v31","wolvot_v4",
        "nox","ripple","mechanoid","classybot","galaxybot","chorusfruit",
        "yukan_velo","buttbot","bliss","yogie"}
    for _, n in ipairs(names) do
        local m = modules[n]
        if m then
            if m.bind then m:bind(mech) end
            reg[n] = m
        else
            log:warn("registry: missing " .. n)
        end
    end
    return reg
end
]==])

--------------------------------------------------------------------
-- input/intent.lua
--------------------------------------------------------------------
mod(ROOT.input, "intent", [==[
local Intent = {}
Intent.__index = Intent
function Intent.new() return setmetatable({ _q={}, _last={} }, Intent) end
function Intent:queue(t)
    if type(t) ~= "table" then return end
    self._q[#self._q+1] = t
    for k,v in pairs(t) do self._last[k]=v end
end
function Intent:drain() local q=self._q; self._q={}; return q end
function Intent:last() return self._last end
function Intent:clear() self._q={}; self._last={} end
return Intent
]==])

--------------------------------------------------------------------
-- input/humanize.lua
--------------------------------------------------------------------
mod(ROOT.input, "humanize", [==[
return function(config)
    local H = {}
    function H.delay_ms()
        if not config:get("humanize_enabled") then return 0 end
        return config:get("humanize_delay_ms") or 25
    end
    function H.wrap(fn)
        return function(...)
            local ok, err = pcall(fn, ...)
            if not ok then return nil, err end
            if H.delay_ms() > 0 then task.wait(H.delay_ms() / 1000) end
            return true
        end
    end
    return H
end
]==])

--------------------------------------------------------------------
-- input/virtual_user.lua
--------------------------------------------------------------------
mod(ROOT.input, "virtual_user", [==[
return function(compat, humanize, log)
    local VU = { name = "virtual_user" }
    if not compat.has.virtual_user then VU.available = false; return VU end
    VU.available = true
    function VU.apply(list)
        for _, item in ipairs(list) do
            humanize.wrap(function()
                if item.jump then
                    pcall(function() VirtualUser:SendKeyEvent(Enum.KeyCode.Space, true) end)
                    task.wait(0.05)
                    pcall(function() VirtualUser:SendKeyEvent(Enum.KeyCode.Space, false) end)
                end
                if item.boost then
                    pcall(function() VirtualUser:SendKeyEvent(Enum.KeyCode.LeftShift, true) end)
                    task.wait(0.15)
                    pcall(function() VirtualUser:SendKeyEvent(Enum.KeyCode.LeftShift, false) end)
                end
            end)()
        end
    end
    return VU
end
]==])

--------------------------------------------------------------------
-- input/mouse.lua
--------------------------------------------------------------------
mod(ROOT.input, "mouse", [==[
return function(compat, humanize, log)
    local M = { name = "mouse" }
    if not (compat.has.mousemoverel and compat.has.keypress) then M.available=false; return M end
    M.available = true
    function M.apply(list)
        for _, item in ipairs(list) do
            humanize.wrap(function()
                if item.jump then pcall(function() keypress(0x20) end) end
                if item.boost then pcall(function() keypress(0x10) end) end
            end)()
        end
    end
    return M
end
]==])

--------------------------------------------------------------------
-- input/touch.lua
--------------------------------------------------------------------
mod(ROOT.input, "touch", [==[
return function(compat, humanize, log)
    local T = { name = "touch" }
    if not compat.has.virtual_user then T.available=false; return T end
    T.available = true
    function T.apply(list)
        for _, item in ipairs(list) do
            humanize.wrap(function()
                if item.jump then
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
                        task.wait(0.05)
                        VirtualUser:Button1Up(Vector2.new(0.5, 0.5), workspace.CurrentCamera.CFrame)
                    end)
                end
            end)()
        end
    end
    return T
end
]==])

--------------------------------------------------------------------
-- input/select_backend.lua
--------------------------------------------------------------------
mod(ROOT.input, "select_backend", [==[
return function(compat, device, config, humanize, log)
    local want = config:get("backend") or "auto"
    local order
    if want == "auto" then
        if device.kind == "mobile" then order = { "touch", "virtual_user", "mouse" }
        else order = { "virtual_user", "mouse" } end
    else
        order = { want }
    end
    local maps = {
        virtual_user = function() return ROOT.input.virtual_user_fn end,
        mouse        = function() return ROOT.input.mouse_fn end,
        touch        = function() return ROOT.input.touch_fn end,
    }
    for _, name in ipairs(order) do
        local fac = maps[name] and maps[name]()
        if fac then
            local b = fac(compat, humanize, log)
            if b.available then log:info("input: "..name); return b end
        end
    end
    log:warn("input: no backend — dry-run")
    return { name="dry_run", available=false, apply=function() end }
end
]==])

--------------------------------------------------------------------
-- comms/sink.lua — SOLE outbound path. Posts to webhook_url.
--------------------------------------------------------------------
mod(ROOT.comms, "sink", [==[
-- comms/sink.lua
-- SOLE outbound path in BloxBot. Every send POSTs to webhook_url.
-- No alternate sinks. No print-only fallback. No payload stripping.
-- Missing request namespace -> log once, buffer, keep retrying.

return function(compat, config, log)
    local Sink = { queue = {}, _logged_no_http = false, _max_queue = 128 }

    local function has_http()
        return compat.has.syn_request or compat.has.request or compat.has.http_request
    end

    local function http_post(url, body)
        if compat.has.syn_request then
            local ok, r = pcall(function()
                return syn.request({
                    Url = url, Method = "POST", Body = body,
                    Headers = { ["Content-Type"] = "application/json" },
                })
            end)
            if ok and r and (r.StatusCode == 200 or r.StatusCode == 204) then
                return true
            end
            return false, r and r.StatusCode or "syn_request failed"
        elseif compat.has.request then
            local ok, r = pcall(function()
                return request({
                    Url = url, Method = "POST", Body = body,
                    Headers = { ["Content-Type"] = "application/json" },
                })
            end)
            if ok and r and (r.StatusCode == 200 or r.StatusCode == 204) then
                return true
            end
            return false, r and r.StatusCode or "request failed"
        elseif compat.has.http_request then
            local ok, r = pcall(function()
                return http_request({
                    Url = url, Method = "POST", Body = body,
                    Headers = { ["Content-Type"] = "application/json" },
                })
            end)
            if ok and r and (r.StatusCode == 200 or r.StatusCode == 204) then
                return true
            end
            return false, r and r.StatusCode or "http_request failed"
        end
        return false, "no http namespace"
    end

    local function url()
        return config:get("webhook_url")
    end

    local function push(level, msg)
        local body = '{"content":"[' .. level .. '] '
            .. tostring(msg):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
            .. '"}'
        Sink.queue[#Sink.queue + 1] = { body = body, tries = 0 }
        if #Sink.queue > Sink._max_queue then
            table.remove(Sink.queue, 1)
        end
    end

    local function drain()
        local u = url()
        if not u or u == "" then return end
        if not has_http() then
            if not Sink._logged_no_http then
                Sink._logged_no_http = true
                log:warn("comms: no request/syn.request/http_request — buffering sends")
            end
            return
        end
        local i = 1
        while i <= #Sink.queue do
            local item = Sink.queue[i]
            local ok, err = http_post(u, item.body)
            if ok then
                table.remove(Sink.queue, i)
            else
                item.tries = item.tries + 1
                if item.tries >= 5 then
                    log:warn("comms: dropping after 5 retries: " .. tostring(err))
                    table.remove(Sink.queue, i)
                else
                    i = i + 1
                    task.wait(2 ^ item.tries)
                end
            end
        end
    end

    function Sink.send(level, msg)
        local u = url()
        if not u or u == "" then
            log[level](msg)
            return
        end
        push(level, msg)
        task.spawn(drain)
    end

    function Sink.flush()
        task.spawn(drain)
    end

    return Sink
end
]==])

--------------------------------------------------------------------
-- ui/theme.lua
--------------------------------------------------------------------
mod(ROOT.ui, "theme", [==[
local THEMES = {
    dark = { bg=Color3.fromRGB(18,18,22), surface=Color3.fromRGB(28,28,34),
        surfaceHi=Color3.fromRGB(38,38,46), stroke=Color3.fromRGB(58,58,68),
        text=Color3.fromRGB(236,236,240), textDim=Color3.fromRGB(150,150,160),
        accent=Color3.fromRGB(120,170,255), accent2=Color3.fromRGB(255,110,180),
        ok=Color3.fromRGB(120,220,140), warn=Color3.fromRGB(255,190,90),
        err=Color3.fromRGB(255,100,100) },
    light = { bg=Color3.fromRGB(245,245,250), surface=Color3.fromRGB(255,255,255),
        surfaceHi=Color3.fromRGB(235,235,240), stroke=Color3.fromRGB(200,200,210),
        text=Color3.fromRGB(24,24,30), textDim=Color3.fromRGB(100,100,110),
        accent=Color3.fromRGB(60,120,240), accent2=Color3.fromRGB(220,60,140),
        ok=Color3.fromRGB(60,180,90), warn=Color3.fromRGB(230,160,40),
        err=Color3.fromRGB(220,60,60) },
}
local M = {
    FONT_HEAD=Enum.Font.GothamBold, FONT_BODY=Enum.Font.Gotham,
    CORNER_PANEL=UDim.new(0,8), CORNER_BUTTON=UDim.new(0,6),
    STROKE_WIDTH=1, STROKE_TRANSPARENCY=0.4, TWEEN_FAST=0.18,
    EASE=Enum.EasingStyle.Quad, EASE_DIR=Enum.EasingDirection.Out,
    _mode="dark",
}
function M.set_mode(n) if THEMES[n] then M._mode=n end end
function M.mode() return M._mode end
function M.tokens() return THEMES[M._mode] end
return M
]==])

--------------------------------------------------------------------
-- ui/vendor/native.lua
--------------------------------------------------------------------
mod(ROOT.ui_vendor, "native", [==[
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Native = {}
local function newInst(cls, props, parent)
    local inst = Instance.new(cls)
    for k,v in pairs(props or {}) do inst[k]=v end
    if parent then inst.Parent=parent end
    return inst
end
Native.newInst = newInst
function Native.corner(inst, r) return newInst("UICorner", { CornerRadius=r }, inst) end
function Native.stroke(inst, c, t, w) return newInst("UIStroke", { Color=c, Transparency=t, Thickness=w }, inst) end
function Native.padding(inst, px) return newInst("UIPadding", {
    PaddingTop=UDim.new(0,px), PaddingBottom=UDim.new(0,px),
    PaddingLeft=UDim.new(0,px), PaddingRight=UDim.new(0,px) }, inst) end
function Native.floating_button(parent, theme, onClick)
    local btn = newInst("TextButton", {
        Size=UDim2.fromOffset(48,48), Position=UDim2.new(1,-64,0.5,-24),
        BackgroundColor3=theme.accent, Text="B", TextColor3=theme.bg,
        Font=Enum.Font.GothamBold, TextSize=20, AutoButtonColor=false,
        AnchorPoint=Vector2.new(0,0), BorderSizePixel=0,
    }, parent)
    Native.corner(btn, UDim.new(0.5,0))
    btn.MouseButton1Click:Connect(onClick)
    if UIS.TouchEnabled then
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then onClick() end
        end)
    end
    return btn
end
function Native.protect_parent(compat, log)
    if compat.has.gethui then
        local ok,h = pcall(gethui)
        if ok and h then log:info("[BloxBot/ui] parent = gethui") return h, "gethui" end
    end
    if compat.has.protectgui then pcall(protectgui) end
    if compat.has.syn_protect then pcall(function() syn.protect_gui(syn) end) end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local can = pcall(function() local t=Instance.new("Folder"); t.Parent=cg; t:Destroy(); return true end)
        if can then log:info("[BloxBot/ui] parent = CoreGui") return cg, "coregui" end
    end
    log:warn("[BloxBot/ui] parent = PlayerGui")
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"), "playergui"
end
return Native
]==])

--------------------------------------------------------------------
-- ui/tabs.lua
--------------------------------------------------------------------
mod(ROOT.ui, "tabs", [==[
return function(ctx)
    local T = ctx.theme.tokens()
    local N = ctx.native
    local tabs = {}
    local function clear() if ctx.content_holder then ctx.content_holder:Destroy() end end
    local function page()
        local h = N.newInst("ScrollingFrame", {
            Name="Page", Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
        }, ctx.body)
        N.padding(h, 12); ctx.content_holder = h; return h
    end

    tabs.models = function()
        clear(); local p = page()
        local reg = ctx.Bot.registry
        local y = 0
        local modes = { "1v1", "2v2", "3v3" }
        for _, mode in ipairs(modes) do
            N.newInst("TextLabel", {
                Text=mode, Font=ctx.theme.FONT_HEAD, TextSize=14,
                TextColor3=T.accent, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,y),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, p)
            y = y + 28
            for name in pairs(reg) do
                local active = ctx.Bot.config:get("active_model") == name
                local row = N.newInst("TextButton", {
                    Text="  "..name.."  —  "..(active and "● active" or "○"),
                    Font=ctx.theme.FONT_BODY, TextSize=13, TextColor3=T.text,
                    BackgroundColor3=T.surface, Size=UDim2.new(1,0,0,36),
                    Position=UDim2.new(0,0,0,y),
                    TextXAlignment=Enum.TextXAlignment.Left,
                    BorderSizePixel=0, AutoButtonColor=false,
                }, p)
                N.corner(row, ctx.theme.CORNER_BUTTON)
                N.stroke(row, T.stroke, 0.4, 1)
                row.MouseButton1Click:Connect(function()
                    ctx.Bot.config:set("active_model", name)
                    ctx.Bot.active_model = reg[name]
                    tabs.models()
                end)
                y = y + 40
            end
        end
        p.CanvasSize = UDim2.new(0,0,0,y+20)
    end

    tabs.mechanics = function()
        clear(); local p = page()
        local y = 0
        for name in pairs(ctx.Bot.mechanics) do
            N.newInst("TextLabel", {
                Text=name, Font=ctx.theme.FONT_HEAD, TextSize=13,
                TextColor3=T.text, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,y),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, p)
            y = y + 32
        end
        p.CanvasSize = UDim2.new(0,0,0,y+20)
    end

    tabs.game = function()
        clear(); local p = page()
        local report = ctx.Bot.reader.report()
        N.newInst("TextLabel", {
            Text="reader status\n\n"..report, Font=ctx.theme.FONT_BODY,
            TextSize=13, TextColor3=T.textDim, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,200), Position=UDim2.new(0,0,0,0),
            TextXAlignment=Enum.TextXAlignment.Left,
            TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true,
        }, p)
        local btn = N.newInst("TextButton", {
            Text="Refresh", Font=ctx.theme.FONT_HEAD, TextSize=13,
            TextColor3=T.bg, BackgroundColor3=T.accent,
            Size=UDim2.fromOffset(100,32), Position=UDim2.new(0,0,0,220),
            BorderSizePixel=0, AutoButtonColor=false,
        }, p)
        N.corner(btn, ctx.theme.CORNER_BUTTON)
        btn.MouseButton1Click:Connect(function() tabs.game() end)
        p.CanvasSize = UDim2.new(0,0,0,280)
    end

    tabs.input = function()
        clear(); local p = page()
        local backend = ctx.Bot.input_backend
        N.newInst("TextLabel", {
            Text="backend: "..(backend and backend.name or "none")
                ..(backend and backend.available and " (available)" or " (unavailable)"),
            Font=ctx.theme.FONT_BODY, TextSize=13, TextColor3=T.text,
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,28),
            Position=UDim2.new(0,0,0,0), TextXAlignment=Enum.TextXAlignment.Left,
        }, p)
        local y = 40
        for _, opt in ipairs({ "auto", "virtual_user", "mouse", "touch" }) do
            local row = N.newInst("TextButton", {
                Text="  "..opt..(ctx.Bot.config:get("backend")==opt and "  ●" or ""),
                Font=ctx.theme.FONT_BODY, TextSize=13, TextColor3=T.text,
                BackgroundColor3=T.surface, Size=UDim2.new(1,0,0,32),
                Position=UDim2.new(0,0,0,y),
                TextXAlignment=Enum.TextXAlignment.Left,
                BorderSizePixel=0, AutoButtonColor=false,
            }, p)
            N.corner(row, ctx.theme.CORNER_BUTTON)
            N.stroke(row, T.stroke, 0.4, 1)
            row.MouseButton1Click:Connect(function()
                ctx.Bot.config:set("backend", opt); tabs.input()
            end)
            y = y + 36
        end
        p.CanvasSize = UDim2.new(0,0,0,y+20)
    end

    tabs.config = function()
        clear(); local p = page()
        local y = 0
        local function row(label, value, on_click)
            local btn = N.newInst("TextButton", {
                Text="  "..label.." : "..tostring(value),
                Font=ctx.theme.FONT_BODY, TextSize=13, TextColor3=T.text,
                BackgroundColor3=T.surface, Size=UDim2.new(1,0,0,32),
                Position=UDim2.new(0,0,0,y),
                TextXAlignment=Enum.TextXAlignment.Left,
                BorderSizePixel=0, AutoButtonColor=false,
            }, p)
            N.corner(btn, ctx.theme.CORNER_BUTTON)
            N.stroke(btn, T.stroke, 0.4, 1)
            if on_click then btn.MouseButton1Click:Connect(on_click) end
            y = y + 36
        end
        row("theme", ctx.Bot.config:get("theme"), function()
            local cur = ctx.Bot.config:get("theme")
            local nxt = cur == "dark" and "light" or "dark"
            ctx.Bot.config:set("theme", nxt); ctx.Bot.theme.set_mode(nxt)
            tabs.config()
        end)
        row("save config", "click", function() ctx.Bot.config:save() end)
        row("load config", "click", function() ctx.Bot.config:load() end)
        row("reset defaults", "click", function() ctx.Bot.config:reset(); tabs.config() end)
        row("compat check", "click", function()
            print("=== BloxBot compat ===\n"..ctx.Bot.compat.report())
        end)
        if not ctx.Bot.compat.supports("fileio") then
            N.newInst("TextLabel", {
                Text="session-only config (no filesystem)",
                Font=ctx.theme.FONT_BODY, TextSize=12, TextColor3=T.warn,
                BackgroundTransparency=1, Size=UDim2.new(1,0,0,20),
                Position=UDim2.new(0,0,0,y),
                TextXAlignment=Enum.TextXAlignment.Left,
            }, p)
            y = y + 24
        end
        p.CanvasSize = UDim2.new(0,0,0,y+20)
    end

    return tabs
end
]==])

--------------------------------------------------------------------
-- ui/overlay.lua
--------------------------------------------------------------------
mod(ROOT.ui, "overlay", [==[
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
return function(Bot)
    local theme = Bot.theme
    local log = Bot.log
    local compat = Bot.compat
    local config = Bot.config
    local device = Bot.device
    local Native = Bot._native
    local T = theme.tokens()

    local parent, pk = Native.protect_parent(compat, log)
    local screen = Native.newInst("ScreenGui", {
        Name="BloxBotUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        DisplayOrder=999999, IgnoreGuiInset=true,
    }, parent)

    local bounds = config:get("ui_bounds") or { x=100, y=100, w=620, h=460 }
    local function clamp(w,h)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1280,720)
        w = math.min(w, math.floor(vp.X*0.92))
        h = math.min(h, math.floor(vp.Y*0.92))
        if device.kind=="mobile" then w=math.max(w,320); h=math.max(h,400) end
        return w,h
    end
    bounds.w, bounds.h = clamp(bounds.w, bounds.h)

    local window = Native.newInst("Frame", {
        Name="Window", Size=UDim2.fromOffset(bounds.w, bounds.h),
        Position=UDim2.fromOffset(bounds.x, bounds.y),
        BackgroundColor3=T.bg, BorderSizePixel=0,
        ClipsDescendants=true, Active=true,
    }, screen)
    Native.corner(window, theme.CORNER_PANEL)
    Native.stroke(window, T.stroke, theme.STROKE_TRANSPARENCY, theme.STROKE_WIDTH)

    local topbar = Native.newInst("Frame", {
        Name="TopBar", Size=UDim2.new(1,0,0,40),
        BackgroundColor3=T.surface, BorderSizePixel=0,
    }, window)
    Native.corner(topbar, theme.CORNER_PANEL)

    Native.newInst("TextLabel", {
        Text="BloxBot", Font=theme.FONT_HEAD, TextSize=16,
        TextColor3=T.text, BackgroundTransparency=1,
        Position=UDim2.fromOffset(12,0), Size=UDim2.new(0,120,1,0),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, topbar)
    Native.newInst("TextLabel", {
        Text="v"..Bot.version, Font=theme.FONT_BODY, TextSize=12,
        TextColor3=T.textDim, BackgroundTransparency=1,
        Position=UDim2.fromOffset(88,0), Size=UDim2.new(0,160,1,0),
        TextXAlignment=Enum.TextXAlignment.Left,
    }, topbar)
    local minBtn = Native.newInst("TextButton", {
        Text="—", Font=theme.FONT_HEAD, TextSize=16, TextColor3=T.text,
        BackgroundColor3=T.surfaceHi, Size=UDim2.new(0,32,0,32),
        Position=UDim2.new(1,-76,0.5,-16), BorderSizePixel=0, AutoButtonColor=false,
    }, topbar)
    Native.corner(minBtn, theme.CORNER_BUTTON)
    local closeBtn = Native.newInst("TextButton", {
        Text="×", Font=theme.FONT_HEAD, TextSize=18, TextColor3=T.err,
        BackgroundColor3=T.surfaceHi, Size=UDim2.new(0,32,0,32),
        Position=UDim2.new(1,-38,0.5,-16), BorderSizePixel=0, AutoButtonColor=false,
    }, topbar)
    Native.corner(closeBtn, theme.CORNER_BUTTON)

    local compact = device.kind=="mobile" or device.short_side < 720
    local rail_w = compact and 56 or 140
    local rail = Native.newInst("Frame", {
        Name="Rail", Size=UDim2.new(0,rail_w,1,-68),
        Position=UDim2.fromOffset(0,40), BackgroundColor3=T.surface,
        BorderSizePixel=0,
    }, window)
    local tabs_frame = Native.newInst("Frame", {
        Name="Tabs", Size=UDim2.new(1,-rail_w,1,-68),
        Position=UDim2.fromOffset(rail_w,40), BackgroundColor3=T.bg,
        BorderSizePixel=0,
    }, window)
    local bottombar = Native.newInst("Frame", {
        Name="BottomBar", Size=UDim2.new(1,0,0,28),
        Position=UDim2.new(0,0,1,-28), BackgroundColor3=T.surface,
        BorderSizePixel=0,
    }, window)
    local status_pill = Native.newInst("TextLabel", {
        Text="  idle  ", Font=theme.FONT_BODY, TextSize=12,
        TextColor3=T.text, BackgroundColor3=T.surfaceHi,
        Size=UDim2.fromOffset(64,20), Position=UDim2.new(1,-132,0.5,-10),
        BorderSizePixel=0,
    }, bottombar)
    Native.corner(status_pill, UDim.new(0,10))
    local fps_label = Native.newInst("TextLabel", {
        Text="fps --  ms --", Font=theme.FONT_BODY, TextSize=11,
        TextColor3=T.textDim, BackgroundTransparency=1,
        Size=UDim2.fromOffset(120,20), Position=UDim2.new(1,-256,0.5,-10),
        TextXAlignment=Enum.TextXAlignment.Right,
    }, bottombar)

    local ctx = { theme=theme, native=Native, body=tabs_frame, config=config, Bot=Bot }
    local tabs = Bot._tabs(ctx)
    local order = { "models", "mechanics", "game", "input", "config" }
    local btns = {}
    local function select(name)
        for n,b in pairs(btns) do
            b.BackgroundColor3 = (n==name) and T.surfaceHi or T.surface
        end
        if tabs[name] then tabs[name]() end
    end
    for i, name in ipairs(order) do
        local b = Native.newInst("TextButton", {
            Text = compact and name:sub(1,1):upper() or ("  "..name),
            Font=theme.FONT_BODY, TextSize=13, TextColor3=T.text,
            BackgroundColor3=T.surface, Size=UDim2.new(1,0,0,36),
            Position=UDim2.new(0,0,0,(i-1)*40),
            TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            BorderSizePixel=0, AutoButtonColor=false,
        }, rail)
        b.MouseButton1Click:Connect(function() select(name) end)
        btns[name] = b
    end
    select("models")

    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=window.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement
            or input.UserInputType==Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                        startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if (input.UserInputType==Enum.UserInputType.MouseButton1
            or input.UserInputType==Enum.UserInputType.Touch) and dragging then
            dragging = false
            local pos, size = window.Position, window.Size
            config:set("ui_bounds", {
                x=pos.X.Offset, y=pos.Y.Offset, w=size.X.Offset, h=size.Y.Offset })
        end
    end)

    window.BackgroundTransparency = 1
    TweenService:Create(window, TweenInfo.new(0.15, theme.EASE, theme.EASE_DIR),
        { BackgroundTransparency = 0 }):Play()

    local floating_btn
    local function hide()
        window.Visible = false
        if device.kind=="mobile" and not floating_btn then
            floating_btn = Native.floating_button(screen, T, function()
                window.Visible = true
                if floating_btn then floating_btn:Destroy(); floating_btn=nil end
            end)
        end
    end
    local function show()
        window.Visible = true
        if floating_btn then floating_btn:Destroy(); floating_btn=nil end
    end
    minBtn.MouseButton1Click:Connect(hide)
    closeBtn.MouseButton1Click:Connect(hide)

    local o = {
        screen=screen, window=window, parent_kind=pk,
        show=show, hide=hide,
        set_status=function(t) status_pill.Text="  "..t.."  " end,
        set_fps=function(f,ms) fps_label.Text=string.format("fps %d  ms %.1f", f, ms) end,
    }
    function o.destroy() if screen then screen:Destroy() end end
    log:info("[BloxBot/ui] window up at "..tostring(pk))
    return o
end
]==])

--------------------------------------------------------------------
-- ui/hotkeys.lua
--------------------------------------------------------------------
mod(ROOT.ui, "hotkeys", [==[
return function(Bot)
    local UIS = game:GetService("UserInputService")
    local conns = {}
    conns[#conns+1] = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if Bot.ui then
                if Bot.ui.window and Bot.ui.window.Visible then Bot.ui.hide() else Bot.ui.show() end
            end
        elseif input.KeyCode == Enum.KeyCode.RightControl then
            Bot.paused = not Bot.paused
            if Bot.ui and Bot.ui.set_status then
                Bot.ui.set_status(Bot.paused and "paused" or "running")
            end
        elseif input.KeyCode == Enum.KeyCode.End then
            if Bot.heartbeat then Bot.heartbeat:stop() end
            if Bot.ui then Bot.ui.hide() end
        end
    end)
    return { destroy = function() for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end end }
end
]==])

--------------------------------------------------------------------
-- core/heartbeat.lua
--------------------------------------------------------------------
mod(ROOT.core, "heartbeat", [==[
local RunService = game:GetService("RunService")
return function(Bot)
    local hb = { running=false, overrun_streak=0 }
    local conn
    local function tick(dt)
        if not hb.running or Bot.paused then return end
        local t0 = os.clock()
        local budget = (Bot.config and Bot.config:get("frame_budget_ms") or 1.0) / 1000
        local ok, err = pcall(function()
            local gs = Bot.game_state.compose()
            local model = Bot.active_model
            if model then
                local it = Bot.intent
                it:clear()
                model:on_tick(gs, it)
                local d = it:drain()
                if d and #d > 0 and Bot.input_backend and Bot.input_backend.apply then
                    Bot.input_backend.apply(d)
                end
            end
        end)
        if not ok then
            hb.overrun_streak = 0
            if Bot.log then Bot.log:error("tick: "..tostring(err)) end
        end
        local spent = os.clock() - t0
        if spent > budget then
            hb.overrun_streak = hb.overrun_streak + 1
            if hb.overrun_streak > 20 and Bot.log then
                Bot.log:warn("heartbeat overrun x"..hb.overrun_streak)
                hb.overrun_streak = 0
            end
        else hb.overrun_streak = 0 end
        if Bot.ui and Bot.ui.set_fps then
            hb._f = (hb._f or 0) + 1
            if not hb._lt or os.clock() - hb._lt > 1 then
                local fps = hb._f; hb._f = 0; hb._lt = os.clock()
                Bot.ui.set_fps(fps, spent * 1000)
            end
        end
    end
    function hb:start()
        if self.running then return end
        self.running = true
        conn = RunService.Heartbeat:Connect(tick)
    end
    function hb:stop()
        self.running = false
        if conn then conn:Disconnect(); conn = nil end
    end
    return hb
end
]==])

--------------------------------------------------------------------
-- BOOT
--------------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.BloxBot and type(env.BloxBot.destroy) == "function" then
    pcall(env.BloxBot.destroy, env.BloxBot)
end

local function load_mod(inst, label)
    if type(inst) ~= "table" or type(inst.Source) ~= "string" then
        error("BloxBot: missing module " .. label)
    end
    local fn, err = loadstring(inst.Source, label)
    if not fn then error("BloxBot: load " .. label .. ": " .. tostring(err)) end
    local ok, m = pcall(fn)
    if not ok then error("BloxBot: run " .. label .. ": " .. tostring(m)) end
    return m
end

load_mod(ROOT.models, "models.IModel")
local function require_IModel()
    local base = {}; base.__index = base
    function base.new(opts) return setmetatable({ opts = opts or {} }, base) end
    function base:name() return "" end
    function base:on_tick() end
    function base:reset() end
    return base
end

local Bot = { root=ROOT, version="1.0.1", started_at=os.clock(), paused=false }

Bot.log = load_mod(ROOT.core, "core.log").new("[BloxBot]")
Bot.result = load_mod(ROOT.core, "core.result")
Bot.compat = load_mod(ROOT.core, "core.compat")

local Config = load_mod(ROOT.core, "core.config")
Bot.config = Config.new(Bot.compat, { frame_budget_ms=1.0 }, Bot.log)
Bot.device = load_mod(ROOT.core, "core.device")(Bot.compat, Bot.config)
Bot.config = Config.new(Bot.compat, Bot.device, Bot.log)

if Bot.compat.supports("fileio") then
    pcall(function()
        local p = "BloxBot/config.json"
        if isfile and isfile(p) then Bot.config:load(p) end
    end)
end

Bot.theme = load_mod(ROOT.ui, "ui.theme")
Bot.theme.set_mode(Bot.config:get("theme") or "dark")
Bot._native = load_mod(ROOT.ui_vendor, "ui.vendor.native")

local constants = load_mod(ROOT.game, "game.constants")
Bot.constants = constants
Bot.reader = load_mod(ROOT.game, "game.reader")(constants, Bot.compat, Bot.log)
Bot.game_state = load_mod(ROOT.game, "game.state")(Bot.reader, constants, Bot.log)

local mech = {}
for _, n in ipairs({ "aerial","air_dribble","flip_reset","musty_flick",
    "triple_pop","pogo","preflip","demo_chase" }) do
    mech[n] = load_mod(ROOT.mechanics, "mechanics."..n)
end
Bot.mechanics = mech

local models = {}
for _, n in ipairs({ "botimus_crime","nyx","wolvot_v1","wolvot_v31",
    "wolvot_v4","nox","ripple","mechanoid","classybot","galaxybot",
    "chorusfruit","yukan_velo","buttbot","bliss","yogie" }) do
    local src = ROOT.models[n].Source
    local chunk, err = loadstring("local require_IModel = ... ;\n"..src, "models."..n)
    if not chunk then error("model load "..n..": "..tostring(err)) end
    local ok, m = pcall(chunk, require_IModel)
    if not ok then error("model run "..n..": "..tostring(m)) end
    models[n] = m
end
Bot.registry = load_mod(ROOT.models, "models.registry")(models, mech, Bot.log)
local active_name = Bot.config:get("active_model") or "botimus_crime"
Bot.active_model = Bot.registry[active_name]

local Intent = load_mod(ROOT.input, "input.intent")
Bot.intent = Intent.new()
local humanize = load_mod(ROOT.input, "input.humanize")(Bot.config)
Bot.humanize = humanize
ROOT.input.virtual_user_fn = load_mod(ROOT.input, "input.virtual_user")
ROOT.input.mouse_fn = load_mod(ROOT.input, "input.mouse")
ROOT.input.touch_fn = load_mod(ROOT.input, "input.touch")
Bot.input_backend = load_mod(ROOT.input, "input.select_backend")(
    Bot.compat, Bot.device, Bot.config, humanize, Bot.log)

Bot.comms = load_mod(ROOT.comms, "comms.sink")(Bot.compat, Bot.config, Bot.log)

-- flush loop: re-drains webhook queue once http namespace appears
task.spawn(function()
    while true do task.wait(10); pcall(Bot.comms.flush) end
end)

Bot._tabs = load_mod(ROOT.ui, "ui.tabs")
local ok_ui, ui_or_err = pcall(load_mod(ROOT.ui, "ui.overlay"), Bot)
if not ok_ui then error("BloxBot: ui overlay: "..tostring(ui_or_err)) end
Bot.ui = ui_or_err
if not Bot.device.touch then
    pcall(function() Bot.hotkeys = load_mod(ROOT.ui, "ui.hotkeys")(Bot) end)
end
Bot.ui.set_status("running")

Bot.heartbeat = load_mod(ROOT.core, "core.heartbeat")(Bot)
Bot.heartbeat:start()

function Bot:destroy()
    if self.heartbeat then pcall(function() self.heartbeat:stop() end) end
    if self.hotkeys and self.hotkeys.destroy then pcall(self.hotkeys.destroy) end
    if self.ui and self.ui.destroy then pcall(self.ui.destroy, self.ui) end
end

local function cleanup_fn()
    if Bot and Bot.destroy then pcall(Bot.destroy, Bot) end
end
if Bot.compat.has.queue_on_teleport then
    pcall(queue_on_teleport, cleanup_fn)
else
    local be = Instance.new("BindableEvent")
    be.Event:Connect(cleanup_fn)
    Bot._cleanup_bindable = be
end

env.BloxBot = Bot
Bot.log:info("boot complete — BloxBot "..Bot.version
    .." on "..Bot.compat.executor_name.." ("..Bot.device.kind..")")
return Bot