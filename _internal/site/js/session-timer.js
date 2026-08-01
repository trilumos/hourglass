(function (root) {
  function create(segments, opts) {
    opts = opts || {};
    var now = opts.now || function () { return Date.now(); };
    var endless = !!opts.endless;
    var startTs = null, pausedMs = 0, pauseStart = null;
    function elapsedMs() {
      if (startTs == null) return 0;
      var live = pauseStart != null ? (now() - pauseStart) : 0;
      return now() - startTs - pausedMs - live;
    }
    function totalMs() {
      if (endless) return 0;
      return segments.reduce(function (a, s) { return a + s.min * 60000; }, 0);
    }
    function progress() {
      var e = elapsedMs();
      if (endless) return { done:false, segIndex:0, kind:'focus', remainingMs:0, elapsedMs:e };
      var acc = 0;
      for (var i = 0; i < segments.length; i++) {
        var segMs = segments[i].min * 60000;
        if (e < acc + segMs) return { done:false, segIndex:i, kind:segments[i].kind, remainingMs:(acc+segMs)-e, elapsedMs:e };
        acc += segMs;
      }
      return { done:true, segIndex:segments.length-1, kind:(segments[segments.length-1]||{}).kind, remainingMs:0, elapsedMs:e };
    }
    return {
      start:  function () { if (startTs == null) startTs = now(); },
      pause:  function () { if (pauseStart == null) pauseStart = now(); },
      resume: function () { if (pauseStart != null) { pausedMs += now() - pauseStart; pauseStart = null; } },
      elapsedMs: elapsedMs, totalMs: totalMs, progress: progress,
      isPaused: function () { return pauseStart != null; }
    };
  }
  var API = { create: create };
  if (typeof module !== 'undefined' && module.exports) module.exports = API;
  root.SessionTimer = API;
})(typeof window !== 'undefined' ? window : this);

// (place at bottom of file, after the module — written first for TDD)
if (typeof process !== 'undefined' && process.argv && process.argv.indexOf('--test') !== -1) {
  var T = module.exports, n = 0, clock = 0, now = function () { return clock; };
  function ok(c, m) { n++; if (!c) { console.error('FAIL: ' + m); process.exit(1); } }
  var segs = [{kind:'focus',min:25},{kind:'rest',min:5},{kind:'focus',min:25}]; // 25+5+25 = 55 min

  // wall-clock accuracy across a backgrounded gap (no rAF drift)
  clock = 0; var e = T.create(segs, {now:now}); e.start();
  clock = 90000;                                  // jump 90s (as if tab was backgrounded)
  ok(e.elapsedMs() === 90000, 'elapsed tracks wall clock across a gap');

  // pause/resume math
  clock = 0; e = T.create(segs, {now:now}); e.start();
  clock = 10000; e.pause(); clock = 25000; e.resume(); // paused 15s
  clock = 30000;
  ok(e.elapsedMs() === 15000, 'pause/resume subtracts paused time (30s - 15s paused = 15s)');

  // segment mapping
  clock = 0; e = T.create(segs, {now:now}); e.start();
  clock = 24*60000; var p = e.progress();
  ok(p.segIndex===0 && p.kind==='focus' && p.remainingMs===60000, 'at 24m: focus seg0, 1m left');
  clock = 26*60000; p = e.progress();
  ok(p.segIndex===1 && p.kind==='rest', 'at 26m: rest seg1');
  clock = 31*60000; p = e.progress();
  ok(p.segIndex===2 && p.kind==='focus', 'at 31m: focus seg2');
  clock = 56*60000; p = e.progress();
  ok(p.done === true, 'at 56m: done');

  // endless counts up, never done
  clock = 0; e = T.create([{kind:'focus',min:0}], {now:now, endless:true}); e.start();
  clock = 999*60000; p = e.progress();
  ok(p.done===false && p.kind==='focus' && p.elapsedMs===999*60000, 'endless counts up, never done');

  // totalMs
  clock = 0; e = T.create(segs, {now:now});
  ok(e.totalMs() === 55*60000, 'totalMs sums segment durations (55 min)');
  var ee = T.create([{kind:'focus',min:0}], {now:now, endless:true});
  ok(ee.totalMs() === 0, 'endless totalMs is 0');

  // isPaused transitions
  clock = 0; e = T.create(segs, {now:now}); e.start();
  ok(e.isPaused() === false, 'not paused initially');
  clock = 1000; e.pause();  ok(e.isPaused() === true,  'paused after pause()');
  clock = 2000; e.resume(); ok(e.isPaused() === false, 'not paused after resume()');

  // elapsed is frozen while paused (live-pause query)
  clock = 0; e = T.create(segs, {now:now}); e.start();
  clock = 5000; e.pause(); clock = 9999;
  ok(e.elapsedMs() === 5000, 'elapsed frozen while paused (query mid-pause)');

  console.log('session-timer: ' + n + ' checks passed');
}
