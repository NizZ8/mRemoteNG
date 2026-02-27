#!/usr/bin/env python3
"""Analyze orchestrator cost, waste, and bandwidth usage patterns."""
import sys, re, json
from datetime import datetime, timedelta
from collections import defaultdict
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

LOG = '.project-roadmap/scripts/orchestrator.log'
lines = open(LOG, encoding='utf-8', errors='replace').readlines()

def parse_ts(line):
    m = re.match(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
    return datetime.strptime(m.group(1), '%Y-%m-%d %H:%M:%S') if m else None

# Patterns
PAT_TOKEN = re.compile(r'\[TOKENS\] (\d+) in / (\d+) out / \$([0-9.]+) \(([^)]+)\)')
PAT_ISSUE = re.compile(r'\[(\d+)/(\d+)\] Issue #(\d+): (.+)')
PAT_SESSION = re.compile(r'TEST HYGIENE \(pre-flight\)')
PAT_COMMIT = re.compile(r'committed ([0-9a-f]{7,8})')
PAT_ALL_FAILED = re.compile(r'All agents in chain failed')
PAT_OPUS_FAILED = re.compile(r'Opus fallback also failed')
PAT_OPUS_FB = re.compile(r'retrying.*with Opus')
PAT_MODEL = re.compile(r'\[CLAUDE\] model=(\S+) task=(\S+)')
PAT_BUILD = re.compile(r'\[BUILD\] (OK|.*DLLs.*missing|.*FAIL)')
PAT_TEST_OK = re.compile(r'\[TEST\] OK')
PAT_TEST_FAIL = re.compile(r'\[TEST\] FAILED')

today = datetime.now().strftime('%Y-%m-%d')
task_type = 'unknown'
issue_num = None
token_entries = []
sessions = []

for line in lines:
    ts = parse_ts(line)
    if not ts:
        continue

    if PAT_SESSION.search(line):
        sessions.append({'start': ts, 'cost': 0.0, 'entries': []})

    m = PAT_ISSUE.search(line)
    if m:
        issue_num = int(m.group(3))

    m = PAT_MODEL.search(line)
    if m:
        task_type = m.group(2)

    m = PAT_TOKEN.search(line)
    if m:
        inp, out, cost, model = int(m.group(1)), int(m.group(2)), float(m.group(3)), m.group(4)
        entry = {'ts': ts, 'model': model, 'input': inp, 'output': out, 'cost': cost,
                 'task': task_type, 'issue': issue_num, 'day': ts.strftime('%Y-%m-%d')}
        token_entries.append(entry)
        if sessions:
            sessions[-1]['cost'] += cost
            sessions[-1]['entries'].append(entry)

# === 1. COST BY TASK TYPE ===
by_task = defaultdict(lambda: {'count': 0, 'cost': 0.0, 'input': 0, 'output': 0})
for e in token_entries:
    t = by_task[e['task']]
    t['count'] += 1
    t['cost'] += e['cost']
    t['input'] += e['input']
    t['output'] += e['output']

print('=== 1. COST BY TASK TYPE (all time) ===')
print(f'  {"Task":<20} {"Calls":>6} {"Cost":>10} {"Avg":>8} {"Out tok":>10}')
for task in sorted(by_task, key=lambda k: by_task[k]['cost'], reverse=True):
    t = by_task[task]
    avg = t['cost'] / t['count'] if t['count'] else 0
    print(f'  {task:<20} {t["count"]:>6} ${t["cost"]:>8.2f} ${avg:>6.2f} {t["output"]:>10}')
total_cost = sum(t['cost'] for t in by_task.values())
print(f'  {"TOTAL":<20} {sum(t["count"] for t in by_task.values()):>6} ${total_cost:>8.2f}')

# === 2. COST BY MODEL ===
print()
by_model = defaultdict(lambda: {'count': 0, 'cost': 0.0})
for e in token_entries:
    m = by_model[e['model']]
    m['count'] += 1
    m['cost'] += e['cost']

print('=== 2. COST BY MODEL ===')
for model in sorted(by_model, key=lambda k: by_model[k]['cost'], reverse=True):
    m = by_model[model]
    avg = m['cost'] / m['count'] if m['count'] else 0
    pct = int(m['cost'] / total_cost * 100) if total_cost else 0
    print(f'  {model:<28} {m["count"]:>4} calls  ${m["cost"]:>8.2f} ({pct}%)  avg ${avg:.2f}/call')

# === 3. COST BY DAY ===
print()
by_day = defaultdict(lambda: {'cost': 0.0, 'calls': 0, 'by_task': defaultdict(float)})
for e in token_entries:
    d = by_day[e['day']]
    d['cost'] += e['cost']
    d['calls'] += 1
    d['by_task'][e['task']] += e['cost']

print('=== 3. COST BY DAY ===')
for day in sorted(by_day):
    d = by_day[day]
    breakdown = ', '.join(f'{t}:${c:.1f}' for t, c in sorted(d['by_task'].items(), key=lambda x: -x[1])[:3])
    print(f'  {day}: ${d["cost"]:>7.2f} ({d["calls"]:>3} calls) -- {breakdown}')

# === 4. WASTE ANALYSIS ===
print()
print('=== 4. WASTE ANALYSIS (money spent on issues that never committed) ===')

# Re-parse for per-issue tracking
issue_costs = defaultdict(lambda: {'total': 0.0, 'triage': 0.0, 'pre_analysis': 0.0,
                                    'implement': 0.0, 'default': 0.0, 'other': 0.0,
                                    'committed': False, 'failed': False, 'opus_fb': False,
                                    'attempts': 0})
cur_issue = None
cur_task = 'unknown'

for line in lines:
    ts = parse_ts(line)
    if not ts:
        continue

    m = PAT_ISSUE.search(line)
    if m:
        cur_issue = int(m.group(3))

    m = PAT_MODEL.search(line)
    if m:
        cur_task = m.group(2)

    m = PAT_TOKEN.search(line)
    if m and cur_issue:
        cost = float(m.group(3))
        ic = issue_costs[cur_issue]
        ic['total'] += cost
        ic['attempts'] += 1
        if cur_task in ic:
            ic[cur_task] += cost
        else:
            ic['other'] += cost

    if PAT_COMMIT.search(line) and cur_issue:
        issue_costs[cur_issue]['committed'] = True
    if PAT_ALL_FAILED.search(line) and cur_issue:
        issue_costs[cur_issue]['failed'] = True
    if PAT_OPUS_FB.search(line) and cur_issue:
        issue_costs[cur_issue]['opus_fb'] = True

committed = {n: ic for n, ic in issue_costs.items() if ic['committed']}
failed = {n: ic for n, ic in issue_costs.items() if not ic['committed']}
committed_cost = sum(ic['total'] for ic in committed.values())
wasted_cost = sum(ic['total'] for ic in failed.values())
total_issues_cost = committed_cost + wasted_cost
waste_pct = int(wasted_cost / total_issues_cost * 100) if total_issues_cost else 0

print(f'  Committed: {len(committed)} issues, ${committed_cost:.2f}')
print(f'    Avg cost per successful issue: ${committed_cost/len(committed):.2f}' if committed else '')
print(f'  Failed:    {len(failed)} issues, ${wasted_cost:.2f}')
print(f'    Avg cost per failed issue:     ${wasted_cost/len(failed):.2f}' if failed else '')
print(f'  WASTE RATIO: {waste_pct}% of spend went to issues that never committed')

# Multi-attempt issues (retried across sessions)
multi_attempt = {n: ic for n, ic in issue_costs.items() if ic['attempts'] > 2}
multi_cost = sum(ic['total'] for ic in multi_attempt.values())
print(f'\n  Multi-attempt issues (>2 API calls): {len(multi_attempt)}, ${multi_cost:.2f}')

print('\n  Top 10 most expensive FAILED issues:')
for num, ic in sorted(failed.items(), key=lambda x: -x[1]['total'])[:10]:
    parts = []
    if ic['pre_analysis'] > 0: parts.append(f'preA:${ic["pre_analysis"]:.2f}')
    if ic['implement'] > 0: parts.append(f'impl:${ic["implement"]:.2f}')
    if ic['default'] > 0: parts.append(f'opus_fb:${ic["default"]:.2f}')
    if ic['triage'] > 0: parts.append(f'tri:${ic["triage"]:.2f}')
    opus = ' [opus_fb]' if ic['opus_fb'] else ''
    print(f'    #{num:<6} ${ic["total"]:>6.2f}  ({ic["attempts"]} calls) {" + ".join(parts)}{opus}')

print('\n  Top 10 most expensive SUCCESSFUL issues:')
for num, ic in sorted(committed.items(), key=lambda x: -x[1]['total'])[:10]:
    parts = []
    if ic['pre_analysis'] > 0: parts.append(f'preA:${ic["pre_analysis"]:.2f}')
    if ic['implement'] > 0: parts.append(f'impl:${ic["implement"]:.2f}')
    if ic['default'] > 0: parts.append(f'opus_fb:${ic["default"]:.2f}')
    opus = ' [opus_fb]' if ic['opus_fb'] else ''
    print(f'    #{num:<6} ${ic["total"]:>6.2f}  ({ic["attempts"]} calls){opus}')

# === 5. PRE-ANALYSIS ROI ===
print()
print('=== 5. PRE-ANALYSIS OVERHEAD (now disabled) ===')
pa = by_task.get('pre_analysis', {'cost': 0, 'count': 0})
print(f'  Total: ${pa["cost"]:.2f} across {pa["count"]} calls')
if pa['count']:
    print(f'  Avg: ${pa["cost"]/pa["count"]:.2f}/call')

# === 6. DOUBLE-PAY: Sonnet fail then Opus retry ===
print()
print('=== 6. DOUBLE-PAY PATTERN (Sonnet fail -> Opus retry) ===')
opus_fb_issues = {n: ic for n, ic in issue_costs.items() if ic['opus_fb']}
sonnet_wasted_on_fb = sum(ic['implement'] for ic in opus_fb_issues.values())
opus_fb_cost = sum(ic['default'] for ic in opus_fb_issues.values())
print(f'  Issues that hit Opus fallback: {len(opus_fb_issues)}')
print(f'  Sonnet impl cost (wasted on these): ${sonnet_wasted_on_fb:.2f}')
print(f'  Opus fallback cost: ${opus_fb_cost:.2f}')
print(f'  Total double-pay: ${sonnet_wasted_on_fb + opus_fb_cost:.2f}')
if opus_fb_issues:
    committed_after_fb = len([ic for ic in opus_fb_issues.values() if ic['committed']])
    print(f'  Of which committed after Opus: {committed_after_fb}/{len(opus_fb_issues)} ({int(committed_after_fb/len(opus_fb_issues)*100)}%)')

# === 7. SESSION CHURN TODAY ===
print()
today_sessions = [s for s in sessions if s['start'].strftime('%Y-%m-%d') == today]
print(f'=== 7. SESSION CHURN TODAY ({len(today_sessions)} sessions) ===')
productive = 0
wasted_sessions = 0
for idx, s in enumerate(today_sessions):
    end = today_sessions[idx + 1]['start'] if idx + 1 < len(today_sessions) else datetime.now()
    dur = (end - s['start']).total_seconds() / 60
    status = 'productive' if s['cost'] > 0.5 else 'overhead'
    if status == 'overhead':
        wasted_sessions += 1
    else:
        productive += 1
    print(f'  S{idx+1:>2}: {s["start"].strftime("%H:%M")} ({dur:>5.0f}min) ${s["cost"]:>6.2f} [{status}] ({len(s["entries"])} calls)')

print(f'\n  Productive sessions: {productive}')
print(f'  Overhead sessions (restarts, config): {wasted_sessions}')
if today_sessions:
    overhead_time = sum(
        (today_sessions[i+1]['start'] - today_sessions[i]['start']).total_seconds() / 60
        for i in range(len(today_sessions) - 1)
        if today_sessions[i]['cost'] <= 0.5
    )
    print(f'  Estimated time lost to restarts: ~{overhead_time:.0f} min')

# === 8. TOKEN VOLUME ANALYSIS ===
print()
print('=== 8. TOKEN VOLUME (output tokens = biggest cost driver) ===')
by_task_vol = defaultdict(lambda: {'calls': 0, 'total_in': 0, 'total_out': 0, 'max_out': 0})
for e in token_entries:
    d = by_task_vol[e['task']]
    d['calls'] += 1
    d['total_in'] += e['input']
    d['total_out'] += e['output']
    d['max_out'] = max(d['max_out'], e['output'])

print(f'  {"Task":<16} {"Calls":>5} {"Avg In":>8} {"Avg Out":>8} {"Max Out":>8}')
for task in sorted(by_task_vol, key=lambda k: by_task_vol[k]['total_out'], reverse=True):
    d = by_task_vol[task]
    avg_in = d['total_in'] // d['calls']
    avg_out = d['total_out'] // d['calls']
    print(f'  {task:<16} {d["calls"]:>5} {avg_in:>8} {avg_out:>8} {d["max_out"]:>8}')

total_out = sum(d['total_out'] for d in by_task_vol.values())
total_in = sum(d['total_in'] for d in by_task_vol.values())
print(f'  {"TOTAL":<16} {len(token_entries):>5} {total_in//len(token_entries):>8} {total_out//len(token_entries):>8}')
print(f'  Output/Input ratio: {total_out/total_in:.1f}x (output costs 5x more per token)')

# === 9. COST PER COMMIT EVOLUTION ===
print()
print('=== 9. COST PER COMMIT BY DAY (learning curve?) ===')
daily = defaultdict(lambda: {'commits': 0, 'cost': 0.0, 'failures': 0, 'model_costs': defaultdict(float)})
day_track = None
for line in lines:
    ts = parse_ts(line)
    if ts:
        day_track = ts.strftime('%Y-%m-%d')
    m = PAT_TOKEN.search(line)
    if m and day_track:
        cost = float(m.group(3))
        model = m.group(4)
        daily[day_track]['cost'] += cost
        daily[day_track]['model_costs'][model] += cost
    if PAT_COMMIT.search(line) and day_track:
        daily[day_track]['commits'] += 1
    if PAT_ALL_FAILED.search(line) and day_track:
        daily[day_track]['failures'] += 1

print(f'  {"Day":<12} {"Commits":>7} {"Fail":>5} {"Rate":>5} {"Cost":>8} {"$/commit":>9} {"Sonnet":>8} {"Opus":>8}')
for day in sorted(daily):
    d = daily[day]
    cpc = d['cost'] / d['commits'] if d['commits'] else 0
    total_att = d['commits'] + d['failures']
    rate = int(d['commits'] / total_att * 100) if total_att else 0
    sonnet_c = sum(v for k, v in d['model_costs'].items() if 'sonnet' in k)
    opus_c = sum(v for k, v in d['model_costs'].items() if 'opus' in k)
    cpc_str = f'${cpc:.2f}' if d['commits'] else 'N/A'
    print(f'  {day:<12} {d["commits"]:>7} {d["failures"]:>5} {rate:>4}% ${d["cost"]:>7.2f} {cpc_str:>9} ${sonnet_c:>6.2f} ${opus_c:>6.2f}')

# === 10. TRIAGE EFFICIENCY ===
print()
print('=== 10. TRIAGE vs IMPLEMENT RATIO ===')
triage_entries = [e for e in token_entries if e['task'] == 'triage']
impl_entries = [e for e in token_entries if e['task'] == 'implement']
triage_cost = sum(e['cost'] for e in triage_entries)
impl_cost = sum(e['cost'] for e in impl_entries)
print(f'  Triage:  {len(triage_entries)} calls, ${triage_cost:.2f} total, ${triage_cost/max(len(triage_entries),1):.2f}/call')
print(f'  Implement: {len(impl_entries)} calls, ${impl_cost:.2f} total, ${impl_cost/max(len(impl_entries),1):.2f}/call')
if impl_entries:
    ratio = len(triage_entries) / len(impl_entries)
    print(f'  Ratio: {ratio:.1f}:1 triage:implement')
    triage_that_led_to_impl = len(set(e['issue'] for e in impl_entries))
    triage_unique = len(set(e['issue'] for e in triage_entries))
    conversion = int(triage_that_led_to_impl / triage_unique * 100) if triage_unique else 0
    print(f'  Triage conversion: {triage_that_led_to_impl}/{triage_unique} triaged issues got implemented ({conversion}%)')

# === 11. HEAVY RETRIES ===
print()
print('=== 11. TOP MONEY SINKS (5+ API calls per issue) ===')
issue_attempts = defaultdict(lambda: {'calls': 0, 'cost': 0.0, 'committed': False, 'tasks': set()})
cur_issue2 = None
cur_task2 = 'unknown'
for line in lines:
    m = PAT_ISSUE.search(line)
    if m:
        cur_issue2 = int(m.group(3))
    m = PAT_MODEL.search(line)
    if m:
        cur_task2 = m.group(2)
    m = PAT_TOKEN.search(line)
    if m and cur_issue2:
        cost = float(m.group(3))
        ia = issue_attempts[cur_issue2]
        ia['calls'] += 1
        ia['cost'] += cost
        ia['tasks'].add(cur_task2)
    if PAT_COMMIT.search(line) and cur_issue2:
        issue_attempts[cur_issue2]['committed'] = True

heavy = {n: ia for n, ia in issue_attempts.items() if ia['calls'] >= 5}
heavy_cost = sum(ia['cost'] for ia in heavy.values())
heavy_ok = sum(1 for ia in heavy.values() if ia['committed'])
print(f'  {len(heavy)} issues with 5+ calls, total ${heavy_cost:.2f}, {heavy_ok} committed')
for num, ia in sorted(heavy.items(), key=lambda x: -x[1]['cost']):
    status = 'OK' if ia['committed'] else 'FAIL'
    tasks = ', '.join(sorted(ia['tasks']))
    print(f'    #{num}: {ia["calls"]} calls, ${ia["cost"]:.2f} [{status}] ({tasks})')

# === 12. SUMMARY & RECOMMENDATIONS ===
print()
print('=' * 65)
print('=== 12. SUMMARY & ACTIONABLE RECOMMENDATIONS ===')
print('=' * 65)
print(f'  Total API spend: ${total_cost:.2f}')
print(f'  Total commits: {sum(d["commits"] for d in daily.values())}')
avg_cpc = total_cost / max(sum(d["commits"] for d in daily.values()), 1)
print(f'  Avg cost per commit: ${avg_cpc:.2f}')
print()
print('  WASTE BREAKDOWN:')
print(f'    Double-pay (Sonnet+Opus):   ${sonnet_wasted_on_fb + opus_fb_cost:.2f} ({int((sonnet_wasted_on_fb+opus_fb_cost)/total_cost*100)}%) ** BIGGEST **')
print(f'    Failed issues (no commit):  ${wasted_cost:.2f} ({waste_pct}%)')
print(f'    Pre-analysis (disabled):    ${pa["cost"]:.2f} (<1%)')
print(f'    Session restarts today:     {len(today_sessions)} ({wasted_sessions} overhead, ~{overhead_time:.0f} min)')
print()
print('  RECOMMENDATIONS:')
print('  1. DONE: Switch to Opus-only eliminates $87 double-pay waste (27% of total)')
print('  2. Cap retries per issue (max 2 attempts) to limit money sinks')
print(f'     Top 5 money sinks alone cost ${sum(ia["cost"] for ia in sorted(heavy.values(), key=lambda x: -x["cost"])[:5]):.2f}')
print('  3. Mark persistent failures as needs_human after 2 failed attempts')
print(f'  4. Triage is cheap (${triage_cost:.2f} total, {int(triage_cost/total_cost*100)}%) - not worth optimizing')
print(f'  5. Output tokens ({total_out:,}) cost ~5x input ({total_in:,}) - consider --max-turns limits')
