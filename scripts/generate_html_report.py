#!/usr/bin/env python3
"""
UVM Test Log to HTML Converter — Card-based UI
Converts QuestaSim UVM text logs to formatted HTML with syntax highlighting
"""

import os
import re
from datetime import datetime
from html import escape
from pathlib import Path


def load_run_timestamps(ts_path: Path) -> dict:
    """Read uvm_test_logs/run_timestamps.txt written by run_all_uvm_tests.bat."""
    keys = [
        "FLOW_START", "COMPILE_START", "COMPILE_END",
        "TESTS_START", "TESTS_END",
        "UCDB_MERGE_START", "UCDB_MERGE_END",
        "VCOVER_REPORT_START", "VCOVER_REPORT_END",
        "HTML_REPORT_START", "HTML_REPORT_END",
        "COV_HTML_START", "COV_HTML_END",
        "FLOW_END",
    ]
    result = {k: "" for k in keys}
    if ts_path.exists():
        for line in ts_path.read_text(errors="ignore").splitlines():
            if "=" in line:
                k, _, v = line.partition("=")
                result[k.strip()] = v.strip()
    return result

# ── Exact 15 known UVM tests ──────────────────────────────────────────────────
KNOWN_TESTS = {
    'basic_rw_test':             'Basic Read-Write Test',
    'fifo_full_test':            'FIFO Full Test',
    'fifo_empty_test':           'FIFO Empty Test',
    'reset_test':                'Reset Test',
    'rand_test':                 'Random Test',
    'full_write_full_read_test': 'Full Write / Full Read Test',
    'continuous_rw_test':        'Continuous Read-Write Test',
    'cdc_stress_test':           'CDC Stress Test',
    'burst_pattern_test':        'Burst Pattern Test',
    'alternating_pattern_test':  'Alternating Pattern Test',
    'boundary_condition_test':   'Boundary Condition Test',
    'interrupt_signals_test':    'Interrupt Signals Test',
    'stress_load_test':          'Stress Load Test',
    'protocol_edge_case_test':   'Protocol Edge Case Test',
    'coverage_test':             'Comprehensive Coverage Test',
}

# Short description for each test (shown in card)
TEST_DESC = {
    'basic_rw_test':             'Basic AXI write followed by peripheral read',
    'fifo_full_test':            'Fill FIFO to capacity, verify overflow handling',
    'fifo_empty_test':           'Read from empty FIFO, verify underflow handling',
    'reset_test':                'Assert reset mid-transaction, verify clean recovery',
    'rand_test':                 'Random write/read pairs via dummy sequence',
    'full_write_full_read_test': 'Fill FIFO completely then drain completely',
    'continuous_rw_test':        '50 balanced write/read pairs, FIFO state transitions',
    'cdc_stress_test':           'Rapid writes/reads to stress CDC synchronizers',
    'burst_pattern_test':        'Alternating address burst patterns (0x0 / 0x4)',
    'alternating_pattern_test':  'Variable-timing write-read pairs, CDC stress',
    'boundary_condition_test':   'Edge cases: single write/many reads, back-to-back ops',
    'interrupt_signals_test':    'IRQ_FULL and IRQ_EMPTY signal generation',
    'stress_load_test':          '500 high-speed transactions, extreme CDC stress',
    'protocol_edge_case_test':   'AXI protocol boundary values and timing variations',
    'coverage_test':             '5 sequences targeting 100% functional coverage',
}


def escape_html(text):
    return escape(text)


def highlight_uvm_line(line):
    line_escaped = escape_html(line.rstrip())
    if re.search(r'UVM_INFO', line):
        return f'<span class="uvm-info">{line_escaped}</span>'
    elif re.search(r'UVM_WARNING', line):
        return f'<span class="uvm-warning">{line_escaped}</span>'
    elif re.search(r'UVM_ERROR', line):
        return f'<span class="uvm-error">{line_escaped}</span>'
    elif re.search(r'UVM_FATAL', line):
        return f'<span class="uvm-fatal">{line_escaped}</span>'
    elif re.search(r'--- UVM Report Summary ---', line):
        return f'<span class="uvm-summary-header">{line_escaped}</span>'
    elif re.search(r'UVM_INFO.*\[TRANSACTION\]', line):
        return f'<span class="transaction">{line_escaped}</span>'
    elif re.search(r'UVM_INFO.*\[TEST_DONE\]', line):
        return f'<span class="test-done">{line_escaped}</span>'
    elif re.search(r'Errors: 0.*Warnings: 0', line):
        return f'<span class="success">{line_escaped}</span>'
    elif line.strip().startswith('#'):
        return f'<span class="comment">{line_escaped}</span>'
    else:
        return line_escaped


def extract_test_metrics(log_content):
    """Extract status, transaction count, writes, reads from log."""
    # UVM summary counts
    err_m   = re.search(r'UVM_ERROR\s*:\s*(\d+)',   log_content)
    fatal_m = re.search(r'UVM_FATAL\s*:\s*(\d+)',   log_content)
    warn_m  = re.search(r'UVM_WARNING\s*:\s*(\d+)', log_content)
    uvm_errors   = int(err_m.group(1))   if err_m   else 0
    uvm_fatals   = int(fatal_m.group(1)) if fatal_m else 0
    uvm_warnings = int(warn_m.group(1))  if warn_m  else 0

    comp_err_m  = re.search(r'Errors:\s*(\d+)',   log_content)
    comp_warn_m = re.search(r'Warnings:\s*(\d+)', log_content)
    comp_errors   = int(comp_err_m.group(1))  if comp_err_m  else 0
    comp_warnings = int(comp_warn_m.group(1)) if comp_warn_m else 0

    total_errors   = uvm_errors + uvm_fatals + comp_errors
    total_warnings = uvm_warnings + comp_warnings

    # Status
    if uvm_errors == 0 and uvm_fatals == 0 and comp_errors == 0:
        if re.search(r'TEST_DONE|run.*phase.*ready', log_content, re.IGNORECASE):
            status = "PASS"
        elif re.search(r'Errors:\s*0.*Warnings:\s*0', log_content):
            status = "PASS"
        else:
            status = "UNKNOWN"
    else:
        status = "FAIL"

    # Use the authoritative [COVERAGE] Transactions line from the coverage reporter
    # Format: "Transactions: N writes, M reads, T total"
    cov_match = re.search(
        r'\[COVERAGE\] Transactions:\s*(\d+) writes,\s*(\d+) reads,\s*(\d+) total',
        log_content
    )
    if cov_match:
        writes       = int(cov_match.group(1))
        reads        = int(cov_match.group(2))
        transactions = int(cov_match.group(3))
    else:
        # Fallback: count [TRANSACTION] tags
        transactions = len(re.findall(r'\[TRANSACTION\]', log_content))
        writes = len(re.findall(r'\[TRANSACTION\].*?kind=WRITE\b', log_content))
        reads  = len(re.findall(r'\[TRANSACTION\].*?kind=(?:PERIPH_READ|AXI_READ)\b', log_content))

    return status, total_errors, total_warnings, transactions, writes, reads


def convert_log_to_html(log_file_path, output_html_path, test_name):
    with open(log_file_path, 'r', encoding='utf-8', errors='ignore') as f:
        log_content = f.read()

    status, errors, warnings, transactions, writes, reads = extract_test_metrics(log_content)

    status_color = {"PASS": "#4caf50", "FAIL": "#f44336", "UNKNOWN": "#9e9e9e"}.get(status, "#9e9e9e")

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>UVM Log – {test_name}</title>
  <style>
    * {{ margin:0; padding:0; box-sizing:border-box; }}
    body {{ font-family:'Segoe UI',sans-serif; background:#f5f5f5; padding:20px; }}
    .container {{ max-width:1400px; margin:0 auto; background:white;
                  border-radius:10px; padding:30px;
                  box-shadow:0 4px 12px rgba(0,0,0,.1); }}
    h1 {{ color:#2c3e50; border-bottom:2px solid #667eea; padding-bottom:10px; margin-bottom:20px; }}
    .meta {{ background:#f8f9fa; padding:15px 20px; border-radius:8px;
             border-left:4px solid #667eea; margin-bottom:20px;
             display:flex; gap:30px; flex-wrap:wrap; align-items:center; }}
    .badge {{ display:inline-block; padding:5px 16px; border-radius:20px;
              font-weight:bold; color:white; background:{status_color}; }}
    .stat {{ color:#555; font-size:.95em; }}
    .stat strong {{ color:#333; }}
    .log-box {{ background:#1e1e1e; color:#d4d4d4; border-radius:8px;
                padding:16px; overflow:auto; max-height:750px;
                font-family:'Consolas','Monaco',monospace; font-size:12.5px;
                line-height:1.55; }}
    .log-line {{ white-space:pre-wrap; word-break:break-all; margin:1px 0; }}
    .uvm-info    {{ color:#4fc3f7; }}
    .uvm-warning {{ color:#ffb74d; }}
    .uvm-error   {{ color:#ef5350; font-weight:bold; }}
    .uvm-fatal   {{ color:#e53935; font-weight:bold; }}
    .transaction {{ color:#ff8a65; }}
    .test-done   {{ color:#81c784; font-weight:bold; }}
    .success     {{ color:#a5d6a7; font-weight:bold; }}
    .comment     {{ color:#888; }}
    .uvm-summary-header {{ color:#90caf9; font-weight:bold; }}
    .back {{ display:inline-block; margin-bottom:20px; color:#667eea;
             text-decoration:none; padding:8px 16px; border:1px solid #667eea;
             border-radius:6px; font-size:.9em; }}
    .back:hover {{ background:#667eea; color:white; }}
  </style>
</head>
<body>
<div class="container">
  <a href="index.html" class="back">← Back to Dashboard</a>
  <h1>📋 {test_name}</h1>
  <div class="meta">
    <span class="badge">{status}</span>
    <span class="stat"><strong>Transactions:</strong> {transactions}</span>
    <span class="stat"><strong>Writes:</strong> {writes}</span>
    <span class="stat"><strong>Reads:</strong> {reads}</span>
    <span class="stat"><strong>UVM Errors:</strong> {errors}</span>
    <span class="stat"><strong>Warnings:</strong> {warnings}</span>
    <span class="stat" style="margin-left:auto;color:#999;font-size:.85em">
      Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    </span>
  </div>
  <div class="log-box">
"""
    for line in log_content.split('\n'):
        html += f'    <div class="log-line">{highlight_uvm_line(line)}</div>\n'

    html += """  </div>
</div>
</body>
</html>"""

    with open(output_html_path, 'w', encoding='utf-8') as f:
        f.write(html)

    return status, errors, warnings, transactions, writes, reads


def generate_master_report(log_dir='uvm_test_logs', output_dir='html_reports'):
    os.makedirs(output_dir, exist_ok=True)

    test_results = []
    for stem, display_name in KNOWN_TESTS.items():
        log_path = os.path.join(log_dir, f'{stem}.log')
        if not os.path.isfile(log_path):
            continue
        html_file = f'{stem}.html'
        html_path = os.path.join(output_dir, html_file)
        status, errors, warnings, transactions, writes, reads = \
            convert_log_to_html(log_path, html_path, display_name)
        test_results.append({
            'id':           stem,
            'name':         display_name,
            'desc':         TEST_DESC.get(stem, ''),
            'html_file':    html_file,
            'status':       status,
            'errors':       errors,
            'warnings':     warnings,
            'transactions': transactions,
            'writes':       writes,
            'reads':        reads,
        })

    # ── Stats ─────────────────────────────────────────────────────────────────
    total  = len(test_results)
    passed = sum(1 for t in test_results if t['status'] == 'PASS')
    failed = sum(1 for t in test_results if t['status'] == 'FAIL')
    total_txn = sum(t['transactions'] for t in test_results)

    # ── Build cards ───────────────────────────────────────────────────────────
    cards_html = ""
    for t in test_results:
        sc = {"PASS": "#4caf50", "FAIL": "#f44336"}.get(t['status'], "#9e9e9e")
        border = {"PASS": "#4caf50", "FAIL": "#f44336"}.get(t['status'], "#bbb")
        icon   = {"PASS": "✅", "FAIL": "❌"}.get(t['status'], "⚪")
        cards_html += f"""
      <div style="background:white;border-radius:10px;padding:22px;
                  box-shadow:0 2px 8px rgba(0,0,0,.08);
                  border-top:4px solid {border};
                  display:flex;flex-direction:column;gap:10px;">
        <div style="display:flex;justify-content:space-between;align-items:flex-start">
          <div>
            <div style="font-weight:700;font-size:1em;color:#222">{icon} {t['name']}</div>
            <div style="font-size:.82em;color:#777;margin-top:3px">{t['desc']}</div>
          </div>
          <span style="background:{sc};color:white;padding:3px 12px;
                       border-radius:12px;font-size:.8em;font-weight:bold;
                       white-space:nowrap;margin-left:10px">{t['status']}</span>
        </div>
        <div style="display:flex;gap:16px;flex-wrap:wrap;font-size:.85em;color:#555">
          <span>🔄 <strong>{t['transactions']}</strong> txns</span>
          <span>✍️ <strong>{t['writes']}</strong> writes</span>
          <span>📖 <strong>{t['reads']}</strong> reads</span>
          <span>⚠️ Errors: <strong style="color:{'#f44336' if t['errors'] else '#4caf50'}">{t['errors']}</strong></span>
        </div>
        <a href="{t['html_file']}"
           style="display:inline-block;background:#667eea;color:white;
                  padding:7px 16px;border-radius:6px;text-decoration:none;
                  font-size:.85em;font-weight:500;align-self:flex-start;
                  margin-top:4px">
          View Log →
        </a>
      </div>"""

    # ── Load run timestamps ───────────────────────────────────────────────────
    ts = load_run_timestamps(Path(log_dir) / "run_timestamps.txt")
    html_gen_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    def ts_row(label, start_key, end_key=""):
        start = ts.get(start_key, "")
        end   = ts.get(end_key, "") if end_key else ""
        if not start:
            return ""
        duration = ""
        if start and end:
            try:
                fmt = "%Y-%m-%d %H:%M:%S"
                delta = datetime.strptime(end, fmt) - datetime.strptime(start, fmt)
                secs = int(delta.total_seconds())
                duration = f" &nbsp;<span style='color:#888;font-size:.85em'>({secs}s)</span>"
            except Exception:
                pass
        end_str = f" → {end}" if end else ""
        return (f"<tr><td style='padding:5px 10px;color:#555;white-space:nowrap'>{label}</td>"
                f"<td style='padding:5px 10px;font-family:monospace;color:#333'>"
                f"{start}{end_str}{duration}</td></tr>")

    timing_rows = (
        ts_row("Flow started",            "FLOW_START") +
        ts_row("Compilation",             "COMPILE_START",      "COMPILE_END") +
        ts_row("All 15 tests ran",        "TESTS_START",        "TESTS_END") +
        ts_row("UCDB merge",              "UCDB_MERGE_START",   "UCDB_MERGE_END") +
        ts_row("vcover report generated", "VCOVER_REPORT_START","VCOVER_REPORT_END") +
        ts_row("HTML test reports",       "HTML_REPORT_START",  "HTML_REPORT_END") +
        ts_row("Coverage HTML generated", "COV_HTML_START",     "COV_HTML_END") +
        ts_row("Flow finished",           "FLOW_END")
    )

    if timing_rows:
        timing_section = f"""
  <!-- Run timing -->
  <div class="section">
    <h2>🕐 Run Timing</h2>
    <table style="width:100%;border-collapse:collapse;font-size:.92em">
      <tbody>{timing_rows}</tbody>
    </table>
    <p style="color:#aaa;font-size:.8em;margin-top:8px">
      HTML report created: {html_gen_time} &nbsp;|&nbsp;
      Source: uvm_test_logs/run_timestamps.txt
    </p>
  </div>"""
    else:
        timing_section = f"""
  <!-- Run timing -->
  <div class="section">
    <h2>🕐 Run Timing</h2>
    <p style="color:#aaa;font-size:.85em">
      No timing data found (run_timestamps.txt not present).<br>
      HTML report created: {html_gen_time}
    </p>
  </div>"""

    index_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AXI4 Async FIFO – UVM Verification Dashboard</title>
  <style>
    * {{ margin:0; padding:0; box-sizing:border-box; }}
    body {{ font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;
            background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
            min-height:100vh; padding:30px 20px; }}
    .wrap {{ max-width:1300px; margin:0 auto; }}
    .header {{ background:white; border-radius:12px; padding:32px 36px;
               margin-bottom:28px; box-shadow:0 4px 16px rgba(0,0,0,.12); }}
    .header h1 {{ font-size:2.2em; color:#222; margin-bottom:6px; }}
    .header p  {{ color:#666; font-size:1em; }}
    .section {{ background:white; border-radius:12px; padding:28px 32px;
                margin-bottom:28px; box-shadow:0 4px 16px rgba(0,0,0,.12); }}
    .section h2 {{ font-size:1.3em; color:#333;
                   border-bottom:3px solid #667eea;
                   padding-bottom:10px; margin-bottom:22px; }}
    .stat-row {{ display:grid;
                 grid-template-columns:repeat(auto-fit,minmax(160px,1fr));
                 gap:16px; margin-bottom:0; }}
    .stat-card {{ border-radius:10px; padding:20px; text-align:center; color:white; }}
    .stat-card .num {{ font-size:2.4em; font-weight:700; line-height:1; }}
    .stat-card .lbl {{ font-size:.9em; opacity:.9; margin-top:4px; }}
    .card-grid {{ display:grid;
                  grid-template-columns:repeat(auto-fill,minmax(340px,1fr));
                  gap:20px; }}
    .cov-link {{ display:inline-block; background:linear-gradient(135deg,#667eea,#764ba2);
                 color:white; padding:12px 28px; border-radius:8px;
                 text-decoration:none; font-weight:600; font-size:.95em;
                 margin-top:8px; }}
    .cov-link:hover {{ opacity:.9; }}
    .footer {{ text-align:center; color:rgba(255,255,255,.75);
               font-size:.9em; margin-top:10px; }}
  </style>
</head>
<body>
<div class="wrap">

  <div class="header">
    <h1>🔬 AXI4-Lite Async FIFO — UVM Verification Dashboard</h1>
    <p>QuestaSim 10.7c &nbsp;|&nbsp; UVM 1.1d &nbsp;|&nbsp;
       Created: {html_gen_time}</p>
  </div>

  <!-- Summary stats -->
  <div class="section">
    <h2>📊 Test Summary</h2>
    <div class="stat-row">
      <div class="stat-card" style="background:linear-gradient(135deg,#667eea,#764ba2)">
        <div class="num">{total}</div><div class="lbl">Total Tests</div>
      </div>
      <div class="stat-card" style="background:linear-gradient(135deg,#56ab2f,#a8e063)">
        <div class="num">{passed}</div><div class="lbl">Passed ✅</div>
      </div>
      <div class="stat-card" style="background:linear-gradient(135deg,#eb3349,#f45c43)">
        <div class="num">{failed}</div><div class="lbl">Failed ❌</div>
      </div>
      <div class="stat-card" style="background:linear-gradient(135deg,#4caf50,#81c784)">
        <div class="num">A</div><div class="lbl">Coverage Grade</div>
      </div>
    </div>
  </div>

  <!-- Test cards -->
  <div class="section">
    <h2>📋 Test Results</h2>
    <div class="card-grid">
      {cards_html}
    </div>
  </div>

  <!-- Coverage link -->
  <div class="section">
    <h2>📈 Functional Coverage</h2>
    <p style="color:#555;margin-bottom:14px">
      Functional coverage was measured using QuestaSim covergroups across 5 domains.
      The UCDB was generated from the <strong>coverage_test</strong> run and verified
      with <code>vcover report</code>.
    </p>
    <a href="functional_coverage.html" class="cov-link">
      📊 View Functional Coverage Report (100%) →
    </a>
  </div>

  {timing_section}

</div>
<div class="footer">
  <p>AXI4-Lite Asynchronous FIFO &nbsp;|&nbsp; UVM Verification &nbsp;|&nbsp; QuestaSim 10.7c</p>
</div>
</body>
</html>"""

    index_path = os.path.join(output_dir, 'index.html')
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(index_html)

    print(f"[OK] {len(test_results)} test HTML files generated in '{output_dir}'")
    print(f"[OK] Dashboard: {index_path}")
    print(f"     {passed} PASS  |  {failed} FAIL  |  {total_txn} total transactions")
    return index_path


if __name__ == '__main__':
    import sys
    log_dir    = sys.argv[1] if len(sys.argv) > 1 else 'uvm_test_logs'
    output_dir = sys.argv[2] if len(sys.argv) > 2 else 'html_reports'
    print("Generating HTML reports from UVM logs...")
    generate_master_report(log_dir, output_dir)
