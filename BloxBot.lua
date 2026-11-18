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
    backend="auto", webhook_url="", log_level="info",
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
        return config:get("humanize_delay_ms") or