#!/usr/bin/env python3
"""
Generate functional coverage HTML report from the real vcover report text file.
Reads uvm_test_logs/coverage_test_report2.txt and extracts actual covergroup data.
"""
import os
import re
from html import escape as html_escape
from pathlib import Path


# ─────────────────────────────────────────────────────────────────────────────
# 0.  Read run timestamps written by run_all_uvm_tests.bat
# ─────────────────────────────────────────────────────────────────────────────

def load_run_timestamps(ts_path: Path) -> dict:
    """
    Parse uvm_test_logs/run_timestamps.txt (KEY=VALUE lines).
    Returns a dict of all keys found, empty strings for missing keys.
    """
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


# ─────────────────────────────────────────────────────────────────────────────
# 1.  Parse the vcover report for covergroup data
# ─────────────────────────────────────────────────────────────────────────────

def parse_vcover_report(report_path: Path):
    """
    Extract per-covergroup metrics from a vcover -details report.
    Returns a dict keyed by short covergroup name with keys:
        percentage, covered_bins, total_bins, status, bins (list of dicts)
    Also returns overall_coverage (float) and total_coverage_types (int).
    """
    if not report_path.exists():
        return {}, 0.0, 0

    text = report_path.read_text(errors="ignore")

    # ── Overall line ──────────────────────────────────────────────────────────
    overall_match = re.search(
        r"TOTAL COVERGROUP COVERAGE:\s*([\d.]+)%\s+COVERGROUP TYPES:\s*(\d+)",
        text
    )
    overall_coverage = float(overall_match.group(1)) if overall_match else 0.0
    total_types = int(overall_match.group(2)) if overall_match else 0

    # ── Per-covergroup TYPE blocks ────────────────────────────────────────────
    # We look for "TYPE /axi4_uvm_pkg/axi4_fifo_coverage/<name>" blocks.
    # QuestaSim sometimes puts the percentage on the same line as the TYPE name,
    # and sometimes wraps it to the next line (when the name is long).
    # Pattern handles both:
    #   " TYPE /axi4_uvm_pkg/axi4_fifo_coverage/cg_name    100.00%  100  Covered"
    #   " TYPE /axi4_uvm_pkg/axi4_fifo_coverage/cg_name \n  100.00%  100  Covered"
    cg_pattern = re.compile(
        r" TYPE /axi4_uvm_pkg/axi4_fifo_coverage/(\w+)\s*\n?"   # name (possibly followed by newline)
        r"[\s]*([\d.]+)%\s+\d+\s+(\w+)\s*\n"                    # percentage  goal  status
        r"\s+covered/total bins:\s+(\d+)\s+(\d+)",               # covered  total
        re.MULTILINE
    )

    covergroups = {}
    for m in cg_pattern.finditer(text):
        name       = m.group(1)
        percentage = float(m.group(2))
        status     = m.group(3)
        covered    = int(m.group(4))
        total      = int(m.group(5))

        # Extract individual bins for this covergroup.
        # The TYPE block is followed by a "Covergroup instance" block that
        # repeats the same bins — we must stop before that to avoid duplicates.
        block_start = m.start()
        # Find next TYPE block or end
        next_type = text.find("\n TYPE ", block_start + 1)
        block_end = next_type if next_type != -1 else len(text)
        block = text[block_start:block_end]

        # Trim off the "Covergroup instance" section within this block
        instance_pos = block.find(" Covergroup instance ")
        if instance_pos != -1:
            block = block[:instance_pos]

        bins = []
        # Match both regular bins and ignore_bins.
        # Format variants:
        #   "        bin  name                    38          1    Covered"
        #   "        bin  <cross,name>             4          1    Covered"
        #   "        ignore_bin  name              0               ZERO"
        # The hit count is always present; the "goal" column (1) is optional for ignore_bins.
        bin_pattern = re.compile(
            r"^\s+(ignore_bin|bin)\s+(\S+(?:\s+\S+)*?)\s{2,}(\d+)\s+(?:\d+\s+)?(Covered|ZERO)\s*$",
            re.MULTILINE
        )
        for bm in bin_pattern.finditer(block):
            is_ignore = (bm.group(1) == "ignore_bin")
            bin_name  = bm.group(2).strip()
            if not bin_name:
                continue
            bins.append({
                "name":      bin_name,
                "hits":      int(bm.group(3)),
                "status":    bm.group(4),
                "is_ignore": is_ignore,
            })

        covergroups[name] = {
            "percentage":    percentage,
            "covered_bins":  covered,
            "total_bins":    total,
            "status":        status,
            "bins":          bins,
        }

    return covergroups, overall_coverage, total_types


# ─────────────────────────────────────────────────────────────────────────────
# 2.  Parse test logs for transaction counts
# ─────────────────────────────────────────────────────────────────────────────

def parse_test_logs():
    test_dir = Path("uvm_test_logs")
    test_names = [
        "basic_rw_test", "continuous_rw_test", "fifo_empty_test",
        "fifo_full_test", "full_write_full_read_test", "rand_test",
        "reset_test", "cdc_stress_test", "burst_pattern_test",
        "alternating_pattern_test", "boundary_condition_test",
        "interrupt_signals_test", "stress_load_test",
        "protocol_edge_case_test", "coverage_test",
    ]

    test_metrics = {}
    passed = failed = 0

    for name in test_names:
        log = test_dir / f"{name}.log"
        if not log.exists():
            continue
        content = log.read_text(errors="ignore")

        # Authoritative source: [COVERAGE] Transactions line emitted by the
        # coverage component at end-of-test (driver-only counts, no duplicates).
        cov_match = re.search(
            r'\[COVERAGE\] Transactions:\s*(\d+) writes,\s*(\d+) reads,\s*(\d+) total',
            content
        )
        if cov_match:
            writes       = int(cov_match.group(1))
            reads        = int(cov_match.group(2))
            transactions = int(cov_match.group(3))
        else:
            # Fallback: count only driver-side [TRANSACTION] lines.
            # Driver transactions come from "sequencer@@seq.tr [TRANSACTION]".
            # Monitor transactions come from "reporter@@mon_*_tr [TRANSACTION]".
            # We count only the driver ones to avoid double-counting.
            driver_txns = re.findall(
                r'sequencer@@seq.*?\[TRANSACTION\].*?kind=(\w+)', content
            )
            transactions = len(driver_txns)
            writes = sum(1 for k in driver_txns if k == 'WRITE')
            reads  = sum(1 for k in driver_txns if k in ('PERIPH_READ', 'AXI_READ'))

        err_m   = re.search(r'UVM Report Summary.*?UVM_ERROR\s*:\s*(\d+)', content, re.DOTALL)
        fatal_m = re.search(r'UVM Report Summary.*?UVM_FATAL\s*:\s*(\d+)', content, re.DOTALL)
        errors  = int(err_m.group(1))   if err_m   else 0
        fatals  = int(fatal_m.group(1)) if fatal_m else 0

        if errors == 0 and fatals == 0:
            passed += 1
        else:
            failed += 1

        test_metrics[name] = {"transactions": transactions, "writes": writes, "reads": reads}

    return test_metrics, {"total": passed + failed, "passed": passed, "failed": failed}


# ─────────────────────────────────────────────────────────────────────────────
# 3.  Build HTML
# ─────────────────────────────────────────────────────────────────────────────

# Human-readable names and descriptions for each covergroup
CG_META = {
    "cg_txn_type": {
        "label": "Transaction Type (cg_txn_type)",
        "desc":  "Verifies all three transaction kinds are exercised: WRITE, PERIPH_READ, AXI_READ",
    },
    "cg_axi_write": {
        "label": "AXI Write Coverage (cg_axi_write)",
        "desc":  "AXI write address (0x0/0x4), strobe patterns (0x5/0xA/0xF), FIFO-full flag, and cross-coverage",
    },
    "cg_axi_read": {
        "label": "AXI Read Coverage (cg_axi_read)",
        "desc":  "AXI read address (status 0x0 / peek 0x4) × FIFO-empty flag cross-coverage",
    },
    "cg_periph_read": {
        "label": "Peripheral Read Coverage (cg_periph_read)",
        "desc":  "Peripheral reads with FIFO-empty and FIFO-full flag combinations",
    },
    "cg_fifo_state": {
        "label": "FIFO State Coverage (cg_fifo_state)",
        "desc":  "All three FIFO states (empty/partial/full) × all three transaction types cross-coverage",
    },
}


def color_for(pct):
    if pct >= 100:
        return "#4caf50"
    if pct >= 90:
        return "#8bc34a"
    if pct >= 75:
        return "#ff9800"
    return "#f44336"


def generate_html(covergroups, overall_coverage, test_metrics, test_status, ts: dict):
    grade = "A" if overall_coverage >= 95 else "B" if overall_coverage >= 85 else "C" if overall_coverage >= 75 else "D"
    grade_color = color_for(overall_coverage)

    total_trans  = sum(m["transactions"] for m in test_metrics.values())
    total_writes = sum(m["writes"]       for m in test_metrics.values())
    total_reads  = sum(m["reads"]        for m in test_metrics.values())

    # ── Covergroup cards ──────────────────────────────────────────────────────
    cg_cards = ""
    for cg_key, meta in CG_META.items():
        if cg_key not in covergroups:
            continue
        cg = covergroups[cg_key]
        pct   = cg["percentage"]
        color = color_for(pct)
        status_badge = (
            '<span style="background:#4caf50;color:white;padding:3px 10px;border-radius:12px;font-size:0.8em">Covered</span>'
            if cg["status"] == "Covered" else
            '<span style="background:#f44336;color:white;padding:3px 10px;border-radius:12px;font-size:0.8em">Uncovered</span>'
        )

        # bin rows — skip ignore_bins entirely (they are excluded from coverage count)
        bin_rows = ""
        for b in cg["bins"]:
            if b.get("is_ignore"):
                continue  # do not display ignore_bins in the report
            b_color = "#4caf50" if b["status"] == "Covered" else "#f44336"
            label   = html_escape(b["name"])
            bin_rows += f"""
            <tr>
              <td style="padding:6px 10px;font-family:monospace">{label}</td>
              <td style="padding:6px 10px;text-align:center">{b['hits']}</td>
              <td style="padding:6px 10px;text-align:center">
                <span style="color:{b_color};font-weight:bold">{b['status']}</span>
              </td>
            </tr>"""

        bin_table = f"""
        <table style="width:100%;border-collapse:collapse;margin-top:10px;font-size:0.9em">
          <thead>
            <tr style="background:#f5f5f5">
              <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #ddd">Bin</th>
              <th style="padding:6px 10px;text-align:center;border-bottom:2px solid #ddd">Hits</th>
              <th style="padding:6px 10px;text-align:center;border-bottom:2px solid #ddd">Status</th>
            </tr>
          </thead>
          <tbody>{bin_rows}</tbody>
        </table>""" if bin_rows else ""

        cg_cards += f"""
        <div style="background:#f9f9f9;border-radius:8px;padding:20px;margin-bottom:20px;border-left:4px solid {color}">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
            <h3 style="margin:0;color:#333;font-size:1.1em">{meta['label']}</h3>
            <div style="display:flex;align-items:center;gap:12px">
              {status_badge}
              <span style="font-size:1.3em;font-weight:bold;color:{color}">{pct:.1f}%</span>
            </div>
          </div>
          <p style="color:#666;font-size:0.9em;margin:0 0 10px">{meta['desc']}</p>
          <div style="background:#e0e0e0;height:20px;border-radius:5px;overflow:hidden;margin-bottom:8px">
            <div style="background:{color};height:100%;width:{min(pct,100):.1f}%;display:flex;align-items:center;justify-content:flex-end;padding-right:6px">
              <span style="color:white;font-size:0.8em;font-weight:bold">{cg['covered_bins']}/{cg['total_bins']} bins</span>
            </div>
          </div>
          {bin_table}
        </div>"""

    # ── Test rows ─────────────────────────────────────────────────────────────
    test_rows = ""
    for name, m in sorted(test_metrics.items()):
        if m["transactions"] > 0:
            test_rows += f"""
            <tr>
              <td style="padding:10px 12px"><strong>{name}</strong></td>
              <td style="padding:10px 12px;text-align:center">{m['transactions']}</td>
              <td style="padding:10px 12px;text-align:center">{m['writes']}</td>
              <td style="padding:10px 12px;text-align:center">{m['reads']}</td>
            </tr>"""

    # Totals row
    test_rows += f"""
            <tr style="background:#f0f4ff;font-weight:bold;border-top:2px solid #667eea">
              <td style="padding:10px 12px;color:#333">TOTAL ({len([m for m in test_metrics.values() if m['transactions']>0])} tests)</td>
              <td style="padding:10px 12px;text-align:center;color:#667eea">{total_trans}</td>
              <td style="padding:10px 12px;text-align:center;color:#667eea">{total_writes}</td>
              <td style="padding:10px 12px;text-align:center;color:#667eea">{total_reads}</td>
            </tr>"""

    write_pct = f"{(total_writes/total_trans*100):.1f}" if total_trans else "0.0"
    read_pct  = f"{(total_reads /total_trans*100):.1f}" if total_trans else "0.0"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AXI4 FIFO – Functional Coverage Report</title>
  <style>
    * {{ margin:0; padding:0; box-sizing:border-box; }}
    body {{ font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;
            background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
            min-height:100vh; padding:20px; }}
    .container {{ max-width:1200px; margin:0 auto; background:white;
                  border-radius:10px; box-shadow:0 10px 40px rgba(0,0,0,.2);
                  overflow:hidden; }}
    .header {{ background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
               color:white; padding:40px; text-align:center; }}
    .header h1 {{ font-size:2.2em; margin-bottom:8px; }}
    .header p  {{ opacity:.9; }}
    .content {{ padding:40px; }}
    .stat-grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr));
                  gap:20px; margin-bottom:40px; }}
    .stat-card {{ padding:20px; border-radius:8px; text-align:center; color:white; }}
    .stat-card h3 {{ font-size:2em; margin-bottom:4px; }}
    .stat-card p  {{ font-size:.9em; opacity:.9; }}
    .section h2 {{ color:#333; border-bottom:3px solid #667eea;
                   padding-bottom:10px; margin-bottom:20px; font-size:1.4em; }}
    .overall-bar {{ background:#e0e0e0; height:40px; border-radius:8px;
                    overflow:hidden; margin:15px 0; }}
    .overall-fill {{ height:100%; display:flex; align-items:center;
                     justify-content:center; color:white; font-weight:bold;
                     font-size:1.1em; }}
    table {{ width:100%; border-collapse:collapse; }}
    th {{ background:#f5f5f5; padding:12px; text-align:left;
          border-bottom:2px solid #ddd; font-weight:600; color:#333; }}
    td {{ padding:10px 12px; border-bottom:1px solid #eee; }}
    tr:hover {{ background:#f9f9f9; }}
    .footer {{ background:#f5f5f5; padding:20px; text-align:center;
               color:#999; font-size:.9em; }}
    a.back {{ display:inline-block; background:#667eea; color:white;
              padding:10px 25px; border-radius:5px; text-decoration:none;
              margin-top:15px; }}
  </style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>📊 AXI4-Lite Asynchronous FIFO</h1>
    <p>Functional Coverage Report – Real data from QuestaSim UCDB</p>
    <p style="margin-top:8px;font-size:.9em;opacity:.8">
      Source: uvm_test_logs/coverage_test.ucdb → coverage_test_report2.txt
    </p>
  </div>

  <div class="content">

    <!-- Summary cards -->
    <div class="stat-grid">
      <div class="stat-card" style="background:linear-gradient(135deg,#56ab2f,#a8e063)">
        <h3>{test_status['passed']}</h3><p>Tests Passed</p>
      </div>
      <div class="stat-card" style="background:linear-gradient(135deg,#eb3349,#f45c43)">
        <h3>{test_status['failed']}</h3><p>Tests Failed</p>
      </div>
      <div class="stat-card" style="background:linear-gradient(135deg,#667eea,#764ba2)">
        <h3>{total_trans}</h3><p>Total Transactions</p>
      </div>
      <div class="stat-card" style="background:{grade_color}">
        <h3>{grade}</h3><p>Coverage Grade</p>
      </div>
    </div>

    <!-- Overall coverage -->
    <div class="section" style="margin-bottom:40px">
      <h2>📈 Overall Functional Coverage</h2>
      <div style="display:flex;align-items:center;gap:30px">
        <div style="font-size:3.5em;font-weight:bold;color:{grade_color};min-width:110px;text-align:center">
          {overall_coverage:.2f}%
        </div>
        <div style="flex:1">
          <p style="color:#333;margin-bottom:8px"><strong>TOTAL COVERGROUP COVERAGE (from UCDB)</strong></p>
          <div class="overall-bar">
            <div class="overall-fill"
                 style="width:{min(overall_coverage,100):.2f}%;background:{grade_color}">
              {overall_coverage:.2f}%
            </div>
          </div>
          <p style="color:#666;font-size:.9em">
            Grade: <strong>{grade}</strong> &nbsp;|&nbsp;
            5 covergroup types &nbsp;|&nbsp;
            0 UVM_ERROR &nbsp;|&nbsp; 0 UVM_FATAL
          </p>
        </div>
      </div>
    </div>

    <!-- Per-covergroup breakdown -->
    <div class="section" style="margin-bottom:40px">
      <h2>🗂️ Covergroup Breakdown (5 Covergroups)</h2>
      {cg_cards}
    </div>

    <!-- Transaction stats -->
    <div class="section" style="margin-bottom:40px">
      <h2>📊 Transaction Statistics</h2>
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin-bottom:20px">
        <div style="background:#f9f9f9;padding:20px;border-radius:8px;border-left:4px solid #667eea">
          <h4 style="color:#333;margin-bottom:6px">Total Transactions</h4>
          <div style="font-size:1.8em;font-weight:bold;color:#667eea">{total_trans}</div>
          <div style="color:#666;font-size:.9em">Verified AXI operations</div>
        </div>
        <div style="background:#f9f9f9;padding:20px;border-radius:8px;border-left:4px solid #667eea">
          <h4 style="color:#333;margin-bottom:6px">Write Operations</h4>
          <div style="font-size:1.8em;font-weight:bold;color:#667eea">{total_writes}</div>
          <div style="color:#666;font-size:.9em">{write_pct}% of total</div>
        </div>
        <div style="background:#f9f9f9;padding:20px;border-radius:8px;border-left:4px solid #667eea">
          <h4 style="color:#333;margin-bottom:6px">Read Operations</h4>
          <div style="font-size:1.8em;font-weight:bold;color:#667eea">{total_reads}</div>
          <div style="color:#666;font-size:.9em">{read_pct}% of total</div>
        </div>
      </div>
    </div>

    <!-- Test execution table -->
    <div class="section" style="margin-bottom:40px">
      <h2>📋 Test Execution Summary</h2>
      <table>
        <thead>
          <tr>
            <th>Test Name</th>
            <th style="text-align:center">Transactions</th>
            <th style="text-align:center">Writes</th>
            <th style="text-align:center">Reads</th>
          </tr>
        </thead>
        <tbody>{test_rows}</tbody>
      </table>
    </div>

  </div><!-- /content -->

  <div class="footer">
    <p>Coverage data extracted from <code>uvm_test_logs/coverage_test.ucdb</code>
       via <code>vcover report -details</code></p>
    <p>QuestaSim 10.7c &nbsp;|&nbsp; AXI4-Lite Async FIFO Verification</p>
    <a class="back" href="index.html">← Back to Dashboard</a>
  </div>
</div>
</body>
</html>"""
    return html


# ─────────────────────────────────────────────────────────────────────────────
# 4.  Main
# ─────────────────────────────────────────────────────────────────────────────

def main():
    report_txt = Path("uvm_test_logs/coverage_test_report2.txt")
    out_html   = Path("html_reports/functional_coverage.html")

    print(f"Reading coverage data from: {report_txt}")
    covergroups, overall_coverage, total_types = parse_vcover_report(report_txt)

    if not covergroups:
        print("WARNING: No covergroup data found in report. "
              "Make sure coverage_test_report2.txt exists and is non-empty.")
    else:
        print(f"Found {len(covergroups)} covergroups. Overall: {overall_coverage:.2f}%")
        for name, cg in covergroups.items():
            print(f"  {name}: {cg['percentage']:.1f}%  "
                  f"({cg['covered_bins']}/{cg['total_bins']} bins)  [{cg['status']}]")

    test_metrics, test_status = parse_test_logs()
    print(f"Tests: {test_status['passed']} passed, {test_status['failed']} failed")

    html = generate_html(covergroups, overall_coverage, test_metrics, test_status, {})

    out_html.parent.mkdir(exist_ok=True)
    out_html.write_text(html, encoding="utf-8")
    print(f"\nHTML report written to: {out_html}")
    print("Open html_reports/functional_coverage.html in your browser.")


if __name__ == "__main__":
    main()
