// Sustain 101 -- the in-app guide content. GENERATED from the guide-compile
// workflow (regenerate via tools/gen_guide.py, do not hand-edit). The single
// source of truth for every mechanism, rule, and feature, written for users.

class GuideTopic {
  final String heading;
  final String body;
  final List<String> bullets;
  const GuideTopic(this.heading, this.body, [this.bullets = const []]);
}

class GuideChapter {
  final String title;
  final String summary;
  final List<GuideTopic> topics;
  const GuideChapter(this.title, this.summary, this.topics);
}

const kSustain101 = <GuideChapter>[
  GuideChapter('Welcome to Sustain', 'What Sustain is, the belief behind it, and how a session works.', [
    GuideTopic(
      'Focus training, not just a timer',
      'A timer counts down. Sustain builds an ability. You practise concentrating deeply, and you practise recovering from it, so your focus grows stronger over time.\n\nThe hourglass on screen is the session itself. You set a small intention, flip it, and the sand carries your focus. When it runs out, the work is done.',
      ['Train your focus the way an athlete trains a muscle.', 'You build two skills: deep concentration, and recovering from it.', 'Everything works fully offline — your sessions and stats live only on your device.'],
    ),
    GuideTopic(
      'The belief behind it',
      'Focus is a skill you can build, with real training and real recovery. That belief shapes every part of the app.\n\nSo Sustain is honest about the hard part. The first stretch of any deep block is a struggle — that resistance is normal, expected, and temporary. Stay with it and focus takes over. Afterwards comes a short, phone-free rest so your attention can recover. Struggle, flow, recover: that is one full cycle, and the more you practise it, the longer you can hold a single block.',
    ),
  ]),
  GuideChapter('The Flow Method', 'Struggle, then Flow, then phone-free recovery — and why the struggle is the point.', [
    GuideTopic(
      'Struggle into Flow',
      'This is the core method. Set a small intention, flip the hourglass, and begin.\n\nThe opening stretch feels hard — that is the Struggle, your attention resisting the settle. It lasts roughly the first quarter of the block. Push through it and you cross into Flow: focus becomes absorbed and effortless, and the block carries itself the rest of the way.',
      ['The Struggle is normal and temporary, not a sign you are doing it wrong.', 'Staying with the resistance is what lets Flow take over.'],
    ),
    GuideTopic(
      'Phone-free recovery',
      'After the focus comes a short, deliberately boring break — no scrolling, no phone. Rest is when your focus actually recovers, the same way muscles recover between sets.\n\nStruggle, flow, recover. That full cycle is the method, and repeating it is how your focus grows.',
    ),
  ]),
  GuideChapter('The Three Modes', 'Flow, Pomodoro, and Custom — what each does and the real numbers behind them.', [
    GuideTopic(
      'Flow',
      'One unbroken block of deep focus. Set an intention, flip the hourglass, and ride the Struggle into Flow. Recovery happens afterwards, separately — there are no breaks inside the block.\n\nFlow is the heart of Sustain. It is the only mode that feeds your Focus Score and the only one that grows your Focus Stamina (both explained later). Pomodoro and Custom are useful on-ramps; Flow is the real method.',
      ['Pick a length: 15, 25, 30, 45, 60, or 90 min, or tap +5 to stretch it.', 'Finish a block to hold your stamina; go past it to grow it.', 'Focus Stamina — a length that learns from your recent Flow blocks — is a Pro feature; without Pro, Flow starts from a plain default.'],
    ),
    GuideTopic(
      'Pomodoro',
      'Fixed focus blocks with breaks between them. Pomodoro has two ways in.\n\nBy blocks is the classic version: pick a work/break length and how many blocks you want. A longer break lands on every fourth break, and the session always ends on a focus block — never a trailing break.\n\nBy duration sets your exact focus time and splits it into the number of blocks you choose, with automatic rests sized to the work (roughly one part rest to five parts focus). The blocks flex in length so your total focus time stays exact.',
      ['By blocks presets (work / short break): 25/5, 50/10, 52/17, 90/15.', 'Long break every 4th break: 15, 20, 25, or 30 min, matching each preset.', 'By duration: you choose the focus time and the block count; rests are automatic.'],
    ),
    GuideTopic(
      'Custom',
      'Design your own focus-and-break schedule. You set the total focus time, and Sustain keeps it exact — the last block absorbs any remainder so the blocks always add up to what you asked for.\n\nThere are two ways to place the breaks. By count spreads a chosen number of breaks evenly, splitting your focus into equal blocks. By interval takes a break after every set stretch of focus. Either way you pick the break length yourself (1 to 30 minutes), and the session ends on a focus block with no trailing rest.',
      ['Set the focus time, then place breaks by count or by interval.', 'You choose the break length (1–30 min); focus time always stays exact.'],
    ),
  ]),
  GuideChapter('A Focus Session', 'From intention to flip to finish — breaks, keeping going, and what counts.', [
    GuideTopic(
      'Setting an intention and beginning',
      'Before a session you can write a short intention — what you are focusing on. It is optional, but naming the work helps you commit to it.\n\nTap Begin and the hourglass flips upright, sand on top. That flip is the start. It flips again at the start of every new focus block — after each break, and whenever a block begins anew.',
    ),
    GuideTopic(
      'Breaks and auto-advance',
      'In Pomodoro and Custom, breaks sit between your focus blocks. By default breaks auto-advance: when one ends, the next focus block starts on its own.\n\nIf you prefer, you can have the session wait for you instead, pausing at the end of each break until you tap to continue. You can also skip a break at any time to start the next block early. This is a setting you control under Settings, Session.',
      ['Auto-advance breaks is the default; tap-to-continue is the alternative.', 'Skip a break whenever you like to start the next block early.'],
    ),
    GuideTopic(
      'Keep going, and Endless',
      'A Flow block runs to its length and then pauses at a completion point — it does not just end. From there you can collect the block, or choose Keep going: the hourglass refills and flips, and you drain the same block again, adding more focus. Time past your chosen length is overflow, and it rewards your Focus Score.\n\nIf you would rather never stop at the mark, turn on Endless flow before you begin (or switch to it near the end). An Endless block runs open-ended until you decide to end it. Both Keep going and Endless apply to single-block Flow, not to Pomodoro or Custom.',
      ['Keep going drains the same Flow block again; overflow rewards your Focus Score.', 'Endless flow runs open-ended until you end it yourself.'],
    ),
    GuideTopic(
      'Ending early, and what counts as completed',
      'You can end a session whenever you need to. Stopping before the mark lowers the completion of a Flow block, which pulls your Focus Score down — the honest cost of giving up. A session counts as completed only when it reaches its planned end.\n\nEvery mode records the focus you actually did — completed, ended early, or interrupted — so it still shows in your Today total and your history. The one exception: a Flow block under 2 minutes records nothing at all, so a quick false start never counts against you. Pomodoro and Custom keep any real focus.',
      ['Completed means the planned end was reached.', 'Sub-2-minute Flow blocks record nothing — no Today, no history, no score.', 'All modes log the real focus done; only Flow feeds the Focus Score.'],
    ),
  ]),
  GuideChapter('Staying Honest', 'What pausing and leaving cost, and why the limits exist.', [
    GuideTopic(
      'Leaving the app',
      'Once a block is running, leaving the app puts it at risk — we give you a short grace to come back, not a free pass.\n\nLeave while a block is running and you have 30 seconds. We send a push notification — "Come back to keep your block — you have 30 seconds before this block ends" — and tapping it returns you straight to the live session, which picks up where it left off. Stay away longer, or close the app, and the block ends, keeping the focus you had already done. No focus accrues while you are away.',
      ['Leave grace while running: 30 seconds, then the block ends.', 'Returning in time resumes the block seamlessly.', 'The "come back" prompt is a push notification because it fires while you are outside the app.'],
    ),
    GuideTopic(
      'Pausing',
      'Pausing is a deliberate tool, so it earns a longer window than leaving. On the free plan you get 3 pauses per session, each up to 3 minutes. When a pause reaches its cap you have a 15-second grace to resume, with a notification ("Your pause is up — return within 15 seconds") to nudge you back.\n\nRunning out of pauses never ends a block. The block simply keeps running and the Pause button rests with a quiet note that Pro unlocks more. With Pro, pauses are unlimited and each can last up to 10 minutes.',
      ['Free: 3 pauses per session, up to 3 minutes each.', 'Pro: unlimited pauses, up to 10 minutes each.', 'Pause-cap grace: 15 seconds to resume once a pause hits its cap.', 'Out of pauses only locks the Pause button — it never ends the session.'],
    ),
    GuideTopic(
      'Why it works this way',
      'If you could pause, pick up your phone, scroll, and resume with no cost, the number at the end would not mean much. The grace windows exist because real life interrupts — a knock at the door, a quick reply — and one short trip should not cost you the whole block. Past that, the session is honestly asking for your attention.\n\nTheme previews are exempt from all of this. A preview is a short, capped taste of a locked theme that records nothing, so none of these limits apply to it.',
    ),
  ]),
  GuideChapter('Focus Score & Stamina', 'The two numbers that track how deep your focus runs and how long you can hold it.', [
    GuideTopic(
      'Focus Score',
      'Your Focus Score is a single reading, 0 to 100, of how deep your recent focus runs. It is the sum of your last 10 Flow session scores divided by 10. Because the divisor is always 10, it ramps gently over your first several blocks, then settles into a rolling read of your recent ten.\n\nEach session is scored on how fully you reach the block you chose — finishing the length you set scores highest, stopping partway scores proportionally, and pushing past your length adds a small over-reach bonus. The Score moves gradually by design: it rewards showing up over chasing one perfect block.\n\nOnly Flow sessions of 2 minutes or more count toward it. Pomodoro and Custom do not, and a quick false start is ignored entirely.',
      ['0 to 100 — the average of your last ~10 Flow sessions.', 'Scored on how fully you reach your chosen block, plus a small over-reach bonus.', 'Flow only; sessions under 2 minutes are ignored.', 'Ramps over your first ~10 blocks, then becomes a rolling recent-10 average.', 'Open the Focus Score page any time to see exactly how it is built.'],
    ),
    GuideTopic(
      'Focus Stamina',
      'Focus Stamina is the length of deep focus you can hold in one unbroken block — the average of your recent qualifying Flow blocks, shown in minutes. It answers a simple question: how long can you stay in it before you need a break?\n\nIt only ever grows from real effort. Your first eligible Flow block sets the baseline — whatever you actually held becomes your starting stamina. After that, a block counts when you finish it, or when you sustain longer than your current stamina (an over-reach). Ending a block early, below your current stamina, is simply ignored, so a short give-up never pulls the number down.\n\nThe 90-minute mark you will see is a reference, not a cap — your stamina can and does pass it, and the chart stretches its axis once you do. Focus Stamina is a Pro feature; without it, Flow starts from a plain default length.',
      ['The length of unbroken Flow focus you can hold, averaged over recent qualifying blocks.', 'First eligible Flow block sets the baseline.', 'Grows when you finish a block or over-reach past it; early ends below it are ignored.', '90 minutes is a reference mark, not a ceiling. A Pro feature.'],
    ),
  ]),
  GuideChapter('Your Numbers', 'What every figure on your stats means, and which mode each one counts.', [
    GuideTopic(
      'The records',
      'These are the figures Sustain keeps for you. Almost all of them count focus from every mode — Flow, Pomodoro, and Custom alike — and any session that recorded real focus counts, whether you finished it or ended it early. The one exception is Completed.\n\nFlow sessions under 2 minutes are never stored, so a quick false start never appears anywhere.',
      ['Today — focus logged since midnight, across every mode.', 'Current streak — focused days counting back from today, with a one-day grace: a single missed day never breaks it, only two empty days in a row do.', 'Total focus — your lifetime focus across every session.', 'Average session — your typical focused time per session (a Pro stat).', 'Best streak — the longest run of focused days you have ever had (with the same one-day grace).', 'Longest session — your single longest unbroken block of recorded focus.', 'Sessions — the number of sessions that recorded real focus.', 'Completed — sessions carried all the way to the finish. The only figure that requires a fully completed session.', 'Active days — days that hold real focus (lifetime, and over the last 30 days).', 'Focusing since — the date of your very first focused session.'],
    ),
    GuideTopic(
      'Streaks and the heatmap',
      'A streak is a run of days with at least one focused session, counting back from today. It comes with a one-day grace: a single missed day never breaks your streak — only two empty days in a row do, so one slip is always forgiven. The moment you focus for any length today counts, and ending a session early still counts — the streak cares that you showed up, not how the session finished. A grace day keeps the run alive but does not add to the number; nothing is inflated.\n\nThe consistency heatmap is a grid of the last fifteen weeks, one square per day, weeks starting on Sunday. A square shades up as the day\'s focus passes roughly fifteen minutes, thirty, and an hour. Tap any square to read that day\'s focus and session count.',
      ['Under 15 min, 15–30, 30–60, 60+ — four shades, darker is deeper.', 'Empty squares are rest days, shown in the quiet base colour.', 'Future days are left blank.'],
    ),
    GuideTopic(
      'No manufactured guilt',
      'Sustain will never punish you for a missed day. A broken streak just starts a new one; the heatmap shows rest days plainly, with no red marks and no scolding. There are no ads and no guilt-trip notifications — only reminders you set yourself.\n\nThe numbers only ever move on real effort. A short session you give up on still records the focus you did, and your streak still holds — but it never drags your stamina or scores down. Each record shown really happened, and nothing is inflated to flatter you.',
    ),
  ]),
  GuideChapter('Insights', 'The full picture of your focus — what is free, what comes with Pro, and how each chart stays honest.', [
    GuideTopic(
      'The Insights page',
      'Insights gathers all of your focus data in one place, in two bands. The first is free and lifetime: your Records scorecard and the consistency heatmap. The second is the Pro depth band, a Week / Month / All view of your story over time.\n\nA short legend sits at the top of the depth band, because the source matters. Focus Score, Focus Stamina, and Follow-through follow your Flow sessions only. Everything else — focus over time, when you focus, by mode, and the records — counts all three modes together. Flow-only sections carry a small tag so you always know which is which.',
    ),
    GuideTopic(
      'Free: Records and consistency',
      'Without Pro you see the Records band — Total focus, Current streak, Best streak, Longest, Sessions, and Focusing-since — plus the consistency heatmap and a plain line like "You\'ve shown up 12 of the last 30 days."\n\nAverage session sits in the Records grid too, but as a Pro stat; until you upgrade, its tile invites you to Pro rather than showing a number.',
    ),
    GuideTopic(
      'Pro: the depth band',
      'Pro opens the Week / Month / All view. Two Flow-only line charts lead it: your Focus Score over time, and your Focus Stamina as it grows from your first recorded Flow block. The 90-minute deep-work mark is drawn as a reference, not a ceiling.\n\nBelow them: focus over time, with this period\'s total and an honest comparison to the last; when you focus, split into six parts of the day and the seven weekdays, with a gentle note on when you go deepest; follow-through, the share of your Flow sessions that reached their mark; and by mode, how your focus divides across the three. The band closes with your lifetime personal bests, each with the date it happened.',
      ['Flow-only: Focus Score, Focus Stamina, Follow-through.', 'All modes: focus over time, when you focus, by mode, and the records.', 'Each chart only speaks when there is enough real data; otherwise it shows a plain teaching line, never a fabricated one.'],
    ),
    GuideTopic(
      'Exporting your data',
      'Your history is yours, and you can take a copy two ways.\n\nWith Pro, from Insights, Export PDF report builds a clean, shareable Focus Report — your whole story in one document: a summary, your Focus Score and Stamina, the records scorecard, focus over time, where your time goes by mode, when you focus, consistency and streaks, follow-through, your personal bests, and a short glossary. It saves as sustain-focus-report.pdf.\n\nFrom the History screen, the share icon exports your raw session history as a CSV — free for everyone, because your data is yours — saved as sustain-focus-history.csv. Its columns are startedAt, mode, plannedMinutes, focusedMinutes, completed, abandoned, and intention — yours to keep or open in any spreadsheet.',
      ['PDF Focus Report (Insights) — the narrative, formatted to read and share. A Pro feature.', 'CSV export (History) — the raw rows, for your own analysis. Free for everyone.', 'Your data lives only on your device until you choose to share it.'],
    ),
  ]),
  GuideChapter('Sounds & Themes', 'Shape how Sustain sounds and looks — session cues, color themes, and how you own them.', [
    GuideTopic(
      'Session sounds',
      'Sustain marks each turn of a session with a gentle bell — when a session begins, when a break starts and ends, and when you finish. They are quiet ritual feedback, a soft signal you can let land without looking at the screen.\n\nThe cues stay out of your way. They mix with whatever else is playing, so your music or podcast keeps going underneath, and on iPhone they follow the silent switch. Turn them off any time under Settings, Session, Session sounds. They are on by default, and free — part of the core experience, never behind Pro.',
    ),
    GuideTopic(
      'Color themes',
      'A theme recolors the whole app and the hourglass at once — the background, the surfaces, the accent, and the falling sand. Each one is a single, cohesive mood. Sand, the warm desert default, is always free.\n\nLight, Dark, and Match system are a separate choice that sits on top of your theme. Every theme ships a full light and dark variant, so your look holds up whichever way you lean. Match system follows your phone and is the default.\n\nYou can try any locked theme before you decide. Preview drops the whole app into that theme while you browse. Starting a session while previewing runs a short, capped preview — the themed hourglass in motion for about ten seconds — that records nothing: no Focus Score, no streak, no history. It is a look, not free use.',
      ['Sand: the free default, always owned.', 'Nine premium themes, with Aurora as the flagship.', 'Each theme: a full light and dark palette and a matching hourglass.', 'Light / Dark / Match system is independent — pick your theme and your brightness separately.', 'Reach themes from Settings, Display, Themes.'],
    ),
    GuideTopic(
      'Owning a theme',
      'Premium themes can be bought one at a time, à la carte, or unlocked all together with Pro. A theme you buy à la carte is a one-time purchase you own forever — it does not depend on a subscription.\n\nWith a Pro subscription, every theme is yours while Pro is active, including any added later. If a Monthly or Yearly subscription lapses, the app quietly returns to Sand but never forgets your choice — renewing brings your look straight back. Pro Lifetime, like an à la carte purchase, keeps every theme for good.',
    ),
  ]),
  GuideChapter('Sustain Pro', 'What Pro unlocks, the three ways to get it, and restoring it.', [
    GuideTopic(
      'What Pro unlocks',
      'Pro opens up the full depth of Sustain. Where the free app shows your Records and consistency, Pro traces your whole focus story over time and gives you more room to work the way you want.\n\nEverything Pro unlocks runs on data the app already keeps on your device — it is the same focus history, shown in more depth.',
      ['Your full analytics: Focus Score and Focus Stamina over time, Average session, and Follow-through', 'Your peak focus window and your personal-bests timeline', 'A detailed PDF Focus Report (raw CSV export stays free)', 'Every color theme, now and every one added later', 'Unlimited, longer pauses mid-session (up to 10 minutes each)', 'Keep going on Pomodoro and Custom — add another block as a session ends', 'Session reuse — start again from a past session\'s setup', 'Focus Stamina sets your Flow length — your starting length learns from your recent blocks', 'Every Pro feature added in future, included'],
    ),
    GuideTopic(
      'The three tiers',
      'Pro comes three ways, all yours to use offline once unlocked. Monthly is the low-barrier way to try Pro. Yearly is the best value and where most people land. Lifetime is a single one-time payment — Pro forever, with no subscription and no renewal, and every Pro feature we add later is included automatically.\n\nMonthly and Yearly auto-renew until you cancel, which you can do any time via Manage subscription (it opens Google Play). Lifetime and à la carte theme purchases are one-time and never expire.\n\nPrices are shown live from the store in your local currency, so this guide does not list them — open Settings, Sustain Pro to see current prices.',
    ),
    GuideTopic(
      'Restoring your purchase',
      'If you reinstall Sustain or move to a new phone, tap Restore purchases on the Pro screen. It checks your Google account and brings back anything you have bought — Pro and any themes you own.\n\nPurchases are tied to your store account, not to your backup file. That is why Pro and themes restore through Google Play rather than through Backup and Restore.',
    ),
  ]),
  GuideChapter('Your Data & Privacy', 'Everything stays on your device. Back it up, restore it, or wipe it — your call.', [
    GuideTopic(
      'Fully offline, on your device',
      'Sustain works fully offline. Your sessions, stats, and profile live only on this device. There is no account, no cloud, and no analytics — we collect nothing about how you use the app.\n\nThe one place data leaves your phone is a purchase: buying Pro or a theme goes through Google Play and the billing service, which handle the payment using an anonymous id and the purchase receipt. That is billing, not behavior tracking — we never see your payment details.',
    ),
    GuideTopic(
      'Backup and restore',
      'Because everything lives on-device, Sustain gives you a manual backup so you never lose your history when you switch phones. Settings, Your data, Back up your data writes a single file and opens the share sheet — save it wherever you like (Drive, Files, email).\n\nThe file captures your full focus history: every session, your settings (Focus Stamina included), your profile and avatar, and your theme choice. It does not include Pro or theme ownership — those restore from Google Play, not from a file.\n\nRestore is safe by design. Your sessions are merged in, matched by a stable id, so nothing already on the device is deleted and duplicates are skipped; it tells you how many new sessions it added. Your profile and settings are replaced by the backup\'s.',
    ),
    GuideTopic(
      'Clearing your data',
      'Clear all data, at the bottom of Settings, is the full reset: it permanently deletes every session, your stats, your profile, and your preferences, and returns the app to a fresh start. It cannot be undone, so it asks you to confirm. If there is any chance you will want it back, back up first.',
    ),
    GuideTopic(
      'What\'s coming: cloud sync',
      'Today\'s backup is the manual, private safety net. Optional cloud sync across devices is planned for a later version, so your focus history can follow you automatically. It will be opt-in and built on the same honest, privacy-first footing — on-device first, with sync as a choice, never a requirement.',
    ),
  ]),
];
