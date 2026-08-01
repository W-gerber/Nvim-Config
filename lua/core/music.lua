local M = {}

local uv = vim.uv or vim.loop

local state = {
  buf = nil,
  win = nil,
  width = 24,
  height = 3,
  winblend = 80,
  panel_position = "top-right",
  pending_query = false,
  setup_done = false,
  debug = vim.g.music_debug == 1,
  last_poll_attempt_ms = 0,
  -- Each poll spawns a PowerShell process that loads the WinRT type system —
  -- on the order of a few hundred milliseconds of CPU. The interval therefore
  -- starts at 10s and doubles up to 60s whenever there is no media session
  -- (see `adjust_poll_interval`), so an editor left open all day is not
  -- spawning a process every five seconds to learn nothing changed.
  poll_interval_ms = 10000,
  poll_interval_min_ms = 10000,
  poll_interval_max_ms = 60000,
  cache = {
    available = false,
    title = "No media session",
    artist = "Start Spotify or Apple Music",
    status = "Stopped",
    app = "",
    updated_at = 0,
  },
}

local DEFAULT_ERR_TIMEOUT = 5000

local function is_windows() return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 end

local function now_ms() return math.floor((uv.hrtime() or 0) / 1e6) end

local function decode_json(s)
  if not s or s == "" then
    return nil, "empty output"
  end
  local ok, parsed
  if vim.json and vim.json.decode then
    ok, parsed = pcall(vim.json.decode, s)
  else
    ok, parsed = pcall(vim.fn.json_decode, s)
  end
  if not ok then
    return nil, tostring(parsed)
  end
  return parsed, nil
end

local function debug_log(msg, payload)
  if not state.debug then
    return
  end

  local suffix = ""
  if payload ~= nil then
    local ok, encoded = pcall(
      function() return vim.json and vim.json.encode and vim.json.encode(payload) or vim.inspect(payload) end
    )
    suffix = ok and ("\n" .. encoded) or ("\n" .. tostring(payload))
  end

  vim.schedule(
    function()
      vim.notify("[MusicDebug] " .. tostring(msg) .. suffix, vim.log.levels.INFO, { title = "Music" })
    end
  )
end

local function warn(msg, extra)
  local full = tostring(msg)
  if extra and extra ~= "" then
    full = full .. "\n" .. tostring(extra)
  end
  vim.notify(full, vim.log.levels.WARN, { title = "Music", timeout = DEFAULT_ERR_TIMEOUT })
  debug_log("warn", { message = msg, extra = extra })
end

local function normalize_status(raw)
  local status = tostring(raw or "Unknown")
  local lower = status:lower()
  if lower:find("playing", 1, true) then
    return "Playing"
  end
  if lower:find("paused", 1, true) then
    return "Paused"
  end
  if lower:find("stopped", 1, true) then
    return "Stopped"
  end
  return status
end

local function status_icon(status)
  if status == "Playing" then
    return "▶"
  end
  if status == "Paused" then
    return "⏸"
  end
  if status == "Stopped" then
    return "■"
  end
  return "♪"
end

local WINHIGHLIGHT =
  "NormalFloat:MusicNormal,Normal:MusicNormal,FloatBorder:MusicBorder,FloatTitle:MusicBorder"

local function apply_highlights()
  local ui = require("core.ui")
  local p = ui.palette()
  local set_hl = vim.api.nvim_set_hl

  set_hl(0, "MusicTitle", { fg = p.pink, bg = "NONE", bold = true })
  set_hl(0, "MusicArtist", { fg = p.cyan, bg = "NONE" })
  set_hl(0, "MusicBorder", { fg = p.purple, bg = "NONE" })
  set_hl(0, "MusicAccent", { fg = p.yellow, bold = true })
  set_hl(0, "MusicStatus", { fg = p.fg, bg = "NONE", bold = true })
  set_hl(0, "MusicNormal", { fg = p.fg, bg = "NONE" })
end

local function ensure_highlight_autocmd()
  local ui = require("core.ui")
  ui.on_theme_change(ui.create_augroup("MusicDashboardHighlights"), function()
    apply_highlights()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_set_option_value("winhighlight", WINHIGHLIGHT, { win = state.win })
    end
  end)
end

local function panel_position()
  local width = state.width
  local height = state.height

  if state.panel_position == "center" then
    return {
      relative = "editor",
      style = "minimal",
      border = "rounded",
      title = "  Music ",
      title_pos = "center",
      width = width,
      height = height,
      row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1),
      col = math.max(1, math.floor((vim.o.columns - width) / 2)),
    }
  end

  return {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    title = "  Music ",
    title_pos = "center",
    width = width,
    height = height,
    row = 1,
    col = math.max(1, vim.o.columns - width - 2),
  }
end

local function truncate_text(text, max_width)
  local s = tostring(text or "")
  if vim.fn.strdisplaywidth(s) <= max_width then
    return s
  end

  local cut = #s
  while cut > 1 do
    local candidate = s:sub(1, cut) .. "…"
    if vim.fn.strdisplaywidth(candidate) <= max_width then
      return candidate
    end
    cut = cut - 1
  end

  return "…"
end

local function center_text(text, width)
  text = tostring(text or "")
  local len = vim.fn.strdisplaywidth(text)
  if len >= width then
    return truncate_text(text, width)
  end
  local left = math.floor((width - len) / 2)
  local right = math.max(0, width - len - left)
  return string.rep(" ", left) .. text .. string.rep(" ", right)
end

local function is_panel_open() return state.win ~= nil and vim.api.nvim_win_is_valid(state.win) end

local function panel_lines()
  local info = state.cache
  local title = info.title
  if not title or title == "" then
    title = "Unknown Track"
  end
  local artist = info.artist
  if not artist or artist == "" then
    artist = "Unknown Artist"
  end

  local status = normalize_status(info.status)
  local status_line = string.format("%s %s", status_icon(status), status)

  -- Ensure window width is consistent
  local width = state.width - 2 -- account for borders

  return {
    center_text(title, width),
    center_text(artist, width),
    center_text(status_line, width),
  }
end

local panel_ns = vim.api.nvim_create_namespace("music_panel")

local function render_panel()
  if not is_panel_open() or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local lines = panel_lines()

  vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(state.buf, panel_ns, 0, -1)

  -- One highlight per line: title, artist, playback status.
  -- (nvim_buf_add_highlight is deprecated on 0.11; extmarks are the API now.)
  for index, group in ipairs({ "MusicTitle", "MusicArtist", "MusicStatus" }) do
    if lines[index] then
      vim.api.nvim_buf_set_extmark(state.buf, panel_ns, index - 1, 0, {
        end_col = #lines[index],
        hl_group = group,
      })
    end
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
end

local function ensure_panel_buffer()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
  vim.api.nvim_set_option_value("buflisted", false, { buf = state.buf })
  vim.api.nvim_set_option_value("readonly", false, { buf = state.buf })
  vim.api.nvim_set_option_value("filetype", "musicdashboard", { buf = state.buf })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = state.buf,
    once = true,
    callback = function()
      state.buf = nil
      if state.win and vim.api.nvim_win_is_valid(state.win) then
        state.win = nil
      end
    end,
  })

  return state.buf
end

local function open_panel()
  if is_panel_open() then
    render_panel()
    return
  end

  local buf = ensure_panel_buffer()
  state.win = vim.api.nvim_open_win(buf, false, panel_position())
  vim.api.nvim_set_option_value("winblend", state.winblend, { win = state.win })
  vim.api.nvim_set_option_value(
    "winhighlight",
    "NormalFloat:MusicNormal,Normal:MusicNormal,FloatBorder:MusicBorder,FloatTitle:MusicBorder",
    { win = state.win }
  )

  render_panel()
end

local function close_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function update_cache(payload)
  if type(payload) ~= "table" then
    return
  end

  state.cache.available = payload.available == true
  state.cache.title = tostring(payload.title or "")
  state.cache.artist = tostring(payload.artist or "")
  state.cache.status = normalize_status(payload.status)
  state.cache.app = tostring(payload.app or "")
  state.cache.updated_at = now_ms()

  if state.cache.title == "" then
    state.cache.title = state.cache.available and "Unknown Track" or "No media session"
  end
  if state.cache.artist == "" then
    state.cache.artist = state.cache.available and "Unknown Artist" or "Start Spotify or Apple Music"
  end

  if is_panel_open() then
    render_panel()
  end
end

local function ps_common_prelude()
  return [[
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime]
$AwaitWinRt = {
  param([object]$AsyncOperation, [Type]$ResultType)
  $method = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1

  if ($null -eq $method) {
    throw 'Unable to locate System.WindowsRuntimeSystemExtensions.AsTask generic overload.'
  }

  $generic = $method.MakeGenericMethod(@($ResultType))
  $task = $generic.Invoke($null, @($AsyncOperation))
  return $task.GetAwaiter().GetResult()
}

$manager = & $AwaitWinRt ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
$session = $manager.GetCurrentSession()

if ($null -eq $session) {
  [pscustomobject]@{
    ok = $true
    available = $false
    title = 'No media session'
    artist = 'Start Spotify or Apple Music'
    status = 'Stopped'
    app = ''
  } | ConvertTo-Json -Compress
  exit 0
}
]]
end

local function ps_read_script()
  return ps_common_prelude()
    .. [[
$props = & $AwaitWinRt ($session.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
$playback = $session.GetPlaybackInfo()

[pscustomobject]@{
  ok = $true
  available = $true
  title = [string]$props.Title
  artist = [string]$props.Artist
  status = [string]$playback.PlaybackStatus
  app = [string]$session.SourceAppUserModelId
} | ConvertTo-Json -Compress
]]
end

local function ps_action_script(action)
  local action_map = {
    playpause = "$result = & $AwaitWinRt ($session.TryTogglePlayPauseAsync()) ([bool])",
    next = "$result = & $AwaitWinRt ($session.TrySkipNextAsync()) ([bool])",
    prev = "$result = & $AwaitWinRt ($session.TrySkipPreviousAsync()) ([bool])",
    stop = "$result = & $AwaitWinRt ($session.TryStopAsync()) ([bool])",
  }

  local invoke_action = action_map[action]
  if not invoke_action then
    return nil
  end

  return ps_common_prelude()
    .. string.format(
      [[
%s
Start-Sleep -Milliseconds 120
$props = & $AwaitWinRt ($session.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
$playback = $session.GetPlaybackInfo()

[pscustomobject]@{
  ok = $true
  available = $true
  title = [string]$props.Title
  artist = [string]$props.Artist
  status = [string]$playback.PlaybackStatus
  app = [string]$session.SourceAppUserModelId
  commandOk = [bool]$result
} | ConvertTo-Json -Compress
]],
      invoke_action
    )
end

local function ps_volume_key_script(vk_hex)
  return string.format(
    [[
$ErrorActionPreference = 'Stop'
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class MusicNative {
  [DllImport("user32.dll")]
  public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
}
"@ | Out-Null

$vk = [byte]%s
[MusicNative]::keybd_event($vk, 0, 0, 0)
[MusicNative]::keybd_event($vk, 0, 2, 0)

[pscustomobject]@{ ok = $true } | ConvertTo-Json -Compress
]],
    vk_hex
  )
end

local function ps_set_volume_script(percent)
  return string.format(
    [[
$ErrorActionPreference = 'Stop'

$p = [double]%s
if ($p -lt 0) { $p = 0 }
if ($p -gt 100) { $p = 100 }
$scalar = [single]($p / 100.0)

Add-Type @"
using System;
using System.Runtime.InteropServices;

namespace AudioInterop {
  [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  interface IAudioEndpointVolume {
    int RegisterControlChangeNotify(IntPtr pNotify);
    int UnregisterControlChangeNotify(IntPtr pNotify);
    int GetChannelCount(out uint pnChannelCount);
    int SetMasterVolumeLevel(float fLevelDB, Guid pguidEventContext);
    int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);
    int GetMasterVolumeLevel(out float pfLevelDB);
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int SetChannelVolumeLevel(uint nChannel, float fLevelDB, Guid pguidEventContext);
    int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, Guid pguidEventContext);
    int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB);
    int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);
    int GetMute(out bool pbMute);
    int GetVolumeStepInfo(out uint pnStep, out uint pnStepCount);
    int VolumeStepUp(Guid pguidEventContext);
    int VolumeStepDown(Guid pguidEventContext);
    int QueryHardwareSupport(out uint pdwHardwareSupportMask);
    int GetVolumeRange(out float pflVolumeMindB, out float pflVolumeMaxdB, out float pflVolumeIncrementdB);
  }

  [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  interface IMMDevice {
    int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
    int OpenPropertyStore(int stgmAccess, out object ppProperties);
    int GetId(out string ppstrId);
    int GetState(out int pdwState);
  }

  [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  interface IMMDeviceEnumerator {
    int EnumAudioEndpoints(int dataFlow, int dwStateMask, out object ppDevices);
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppEndpoint);
    int GetDevice(string pwstrId, out IMMDevice ppDevice);
    int RegisterEndpointNotificationCallback(IntPtr pClient);
    int UnregisterEndpointNotificationCallback(IntPtr pClient);
  }

  [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
  class MMDeviceEnumerator { }

  public static class Volume {
    public static void SetMasterVolumeScalar(float level) {
      var enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator());
      IMMDevice device;
      Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(0, 1, out device)); // eRender, eMultimedia

      Guid iid = typeof(IAudioEndpointVolume).GUID;
      object epObj;
      Marshal.ThrowExceptionForHR(device.Activate(ref iid, 23, IntPtr.Zero, out epObj)); // CLSCTX_ALL

      var ep = (IAudioEndpointVolume)epObj;
      Marshal.ThrowExceptionForHR(ep.SetMasterVolumeLevelScalar(level, Guid.Empty));
    }
  }
}
"@ | Out-Null

[AudioInterop.Volume]::SetMasterVolumeScalar($scalar)

[pscustomobject]@{ ok = $true; volume = [int]$p } | ConvertTo-Json -Compress
]],
    tostring(percent)
  )
end

local function ps_debug_script()
  return ps_common_prelude()
    .. [[
$props = & $AwaitWinRt ($session.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
$timeline = $session.GetTimelineProperties()
$playback = $session.GetPlaybackInfo()

[pscustomobject]@{
  ok = $true
  available = $true
  raw = [pscustomobject]@{
    sourceAppUserModelId = [string]$session.SourceAppUserModelId
    title = [string]$props.Title
    artist = [string]$props.Artist
    albumTitle = [string]$props.AlbumTitle
    playbackStatus = [string]$playback.PlaybackStatus
    controls = [pscustomobject]@{
      canPlay = [bool]$playback.Controls.IsPlayEnabled
      canPause = [bool]$playback.Controls.IsPauseEnabled
      canNext = [bool]$playback.Controls.IsNextEnabled
      canPrevious = [bool]$playback.Controls.IsPreviousEnabled
      canStop = [bool]$playback.Controls.IsStopEnabled
    }
    timeline = [pscustomobject]@{
      position = [string]$timeline.Position
      startTime = [string]$timeline.StartTime
      endTime = [string]$timeline.EndTime
    }
  }
} | ConvertTo-Json -Compress -Depth 6
]]
end

local function run_ps(script, on_done)
  if not is_windows() then
    vim.schedule(function()
      if on_done then
        on_done(false, nil, "This module is only supported on Windows")
      end
    end)
    return
  end

  vim.system({
    "powershell.exe",
    "-NoLogo",
    "-NoProfile",
    "-NonInteractive",
    "-ExecutionPolicy",
    "Bypass",
    "-Command",
    script,
  }, { text = true }, function(result)
    vim.schedule(function()
      local code = result and result.code or 1
      local stdout = (result and result.stdout or ""):gsub("^%s+", ""):gsub("%s+$", "")
      local stderr = (result and result.stderr or ""):gsub("^%s+", ""):gsub("%s+$", "")

      debug_log("powershell result", {
        code = code,
        stdout = stdout,
        stderr = stderr,
      })

      local payload, parse_err = decode_json(stdout)
      if code ~= 0 then
        if on_done then
          on_done(false, payload, string.format("PowerShell exited with code %s", tostring(code)), stderr)
        end
        return
      end

      if not payload then
        if on_done then
          on_done(
            false,
            nil,
            "Could not parse PowerShell JSON output",
            parse_err .. (stderr ~= "" and ("\n" .. stderr) or "")
          )
        end
        return
      end

      if payload.ok == false then
        if on_done then
          on_done(false, payload, tostring(payload.error or "GSMTC query failed"), stderr)
        end
        return
      end

      if on_done then
        on_done(true, payload, nil, stderr)
      end
    end)
  end)
end

local function handle_failure(prefix, err, detail)
  warn(prefix .. ": " .. tostring(err or "Unknown error"), detail)
end

--- Speed the poll back up when something is playing, slow it down when not.
local function adjust_poll_interval(active)
  if active then
    state.poll_interval_ms = state.poll_interval_min_ms
  else
    state.poll_interval_ms = math.min(state.poll_interval_ms * 2, state.poll_interval_max_ms)
  end
end

local function refresh_cache_silent()
  if state.pending_query or not is_windows() then
    return
  end

  local now = now_ms()
  if (now - (state.last_poll_attempt_ms or 0)) < state.poll_interval_ms then
    return
  end

  state.last_poll_attempt_ms = now
  state.pending_query = true
  run_ps(ps_read_script(), function(ok, payload, err, detail)
    state.pending_query = false

    if ok then
      update_cache(payload)
      adjust_poll_interval(state.cache.available)
      return
    end

    -- Background refreshes stay silent; only the debug channel hears about them.
    debug_log("silent refresh failed", { err = err, detail = detail })
    state.cache.updated_at = now_ms()
    adjust_poll_interval(false)
  end)
end

local function run_action(action_name)
  local script = ps_action_script(action_name)
  if not script then
    handle_failure("Music action failed", "Unsupported action: " .. tostring(action_name))
    return
  end

  run_ps(script, function(ok, payload, err, detail)
    if not ok then
      handle_failure("Music control failed", err, detail)
      return
    end

    update_cache(payload)

    if payload.commandOk == false then
      warn("Media session rejected command", "Command: " .. tostring(action_name))
    end
  end)
end

local function run_volume_key(vk_hex)
  run_ps(ps_volume_key_script(vk_hex), function(ok, payload, err, detail)
    if ok then
      return
    end
    debug_log("volume key failed", { err = err, detail = detail, payload = payload })
  end)
end

local function run_set_volume(percent)
  run_ps(ps_set_volume_script(percent), function(ok, payload, err, detail)
    if ok then
      return
    end
    debug_log("set volume failed", { err = err, detail = detail, payload = payload })
  end)
end

function M.get_now_playing(callback)
  if state.pending_query then
    if callback then
      callback(state.cache)
    end
    return state.cache
  end

  state.pending_query = true
  run_ps(ps_read_script(), function(ok, payload, err, detail)
    state.pending_query = false

    if ok then
      update_cache(payload)
    else
      handle_failure("Music query failed", err, detail)
    end

    if callback then
      callback(state.cache)
    end
  end)

  return state.cache
end

function M.statusline()
  refresh_cache_silent()

  local info = state.cache
  local status = normalize_status(info.status)

  -- Hide the segment entirely when there is nothing to show.
  if not info.available or not info.title or info.title == "" or info.title == "No media session" then
    return ""
  end

  local music_icons = require("core.icons").music
  local icon = music_icons.playing
  if status == "Paused" then
    icon = music_icons.paused
  elseif status == "Stopped" then
    icon = music_icons.stopped
  end

  local title = info.title
  if #title > 20 then
    title = title:sub(1, 17) .. "\u{2026}"
  end

  return string.format("%s %s", icon, title)
end

--- Status for UI styling: "Playing" | "Paused" | "Stopped" | nil when unavailable.
function M.statusline_status()
  local info = state.cache
  if not info.available then
    return nil
  end
  return normalize_status(info.status)
end

function M.volume_up()
  -- VK_VOLUME_UP (0xAF)
  run_volume_key("0xAF")
end

function M.volume_down()
  -- VK_VOLUME_DOWN (0xAE)
  run_volume_key("0xAE")
end

function M.set_volume(percent)
  local n = tonumber(percent)
  if not n then
    return
  end
  if n < 0 then
    n = 0
  elseif n > 100 then
    n = 100
  end
  run_set_volume(n)
end

function M.set_volume_prompt()
  vim.ui.input({ prompt = "Volume (0-100): " }, function(input)
    if not input or input == "" then
      return
    end
    local n = tonumber(input)
    if not n then
      return
    end
    M.set_volume(n)
  end)
end

--- Current track, as a table (and via `callback` once a fresh query returns).
--- Alias kept because `now_playing` is the name the panel and any external
--- caller reach for; `get_now_playing` is the implementation.
function M.now_playing(callback) return M.get_now_playing(callback) end

function M.playpause() run_action("playpause") end

function M.next() run_action("next") end

function M.prev() run_action("prev") end

function M.stop() run_action("stop") end

function M.toggle_panel()
  if is_panel_open() then
    close_panel()
    return
  end

  open_panel()
  M.get_now_playing()
end

function M.debug_dump()
  run_ps(ps_debug_script(), function(ok, payload, err, detail)
    if not ok then
      handle_failure("MusicDebug failed", err, detail)
      return
    end

    local raw = payload.raw or payload
    local encoded
    if vim.json and vim.json.encode then
      local ok_encode, out = pcall(vim.json.encode, raw)
      encoded = ok_encode and out or vim.inspect(raw)
    else
      encoded = vim.inspect(raw)
    end

    debug_log("raw GSMTC", raw)
    vim.notify("MusicDebug raw output:\n" .. tostring(encoded), vim.log.levels.INFO, {
      title = "MusicDebug",
      timeout = 7000,
    })
  end)
end

--- Turn the debug channel on or off at runtime.
---
--- The other two ways in are `vim.g.music_debug = 1` (read once at load) and
--- `setup({ debug = true })`; this is the one that works mid-session, which is
--- when you actually want it. `:MusicDebug` dumps a single raw payload.
---@param enabled boolean
function M.set_debug(enabled)
  state.debug = enabled == true
  vim.g.music_debug = state.debug and 1 or 0
  vim.notify(
    "Music debug " .. (state.debug and "enabled" or "disabled"),
    vim.log.levels.INFO,
    { title = "Music" }
  )
end

function M.setup(opts)
  if state.setup_done then
    return
  end

  opts = opts or {}
  if type(opts.width) == "number" and opts.width >= 20 then
    state.width = math.floor(opts.width)
  end
  if type(opts.winblend) == "number" and opts.winblend >= 0 and opts.winblend <= 100 then
    state.winblend = opts.winblend
  end
  if opts.position == "center" or opts.position == "top-right" then
    state.panel_position = opts.position
  end
  if opts.debug == true or opts.debug == false then
    state.debug = opts.debug
    vim.g.music_debug = state.debug and 1 or 0
  end

  apply_highlights()
  ensure_highlight_autocmd()

  -- Keep the floating panel anchored when the window is resized.
  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("MusicPanelLayout", { clear = true }),
    callback = function()
      if is_panel_open() then
        pcall(vim.api.nvim_win_set_config, state.win, panel_position())
      end
    end,
  })

  vim.api.nvim_create_user_command("Music", function(opts)
    local actions = {
      panel = M.toggle_panel,
      toggle = M.playpause,
      next = M.next,
      prev = M.prev,
      stop = M.stop,
      volume = M.set_volume_prompt,
      debug = function() M.set_debug(not state.debug) end,
    }

    local action = actions[opts.args ~= "" and opts.args or "panel"]
    if action then
      action()
    else
      vim.notify("Unknown music action: " .. opts.args, vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "panel", "toggle", "next", "prev", "stop", "volume", "debug" }
    end,
    desc = "Control the Windows media session",
  })

  vim.api.nvim_create_user_command(
    "MusicDebug",
    function() M.debug_dump() end,
    { desc = "Print raw GSMTC payload" }
  )

  state.setup_done = true
end

return M
