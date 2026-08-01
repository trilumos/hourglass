// Location → real sunrise/sunset for the day cycle. Default path is timezone → representative coords → SunCalc
// (no permission prompt, privacy-clean; master spec §5). An optional exact-Geolocation upgrade can come later.
// suncalc is CommonJS (module.exports = SunCalc); default-import fails under rolldown, so namespace + interop.
import * as SunCalcNS from 'suncalc';
const SunCalc = SunCalcNS.default || SunCalcNS;

// Representative [lat, lng] per IANA timezone (major zones by population). Enough to cover most visitors;
// anything unlisted falls back to the zone's standard meridian (from the UTC offset) + a mid latitude.
const TZ = {
  'Asia/Kolkata':[23.5,80.0], 'Asia/Karachi':[24.9,67.0], 'Asia/Dhaka':[23.8,90.4], 'Asia/Kathmandu':[27.7,85.3],
  'Asia/Colombo':[6.9,79.9], 'Asia/Dubai':[25.2,55.3], 'Asia/Tehran':[35.7,51.4], 'Asia/Riyadh':[24.7,46.7],
  'Asia/Baghdad':[33.3,44.4], 'Asia/Jerusalem':[31.8,35.2], 'Asia/Istanbul':[41.0,29.0], 'Europe/Istanbul':[41.0,29.0],
  'Asia/Bangkok':[13.8,100.5], 'Asia/Ho_Chi_Minh':[10.8,106.7], 'Asia/Jakarta':[-6.2,106.8], 'Asia/Singapore':[1.35,103.8],
  'Asia/Kuala_Lumpur':[3.1,101.7], 'Asia/Manila':[14.6,121.0], 'Asia/Shanghai':[31.2,121.5], 'Asia/Hong_Kong':[22.3,114.2],
  'Asia/Taipei':[25.0,121.5], 'Asia/Tokyo':[35.7,139.7], 'Asia/Seoul':[37.6,127.0], 'Asia/Yangon':[16.8,96.2],
  'Asia/Tashkent':[41.3,69.2], 'Asia/Almaty':[43.2,76.9],
  'Europe/London':[51.5,-0.1], 'Europe/Paris':[48.9,2.3], 'Europe/Berlin':[52.5,13.4], 'Europe/Madrid':[40.4,-3.7],
  'Europe/Rome':[41.9,12.5], 'Europe/Moscow':[55.8,37.6], 'Europe/Athens':[38.0,23.7], 'Europe/Amsterdam':[52.4,4.9],
  'Europe/Warsaw':[52.2,21.0], 'Europe/Lisbon':[38.7,-9.1], 'Europe/Dublin':[53.3,-6.3], 'Europe/Kyiv':[50.5,30.5],
  'Europe/Stockholm':[59.3,18.1], 'Europe/Bucharest':[44.4,26.1], 'Europe/Vienna':[48.2,16.4], 'Europe/Madrid ':[40.4,-3.7],
  'Africa/Cairo':[30.0,31.2], 'Africa/Lagos':[6.5,3.4], 'Africa/Johannesburg':[-26.2,28.0], 'Africa/Nairobi':[-1.3,36.8],
  'Africa/Casablanca':[33.6,-7.6], 'Africa/Algiers':[36.8,3.1],
  'America/New_York':[40.7,-74.0], 'America/Chicago':[41.9,-87.6], 'America/Denver':[39.7,-105.0],
  'America/Los_Angeles':[34.1,-118.2], 'America/Phoenix':[33.4,-112.1], 'America/Toronto':[43.7,-79.4],
  'America/Mexico_City':[19.4,-99.1], 'America/Sao_Paulo':[-23.5,-46.6], 'America/Argentina/Buenos_Aires':[-34.6,-58.4],
  'America/Bogota':[4.6,-74.1], 'America/Lima':[-12.0,-77.0], 'America/Santiago':[-33.4,-70.6], 'America/Anchorage':[61.2,-149.9],
  'Pacific/Honolulu':[21.3,-157.9], 'Australia/Sydney':[-33.9,151.2], 'Australia/Melbourne':[-37.8,145.0],
  'Australia/Perth':[-31.9,115.9], 'Australia/Brisbane':[-27.5,153.0], 'Pacific/Auckland':[-36.8,174.8],
};

export function userCoords(){
  try {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (TZ[tz]) return { lat: TZ[tz][0], lng: TZ[tz][1], tz };
    const lng = -new Date().getTimezoneOffset() / 4;   // zone's standard meridian (15°/h)
    return { lat: 25, lng, tz };                        // populated-band fallback latitude
  } catch (e) {
    return { lat: 25, lng: 0, tz: 'UTC' };
  }
}

// Today's LOCAL sunrise/sunset as decimal hours. Near the poles (no rise/set that day) SunCalc returns an
// invalid Date — fall back to the reference 6:00 / 18:30 so the warp becomes a no-op.
const hrs = d => (d instanceof Date && !isNaN(d.getTime())) ? d.getHours() + d.getMinutes()/60 + d.getSeconds()/3600 : NaN;

export function localSunTimes(date = new Date()){
  const { lat, lng, tz } = userCoords();
  const t = SunCalc.getTimes(date, lat, lng);
  let sr = hrs(t.sunrise), ss = hrs(t.sunset);
  if (isNaN(sr) || isNaN(ss) || ss <= sr) { sr = 6.0; ss = 18.5; }
  return { sr, ss, lat, lng, tz };
}

// Optional exact-location upgrade: real device Geolocation → precise local sunrise/sunset (a big timezone like
// Asia/Kolkata spans ~30° of longitude, so the representative coord can be ~30–60 min off). Prompts once; on
// grant it calls cb(sr, ss) and the warp switches to the exact times. Denied/unavailable → timezone default stays.
export function preciseSunTimes(cb){
  try {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(function(pos){
      const t = SunCalc.getTimes(new Date(), pos.coords.latitude, pos.coords.longitude);
      const sr = hrs(t.sunrise), ss = hrs(t.sunset);
      if (!isNaN(sr) && !isNaN(ss) && ss > sr) cb(sr, ss);
    }, function(){}, { timeout: 8000, maximumAge: 3600000, enableHighAccuracy: false });
  } catch (e) {}
}
