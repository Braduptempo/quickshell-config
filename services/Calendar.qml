// Calendar.qml
// Events from the calendars in Settings → Calendars: ICS links fetched with
// curl every Config.calendar.refreshMinutes, read here (VEVENT with DTSTART,
// DTEND or DURATION, all-day dates, and RRULE for daily, weekly, monthly and
// yearly repeats with INTERVAL, COUNT, UNTIL, BYDAY and EXDATE), and kept in
// the shell's state folder so they're there offline too.
//   Calendar.eventsOn(day)   that day's events, sorted
//   Calendar.hasEvents(day)  for the dots in the month
//   Calendar.next            the next event that hasn't ended
// Your own events (made in the clock panel) live in the state folder as
// local-events.json, in the "This computer" calendar:
//   Calendar.addLocal({ title, start, end, allDay, location })
//   Calendar.removeLocal(id)
// Times with a TZID are taken as local time.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  // [{ title, start, end, allDay, location, color, calendar, id?, local? }], start/end in ms
  // The downloaded ones and your own together, sorted
  property var events: []
  property var remote: []
  // "2026-11-20" -> number of events, for the month dots
  property var days: ({})
  property bool syncing: false
  property double lastSync: 0
  // calendar name -> error text
  property var errors: ({})

  readonly property var sources: Config.calendar.sources.filter(s => s.enabled !== false && (s.url ?? "") !== "")

  function key(d: date): string {
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
  }

  function hasEvents(d: date): bool {
    return (days[key(d)] ?? 0) > 0;
  }

  function eventsOn(d: date): var {
    const from = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    const to = from + 86400000;
    return events.filter(e => e.start < to && e.end > from);
  }

  readonly property var next: {
    const now = Time.date.getTime();
    return events.find(e => e.end > now && !e.allDay) ?? null;
  }

  // --- Syncing ---------------------------------------------------------------------------
  function sync(): void {
    if (sources.length === 0) {
      remote = [];
      rebuild();
      return;
    }
    syncing = true;
    fetch.running = true;
  }

  Timer {
    running: Config.calendar.refreshMinutes > 0 && root.sources.length > 0
    interval: Math.max(1, Config.calendar.refreshMinutes) * 60000
    repeat: true
    onTriggered: root.sync()
  }

  // At start, and when a calendar is added or removed: fetch again
  onSourcesChanged: syncDelay.restart()
  Component.onCompleted: syncDelay.restart()

  Timer {
    id: syncDelay
    interval: 800
    onTriggered: root.sync()
  }

  Process {
    id: fetch
    command: ["sh", "-c",
      "i=0; for u in \"$@\"; do echo \"@@SOURCE $i\"; curl -sfL --max-time 25 \"$u\" || echo \"@@ERROR $i\"; echo; i=$((i+1)); done",
      "sh"].concat(root.sources.map(s => s.url.replace(/^webcal:/, "https:")))
    stdout: StdioCollector {
      onStreamFinished: root.parseAll(text, true)
    }
    onExited: root.syncing = false
  }

  // The last good result, for start-up and offline
  FileView {
    id: cache
    path: Quickshell.statePath("calendar.ics.cache")
    printErrors: false
    onLoaded: if (root.events.length === 0) root.parseAll(text(), false)
  }

  function parseAll(text: string, fresh: bool): void {
    const chunks = text.split(/^@@SOURCE /m).slice(1);
    const list = [];
    const errors = {};
    for (const chunk of chunks) {
      const index = parseInt(chunk);
      const source = sources[index];
      if (!source) continue;
      if (/^@@ERROR /m.test(chunk) || !chunk.includes("BEGIN:VCALENDAR")) {
        errors[source.name] = "Couldn't download this calendar";
        continue;
      }
      for (const e of parseIcs(chunk, source)) list.push(e);
    }
    remote = list;
    rebuild();
    if (fresh) {
      root.errors = errors;
      lastSync = Date.now();
      if (Object.keys(errors).length < chunks.length) cache.setText(text);
    }
  }

  // Downloaded and local events together, and the month dots
  function rebuild(): void {
    const local = (localFile.list ?? []).map(e => ({
      id: e.id, title: e.title, start: e.start, end: e.end, allDay: e.allDay === true,
      location: e.location ?? "", color: Theme.accent, calendar: "This computer", local: true
    }));
    const list = remote.concat(local).sort((a, b) => a.start - b.start);
    const map = {};
    for (const e of list) {
      // Mark every day the event touches (a few days at most)
      for (let t = e.start, n = 0; t < e.end && n < 31; t += 86400000, n++) {
        const k = key(new Date(t));
        map[k] = (map[k] ?? 0) + 1;
      }
    }
    events = list;
    days = map;
  }

  // --- Your own events -------------------------------------------------------------------
  function addLocal(e: var): void {
    const id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    localFile.list = (localFile.list ?? []).concat([{ id: id, title: e.title, start: e.start, end: e.end, allDay: e.allDay === true, location: e.location ?? "" }]);
    rebuild();
  }

  function removeLocal(id: string): void {
    localFile.list = (localFile.list ?? []).filter(e => e.id !== id);
    rebuild();
  }

  FileView {
    path: Quickshell.statePath("local-events.json")
    printErrors: false
    onLoaded: root.rebuild()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: localFile
      property var list: []
    }
  }

  // --- Reading ICS -------------------------------------------------------------------------
  // "20261120T150000Z", "20261120T150000" (local), "20261120" (a date)
  function parseDate(value: string): var {
    const m = value.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/);
    if (!m) return null;
    const [y, mo, d] = [parseInt(m[1]), parseInt(m[2]) - 1, parseInt(m[3])];
    if (m[4] === undefined) return { time: new Date(y, mo, d).getTime(), allDay: true };
    const [h, mi, s] = [parseInt(m[4]), parseInt(m[5]), parseInt(m[6] ?? "0")];
    const time = m[7] ? Date.UTC(y, mo, d, h, mi, s) : new Date(y, mo, d, h, mi, s).getTime();
    return { time, allDay: false };
  }

  // "PT1H30M", "P1D"
  function parseDuration(value: string): real {
    const m = value.match(/^-?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/);
    if (!m) return 0;
    return ((parseInt(m[1] ?? 0) * 7 + parseInt(m[2] ?? 0)) * 86400 + parseInt(m[3] ?? 0) * 3600 + parseInt(m[4] ?? 0) * 60 + parseInt(m[5] ?? 0)) * 1000;
  }

  function cleanText(text: string): string {
    return text.replace(/\\n/gi, " ").replace(/\\([,;\\])/g, "$1").trim();
  }

  function parseIcs(text: string, source: var): var {
    // Long lines continue on the next line after a space or tab
    const lines = text.replace(/\r\n/g, "\n").replace(/\n[ \t]/g, "").split("\n");
    const raw = [];
    let current = null;
    for (const line of lines) {
      if (line === "BEGIN:VEVENT") {
        current = { exdates: [] };
      } else if (line === "END:VEVENT") {
        if (current) raw.push(current);
        current = null;
      } else if (current) {
        const colon = line.indexOf(":");
        if (colon < 0) continue;
        const name = line.slice(0, colon).split(";")[0].toUpperCase();
        const value = line.slice(colon + 1);
        switch (name) {
        case "SUMMARY": current.title = cleanText(value); break;
        case "LOCATION": current.location = cleanText(value); break;
        case "DTSTART": current.start = parseDate(value); break;
        case "DTEND": current.end = parseDate(value); break;
        case "DURATION": current.duration = parseDuration(value); break;
        case "RRULE": current.rrule = value; break;
        case "EXDATE": for (const v of value.split(",")) { const d = parseDate(v); if (d) current.exdates.push(d.time); } break;
        case "RECURRENCE-ID": current.recurrenceId = parseDate(value); break;
        case "UID": current.uid = value; break;
        case "STATUS": current.cancelled = value === "CANCELLED"; break;
        }
      }
    }

    // Changed single occurrences replace the one from the rule
    const moved = {};
    for (const r of raw) if (r.recurrenceId && r.uid) moved[r.uid + "@" + r.recurrenceId.time] = true;

    const windowStart = Date.now() - 62 * 86400000;
    const windowEnd = Date.now() + 400 * 86400000;
    const out = [];
    for (const r of raw) {
      if (!r.start || r.cancelled) continue;
      const length = r.end ? r.end.time - r.start.time : (r.duration ?? (r.start.allDay ? 86400000 : 3600000));
      const make = start => ({
        title: r.title || "(No title)",
        start,
        end: start + Math.max(length, 0),
        allDay: r.start.allDay,
        location: r.location ?? "",
        color: source.color || Theme.accent,
        calendar: source.name
      });
      const starts = r.rrule && !r.recurrenceId ? expand(r.start.time, r.rrule, windowStart, windowEnd) : [r.start.time];
      for (const s of starts) {
        if (r.exdates.indexOf(s) >= 0) continue;
        if (r.rrule && !r.recurrenceId && r.uid && moved[r.uid + "@" + s]) continue;
        if (s + length < windowStart || s > windowEnd) continue;
        out.push(make(s));
      }
    }
    return out;
  }

  // Occurrences of a repeat rule inside the window (at most 600)
  function expand(first: real, rule: var, from: real, to: real): var {
    const p = {};
    for (const part of rule.split(";")) {
      const [k, v] = part.split("=");
      p[k] = v;
    }
    const freq = p.FREQ;
    const interval = Math.max(1, parseInt(p.INTERVAL ?? "1"));
    const count = p.COUNT ? parseInt(p.COUNT) : -1;
    const until = p.UNTIL ? (parseDate(p.UNTIL)?.time ?? Infinity) : Infinity;
    const weekdays = { SU: 0, MO: 1, TU: 2, WE: 3, TH: 4, FR: 5, SA: 6 };
    const byDay = p.BYDAY && freq === "WEEKLY" ? p.BYDAY.split(",").map(d => weekdays[d.slice(-2)]).filter(d => d !== undefined) : [];

    const out = [];
    const start = new Date(first);
    let n = 0;
    let made = 0;
    for (let step = 0; step < 5000 && made < 600; step++) {
      let candidates = [];
      const base = new Date(start);
      if (freq === "DAILY") base.setDate(start.getDate() + step * interval);
      else if (freq === "WEEKLY") base.setDate(start.getDate() + step * interval * 7);
      else if (freq === "MONTHLY") base.setMonth(start.getMonth() + step * interval);
      else if (freq === "YEARLY") base.setFullYear(start.getFullYear() + step * interval);
      else return [first];

      if (byDay.length > 0) {
        // The chosen weekdays of this week (the week of `base`, starting where the event does)
        for (const wd of byDay) {
          const d = new Date(base);
          d.setDate(base.getDate() + ((wd - start.getDay() + 7) % 7));
          candidates.push(d.getTime());
        }
        candidates.sort((a, b) => a - b);
      } else {
        candidates = [base.getTime()];
      }

      for (const t of candidates) {
        if (t < first) continue;
        if (t > until || (count >= 0 && n >= count)) return out;
        n++;
        if (t > to) return out;
        if (t >= from - 31 * 86400000) {
          out.push(t);
          made++;
        }
      }
    }
    return out;
  }
}
