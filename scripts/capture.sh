#!/usr/bin/env bash
# capture.sh: screenshots (grim + slurp) and screen recording
# (gpu-screen-recorder) for the shell's capture toolbar.
#
#   capture.sh shot   <region|window|screen> [--delay N] [--copy] [--cursor] [--no-save] [--no-freeze] [--edit]
#   capture.sh record <region|window|screen> [--mic] [--audio] [--cursor] [--countdown]
#   capture.sh stop       stop the recording and save it
#   capture.sh pause      pause or resume the recording
#   capture.sh status     prints "idle", or "recording <start> <paused 0|1> <paused seconds> <file>"
#   capture.sh replay start [--seconds N] [--audio] [--mic]
#                          keep the last N seconds (30 by default) of the focused
#                          monitor in memory, like ShadowPlay
#   capture.sh replay save  write them to ~/Videos/Replays
#   capture.sh replay stop
#   capture.sh replay status   prints "idle", or "replay <seconds> <monitor>"
#
# The recorder runs detached, so a shell reload doesn't stop it; its state is
# in $XDG_RUNTIME_DIR/quickshell-recording.
#
# For testing: QS_CAPTURE_DIR=/tmp/somewhere saves there instead of ~/Pictures
# and ~/Videos.
set -u

runtime="${XDG_RUNTIME_DIR:-/tmp}"
state="$runtime/quickshell-recording"
replay_state="$runtime/quickshell-replay"
pictures="${QS_CAPTURE_DIR:-$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots}"
videos="${QS_CAPTURE_DIR:-$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Recordings}"

# Monitors that are on, with their active workspace
visible_workspaces() {
  hyprctl -j monitors | jq -c '[.[] | select(.disabled | not) | .activeWorkspace.id]'
}

focused_monitor() {
  hyprctl -j monitors | jq -r '.[] | select(.focused) | .name'
}

# Prints the chosen area as "X,Y WxH" (grim) or, with "gsr", "WxH+X+Y".
# For "screen" it prints "output:NAME". Exits 1 when cancelled (Esc).
select_area() {
  local target="$1" format="$2" fmt
  if [ "$format" = gsr ]; then fmt='%wx%h+%x+%y'; else fmt='%x,%y %wx%h'; fi
  case "$target" in
    screen)
      echo "output:$(focused_monitor)"
      ;;
    window)
      # Click a window; slurp only offers the windows on screen
      hyprctl -j clients | jq -r --argjson ws "$(visible_workspaces)" \
        '.[] | select(.workspace.id as $w | $ws | index($w)) | select(.hidden | not)
             | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
        | slurp -r -f "$fmt" || return 1
      ;;
    *)
      slurp -d -f "$fmt" || return 1
      ;;
  esac
}

notify_saved() {
  # $1 title, $2 file, $3 folder; actions run when clicked
  local title="$1" file="$2" folder="$3" answer
  # Edit (the drawing editor) only for pictures
  local edit=()
  case "$file" in *.png|*.jpg) edit=(-A edit=Edit) ;; esac
  answer="$(notify-send -a "$title" -i "$file" "$title" "$(basename "$file")" \
    -A open=Open "${edit[@]}" -A folder="Show in folder")"
  case "$answer" in
    open) xdg-open "$file" >/dev/null 2>&1 & ;;
    edit) qs ipc call capture edit "$file" >/dev/null 2>&1 & ;;
    folder) xdg-open "$folder" >/dev/null 2>&1 & ;;
  esac
}

shot() {
  local target="$1"; shift
  local delay=0 copy=0 cursor=0 save=1 freeze=1 edit=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --delay) delay="$2"; shift ;;
      --copy) copy=1 ;;
      --cursor) cursor=1 ;;
      --no-save) save=0 ;;
      --no-freeze) freeze=0 ;;
      --edit) edit=1 ;;
    esac
    shift
  done

  # Freeze the screen while choosing, so menus and tooltips stay put
  local freezer=""
  if [ "$freeze" = 1 ] && [ "$target" = region ] && command -v hyprpicker >/dev/null; then
    hyprpicker -r -z >/dev/null 2>&1 &
    freezer=$!
    sleep 0.15
  fi
  local area
  area="$(select_area "$target" grim)"
  local ok=$?
  [ -n "$freezer" ] && kill "$freezer" 2>/dev/null
  [ $ok -eq 0 ] && [ -n "$area" ] || exit 0

  [ "$delay" -gt 0 ] && sleep "$delay"

  local dir file
  if [ "$save" = 1 ]; then dir="$pictures"; else dir="$runtime/quickshell-shots"; fi
  mkdir -p "$dir"
  file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

  local args=()
  [ "$cursor" = 1 ] && args+=(-c)
  if [[ "$area" == output:* ]]; then
    grim "${args[@]}" -o "${area#output:}" "$file" || exit 1
  else
    grim "${args[@]}" -g "$area" "$file" || exit 1
  fi

  [ "$copy" = 1 ] && wl-copy --type image/png < "$file"
  # Straight into the drawing editor; it saves or copies the result itself
  if [ "$edit" = 1 ]; then
    qs ipc call capture edit "$file" >/dev/null 2>&1 && exit 0
  fi
  if [ "$save" = 1 ]; then
    # In the background: it waits for a click on Open / Show in folder
    notify_saved "Screenshot saved" "$file" "$dir" &
    disown
  else
    notify-send -a "Screenshot" -i "$file" "Screenshot copied" "Paste it anywhere"
  fi
}

read_state() {
  [ -f "$state" ] || return 1
  # pid start paused pausedAt pausedTotal file
  read -r pid start paused paused_at paused_total file < "$state" || return 1
  kill -0 "$pid" 2>/dev/null || { rm -f "$state"; return 1; }
}

record() {
  local target="$1"; shift
  local mic=0 audio=0 cursor=0 countdown=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --mic) mic=1 ;;
      --audio) audio=1 ;;
      --cursor) cursor=1 ;;
      --countdown) countdown=1 ;;
    esac
    shift
  done
  command -v gpu-screen-recorder >/dev/null || {
    notify-send -a Recording "gpu-screen-recorder is not installed" "sudo pacman -S gpu-screen-recorder"
    exit 1
  }
  read_state && exit 0

  local area
  area="$(select_area "$target" gsr)" && [ -n "$area" ] || exit 0

  if [ "$countdown" = 1 ]; then
    local id
    id="$(notify-send -a Recording -p -t 1100 "Recording in 3")"
    sleep 1; notify-send -a Recording -r "$id" -t 1100 "Recording in 2"
    sleep 1; notify-send -a Recording -r "$id" -t 900 "Recording in 1"
    sleep 1
  fi

  mkdir -p "$videos"
  local file
  file="$videos/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
  local args=(-f 60 -q very_high -c mp4 -cursor "$([ "$cursor" = 1 ] && echo yes || echo no)" -o "$file")
  if [[ "$area" == output:* ]]; then
    args=(-w "${area#output:}" "${args[@]}")
  else
    args=(-w region -region "$area" "${args[@]}")
  fi
  # Both sources end up mixed in one track
  if [ "$mic" = 1 ] && [ "$audio" = 1 ]; then args+=(-a "default_output|default_input")
  elif [ "$audio" = 1 ]; then args+=(-a default_output)
  elif [ "$mic" = 1 ]; then args+=(-a default_input)
  fi

  setsid -f gpu-screen-recorder "${args[@]}" >"$runtime/quickshell-recording.log" 2>&1
  sleep 0.3
  local pid
  pid="$(pgrep -n -f "gpu-screen-recorder .*$file")" || {
    notify-send -a Recording "Recording failed to start" "See $runtime/quickshell-recording.log"
    exit 1
  }
  echo "$pid $(date +%s) 0 0 0 $file" > "$state"
}

stop() {
  read_state || exit 0
  kill -INT "$pid"
  # Wait for the file to be finished
  for _ in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  rm -f "$state"
  notify_saved "Recording saved" "$file" "$(dirname "$file")" &
  disown
}

pause() {
  read_state || exit 0
  kill -USR2 "$pid"
  local now
  now="$(date +%s)"
  if [ "$paused" = 1 ]; then
    echo "$pid $start 0 0 $((paused_total + now - paused_at)) $file" > "$state"
  else
    echo "$pid $start 1 $now $paused_total $file" > "$state"
  fi
}

status() {
  if read_state; then
    local total="$paused_total"
    [ "$paused" = 1 ] && total=$((total + $(date +%s) - paused_at))
    echo "recording $start $paused $total $file"
  else
    echo idle
  fi
}

# --- Replay buffer -------------------------------------------------------------------------
read_replay() {
  [ -f "$replay_state" ] || return 1
  # pid seconds monitor
  read -r rpid rseconds rmonitor < "$replay_state" || return 1
  kill -0 "$rpid" 2>/dev/null || { rm -f "$replay_state"; return 1; }
}

replay() {
  local sub="${1:-status}"; [ $# -gt 0 ] && shift
  case "$sub" in
    start)
      local seconds=30 audio=0 mic=0
      while [ $# -gt 0 ]; do
        case "$1" in
          --seconds) seconds="$2"; shift ;;
          --audio) audio=1 ;;
          --mic) mic=1 ;;
        esac
        shift
      done
      command -v gpu-screen-recorder >/dev/null || {
        notify-send -a Replay "gpu-screen-recorder is not installed" "sudo pacman -S gpu-screen-recorder"
        exit 1
      }
      read_replay && exit 0
      local dir="${QS_CAPTURE_DIR:-$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Replays}"
      mkdir -p "$dir"
      local monitor
      monitor="$(focused_monitor)"
      local args=(-w "$monitor" -f 60 -q very_high -c mp4 -r "$seconds" -replay-storage ram -o "$dir"
                  -sc "$(dirname "$(readlink -f "$0")")/capture.sh")
      if [ "$mic" = 1 ] && [ "$audio" = 1 ]; then args+=(-a "default_output|default_input")
      elif [ "$audio" = 1 ]; then args+=(-a default_output)
      elif [ "$mic" = 1 ]; then args+=(-a default_input)
      fi
      setsid -f gpu-screen-recorder "${args[@]}" >"$runtime/quickshell-replay.log" 2>&1
      sleep 0.4
      local pid
      pid="$(pgrep -n -f "gpu-screen-recorder .*-r $seconds .*-o $dir")" || {
        notify-send -a Replay "The replay buffer failed to start" "See $runtime/quickshell-replay.log"
        exit 1
      }
      echo "$pid $seconds $monitor" > "$replay_state"
      ;;
    save)
      read_replay || { notify-send -a Replay "The replay buffer is off" "Start it from the capture toolbar (Print)"; exit 0; }
      kill -USR1 "$rpid"
      ;;
    stop)
      read_replay || exit 0
      kill -INT "$rpid"
      for _ in $(seq 30); do kill -0 "$rpid" 2>/dev/null || break; sleep 0.1; done
      rm -f "$replay_state"
      ;;
    status)
      if read_replay; then echo "replay $rseconds $rmonitor"; else echo idle; fi
      ;;
  esac
}

# gpu-screen-recorder runs this script (-sc) with the saved file and its kind
if [ -f "${1:-}" ] && [ "${2:-}" = replay ]; then
  # In the background: the recorder shouldn't wait for a click
  notify_saved "Replay saved" "$1" "$(dirname "$1")" &
  disown
  exit 0
fi

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  shot) shot "${1:-region}" "${@:2}" ;;
  record) record "${1:-region}" "${@:2}" ;;
  stop) stop ;;
  pause) pause ;;
  status) status ;;
  replay) replay "$@" ;;
  *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
