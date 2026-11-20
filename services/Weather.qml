// Weather.qml
// Current weather and the next days for the place in Settings → Weather,
// from Open-Meteo (free, no account or key; only the place's coordinates are
// sent). Refreshed every 30 minutes and kept in the state folder for when
// you're offline.
//   Weather.current   { temperature, feelsLike, code, wind, humidity, isDay }
//   Weather.days      [{ date, code, max, min, rain }]
//   Weather.rainNote  "Rain from 17:00" (next 12 hours), or ""
//   Weather.search(name) fills Weather.places for the settings page
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  readonly property bool configured: Config.weather.place !== ""
  readonly property bool fahrenheit: Config.weather.units === "fahrenheit"
  property var current: null
  property var days: []
  property string rainNote: ""
  property double updated: 0
  property string error: ""

  // "8°"
  function degrees(t: real): string {
    return Math.round(t) + "°";
  }

  // --- WMO weather codes -----------------------------------------------------------
  function describe(code: int): string {
    if (code === 0) return "Clear";
    if (code <= 2) return "Partly cloudy";
    if (code === 3) return "Cloudy";
    if (code <= 48) return "Fog";
    if (code <= 57) return "Drizzle";
    if (code <= 67) return "Rain";
    if (code <= 77) return "Snow";
    if (code <= 82) return "Showers";
    if (code <= 86) return "Snow showers";
    return "Thunderstorm";
  }

  function icon(code: int, isDay: bool): string {
    if (code === 0) return isDay ? "sun" : "moon";
    if (code <= 2) return isDay ? "cloud-sun" : "cloud";
    if (code === 3) return "cloud";
    if (code <= 48) return "fog";
    if (code <= 67 || (code >= 80 && code <= 82)) return "cloud-rain";
    if (code <= 77 || code === 85 || code === 86) return "cloud-snow";
    return "cloud-storm";
  }

  // --- Fetching ------------------------------------------------------------------------
  function refresh(): void {
    if (!configured) {
      current = null;
      days = [];
      rainNote = "";
      return;
    }
    fetch.running = true;
  }

  Timer {
    interval: 30 * 60 * 1000
    running: root.configured
    repeat: true
    onTriggered: root.refresh()
  }

  // Start, and a new place or units: fetch again
  Component.onCompleted: placeDelay.restart()
  Connections {
    target: Config.weather
    function onLatitudeChanged() { placeDelay.restart(); }
    function onLongitudeChanged() { placeDelay.restart(); }
    function onUnitsChanged() { placeDelay.restart(); }
    function onPlaceChanged() { placeDelay.restart(); }
  }

  Timer {
    id: placeDelay
    interval: 500
    onTriggered: root.refresh()
  }

  Process {
    id: fetch
    command: ["curl", "-sf", "--max-time", "20",
      "https://api.open-meteo.com/v1/forecast?latitude=" + Config.weather.latitude.toFixed(3) + "&longitude=" + Config.weather.longitude.toFixed(3)
      + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,is_day"
      + "&hourly=precipitation_probability,weather_code"
      + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
      + "&timezone=auto&forecast_days=6"
      + (root.fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")]
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim() === "") {
          root.error = "Couldn't reach the weather service";
          return;
        }
        root.parse(text);
        cache.setText(text);
      }
    }
  }

  FileView {
    id: cache
    path: Quickshell.statePath("weather.json")
    printErrors: false
    onLoaded: if (root.current === null && root.configured) root.parse(text())
  }

  function parse(text: string): void {
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      error = "Couldn't read the weather";
      return;
    }
    const c = data.current ?? {};
    current = {
      temperature: c.temperature_2m,
      feelsLike: c.apparent_temperature,
      code: c.weather_code,
      wind: Math.round(c.wind_speed_10m ?? 0),
      humidity: c.relative_humidity_2m,
      isDay: c.is_day === 1
    };
    const d = data.daily ?? {};
    days = (d.time ?? []).map((t, i) => ({
      date: new Date(t + "T12:00"),
      code: d.weather_code[i],
      max: d.temperature_2m_max[i],
      min: d.temperature_2m_min[i],
      rain: d.precipitation_probability_max[i] ?? 0
    }));
    // The first hour in the next 12 with a good chance of rain
    const h = data.hourly ?? {};
    const now = Date.now();
    rainNote = "";
    for (let i = 0; i < (h.time ?? []).length; i++) {
      const at = new Date(h.time[i]).getTime();
      if (at < now - 3600000 || at > now + 12 * 3600000) continue;
      if ((h.precipitation_probability[i] ?? 0) >= 50) {
        const code = h.weather_code[i];
        const what = code >= 71 && code <= 86 && !(code >= 80 && code <= 82) ? "Snow" : "Rain";
        rainNote = at <= now ? what + " now" : what + " from " + Qt.formatDateTime(new Date(at), "HH:mm");
        break;
      }
    }
    updated = Date.now();
    error = "";
  }

  // --- Finding a place (for the settings page) --------------------------------------------
  // [{ name, detail, latitude, longitude }]
  property var places: []
  property bool searching: false

  function search(name: string): void {
    if (name.trim().length < 2) {
      places = [];
      return;
    }
    searching = true;
    geocode.command = ["curl", "-sf", "--max-time", "15", "-G", "https://geocoding-api.open-meteo.com/v1/search",
                       "--data-urlencode", "name=" + name.trim(), "-d", "count=6", "-d", "language=en", "-d", "format=json"];
    geocode.running = true;
  }

  Process {
    id: geocode
    stdout: StdioCollector {
      onStreamFinished: {
        root.searching = false;
        let list = [];
        try {
          list = JSON.parse(text).results ?? [];
        } catch (e) {
          list = [];
        }
        root.places = list.map(p => ({
          name: p.name,
          detail: [p.admin1, p.country].filter(s => s && s !== "").join(", "),
          latitude: p.latitude,
          longitude: p.longitude
        }));
      }
    }
  }

  function choose(place: var): void {
    Config.weather.place = place.name + (place.detail ? ", " + place.detail.split(", ").pop() : "");
    Config.weather.latitude = place.latitude;
    Config.weather.longitude = place.longitude;
    places = [];
  }
}
