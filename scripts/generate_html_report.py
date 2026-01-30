#!/usr/bin/env python3
"""
UVM Test Log to HTML Converter
Converts QuestaSim UVM text logs to formatted HTML with syntax highlighting
"""

import os
import re
from datetime import datetime
from html import escape

def escape_html(text):
    """Escape HTML special characters"""
    return escape(text)

def highlight_uvm_line(line):
    """Apply syntax highlighting to UVM log lines"""
    line_escaped = escape_html(line.rstrip())
    
    # Color coding for different message types
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
    elif re.search(r'UVM_INFO.*\[Driver\]', line):
        return f'<span class="driver">{line_escaped}</span>'
    elif re.search(r'UVM_INFO.*\[TRANSACTION\]', line):
        return f'<span class="transaction">{line_escaped}</span>'
    elif re.search(r'UVM_INFO.*\[TEST_DONE\]', line):
        return f'<span class="test-done">{line_escaped}</span>'
    elif re.search(r'Errors: 0.*Warnings: 0', line):
        return f'<span class="success">{line_escaped}</span>'
    elif re.search(r'Error', line, re.IGNORECASE):
        return f'<span class="error-line">{line_escaped}</span>'
    elif re.search(r'Warning', line, re.IGNORECASE):
        return f'<span class="warning-line">{line_escaped}</span>'
    elif line.strip().startswith('#'):
        return f'<span class="comment">{line_escaped}</span>'
    else:
        return line_escaped

def extract_test_status(log_content):
    """Extract test status from log content"""
    status = "UNKNOWN"
    errors = 0
    warnings = 0
    
    # Extract UVM error/warning/fatal counts from the report summary
    # Look for patterns like "UVM_ERROR :    0" or "UVM_ERROR :    1"
    uvm_error_match = re.search(r'UVM_ERROR\s*:\s*(\d+)', log_content)
    uvm_fatal_match = re.search(r'UVM_FATAL\s*:\s*(\d+)', log_content)
    uvm_warning_match = re.search(r'UVM_WARNING\s*:\s*(\d+)', log_content)
    
    uvm_errors = int(uvm_error_match.group(1)) if uvm_error_match else 0
    uvm_fatals = int(uvm_fatal_match.group(1)) if uvm_fatal_match else 0
    uvm_warnings = int(uvm_warning_match.group(1)) if uvm_warning_match else 0
    
    # Extract compilation errors/warnings
    comp_error_match = re.search(r'Errors:\s*(\d+)', log_content)
    comp_warning_match = re.search(r'Warnings:\s*(\d+)', log_content)
    
    comp_errors = int(comp_error_match.group(1)) if comp_error_match else 0
    comp_warnings = int(comp_warning_match.group(1)) if comp_warning_match else 0
    
    # Total errors and warnings
    errors = uvm_errors + uvm_fatals + comp_errors
    warnings = uvm_warnings + comp_warnings
    
    # Determine status: PASS if no errors/fatals, check for hang, else UNKNOWN
    if re.search(r'Stuck|stuck|hang|HANG', log_content, re.IGNORECASE):
        status = "HANG"
    elif uvm_errors == 0 and uvm_fatals == 0 and comp_errors == 0:
        # Check if test completed successfully
        if re.search(r'TEST_DONE|run.*phase.*ready', log_content, re.IGNORECASE):
            status = "PASS"
        elif re.search(r'Errors:\s*0.*Warnings:\s*0', log_content):
            status = "PASS"
        else:
            status = "UNKNOWN"
    else:
        status = "FAIL"
    
    return status, errors, warnings

def convert_log_to_html(log_file_path, output_html_path, test_name):
    """Convert a single log file to HTML"""
    
    with open(log_file_path, 'r', encoding='utf-8', errors='ignore') as f:
        log_content = f.read()
    
    # Extract test status
    status, errors, warnings = extract_test_status(log_content)
    
    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UVM Test Log - {test_name}</title>
    <style>
        body {{
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            margin: 0;
            padding: 20px;
            background-color: #1e1e1e;
            color: #d4d4d4;
            line-height: 1.6;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background-color: #252526;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }}
        h1 {{
            color: #4ec9b0;
            border-bottom: 2px solid #4ec9b0;
            padding-bottom: 10px;
        }}
        .test-header {{
            background-color: #2d2d30;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }}
        .status-badge {{
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            margin-left: 10px;
        }}
        .status-pass {{
            background-color: #4caf50;
            color: white;
        }}
        .status-fail {{
            background-color: #f44336;
            color: white;
        }}
        .status-hang {{
            background-color: #ff9800;
            color: white;
        }}
        .status-unknown {{
            background-color: #9e9e9e;
            color: white;
        }}
        .log-content {{
            background-color: #1e1e1e;
            border: 1px solid #3e3e42;
            border-radius: 5px;
            padding: 15px;
            overflow-x: auto;
            max-height: 800px;
            overflow-y: auto;
            font-size: 13px;
        }}
        .log-line {{
            white-space: pre-wrap;
            word-wrap: break-word;
            margin: 2px 0;
        }}
        .uvm-info {{
            color: #4ec9b0;
        }}
        .uvm-warning {{
            color: #dcdcaa;
        }}
        .uvm-error {{
            color: #f48771;
            font-weight: bold;
        }}
        .uvm-fatal {{
            color: #f44336;
            font-weight: bold;
        }}
        .driver {{
            color: #569cd6;
        }}
        .transaction {{
            color: #ce9178;
        }}
        .test-done {{
            color: #4ec9b0;
            font-weight: bold;
        }}
        .uvm-summary-header {{
            color: #4ec9b0;
            font-weight: bold;
            font-size: 14px;
        }}
        .success {{
            color: #4caf50;
            font-weight: bold;
        }}
        .error-line {{
            color: #f48771;
        }}
        .warning-line {{
            color: #dcdcaa;
        }}
        .comment {{
            color: #6a9955;
        }}
        .back-link {{
            display: inline-block;
            margin-bottom: 20px;
            color: #4ec9b0;
            text-decoration: none;
            padding: 8px 15px;
            border: 1px solid #4ec9b0;
            border-radius: 5px;
        }}
        .back-link:hover {{
            background-color: #4ec9b0;
            color: #1e1e1e;
        }}
        .metadata {{
            color: #858585;
            font-size: 12px;
            margin-top: 10px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <a href="index.html" class="back-link">← Back to Test Summary</a>
        <h1>UVM Test Log: {test_name}</h1>
        <div class="test-header">
            <strong>Status:</strong> <span class="status-badge status-{status.lower()}">{status}</span>
            <span style="margin-left: 20px;"><strong>Errors:</strong> {errors}</span>
            <span style="margin-left: 20px;"><strong>Warnings:</strong> {warnings}</span>
            <div class="metadata">
                Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
            </div>
        </div>
        <div class="log-content">
"""
    
    # Process each line
    lines = log_content.split('\n')
    for line in lines:
        highlighted = highlight_uvm_line(line)
        html += f'            <div class="log-line">{highlighted}</div>\n'
    
    html += """        </div>
    </div>
</body>
</html>"""
    
    # Write HTML file
    with open(output_html_path, 'w', encoding='utf-8') as f:
        f.write(html)
    
    return status, errors, warnings

def _discover_log_files(log_dir):
    """
    Discover all .log and .txt files in log_dir and map them to test_id + display name.
    Accepts both extensions; for a given test, .log is preferred over .txt (simulator output).
    Returns list of (log_path, test_id, test_name).
    """
    # Stem (filename without extension) -> (test_id, display_name)
    # Supports both simulator names (basic_rw_test.log, rand_test.log) and legacy .txt names
    STEM_TO_TEST = {
        'basic_rw_test': ('basic_rw_test', 'Basic Read-Write Test'),
        'basic_read_write_test': ('basic_rw_test', 'Basic Read-Write Test'),
        'fifo_full_test': ('fifo_full_test', 'FIFO Full Test'),
        'fifo_empty_test': ('fifo_empty_test', 'FIFO Empty Test'),
        'reset_test': ('reset_test', 'Reset Test'),
        'rand_test': ('rand_test', 'Original Random Test'),
        'original_random_test': ('rand_test', 'Original Random Test'),
    }
    ACCEPTED_EXTENSIONS = ('.log', '.txt')

    found = {}  # test_id -> (log_path, test_name)
    try:
        names = os.listdir(log_dir)
    except OSError:
        return []

    for name in names:
        base, ext = os.path.splitext(name)
        if ext.lower() not in ACCEPTED_EXTENSIONS:
            continue
        if base not in STEM_TO_TEST:
            continue
        test_id, test_name = STEM_TO_TEST[base]
        path = os.path.join(log_dir, name)
        if not os.path.isfile(path):
            continue
        # Prefer .log over .txt when both exist (simulator output)
        if test_id not in found or ext.lower() == '.log':
            found[test_id] = (path, test_name)

    return [(path, tid, tname) for tid, (path, tname) in found.items()]


def generate_master_report(log_dir='uvm_test_logs', output_dir='html_reports'):
    """Generate master HTML report linking all test logs. Reads .log and .txt from log_dir."""
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Discover all .log and .txt files in uvm_test_logs (no manual copy/rename required)
    log_entries = _discover_log_files(log_dir)
    test_results = []
    
    for log_path, test_id, test_name in log_entries:
        html_file = f'{test_id}.html'
        html_path = os.path.join(output_dir, html_file)
        status, errors, warnings = convert_log_to_html(log_path, html_path, test_name)
        test_results.append({
            'id': test_id,
            'name': test_name,
            'html_file': html_file,
            'status': status,
            'errors': errors,
            'warnings': warnings
        })
    
    # Generate master index.html
    index_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AXI Async FIFO - UVM Verification Report</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }}
        .header {{
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #333;
            margin: 0 0 10px 0;
            font-size: 2.5em;
        }}
        .subtitle {{
            color: #666;
            font-size: 1.1em;
            margin: 0;
        }}
        .section {{
            background-color: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }}
        h2 {{
            color: #333;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
            margin-top: 0;
        }}
        .test-table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }}
        .test-table th {{
            background-color: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }}
        .test-table td {{
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }}
        .test-table tr:hover {{
            background-color: #f5f5f5;
        }}
        .status-badge {{
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9em;
        }}
        .status-pass {{
            background-color: #4caf50;
            color: white;
        }}
        .status-fail {{
            background-color: #f44336;
            color: white;
        }}
        .status-hang {{
            background-color: #ff9800;
            color: white;
        }}
        .status-unknown {{
            background-color: #9e9e9e;
            color: white;
        }}
        .test-link {{
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }}
        .test-link:hover {{
            text-decoration: underline;
        }}
        .summary-stats {{
            display: flex;
            gap: 20px;
            margin-top: 20px;
        }}
        .stat-card {{
            flex: 1;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }}
        .stat-card h3 {{
            margin: 0;
            font-size: 2.5em;
        }}
        .stat-card p {{
            margin: 5px 0 0 0;
            font-size: 1em;
            opacity: 0.9;
        }}
        .footer {{
            text-align: center;
            color: white;
            margin-top: 40px;
            opacity: 0.8;
        }}
        ul {{
            list-style-type: none;
            padding: 0;
        }}
        ul li {{
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }}
        ul li:before {{
            content: "✓ ";
            color: #4caf50;
            font-weight: bold;
            margin-right: 10px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔬 AXI Async FIFO – UVM Verification Report</h1>
            <p class="subtitle">Comprehensive Test Results and Coverage Analysis</p>
        </div>
        
        <div class="section">
            <h2>📊 Test Summary</h2>
            <div class="summary-stats">
"""
    
    # Calculate statistics
    total_tests = len(test_results)
    passed = sum(1 for t in test_results if t['status'] == 'PASS')
    failed = sum(1 for t in test_results if t['status'] == 'FAIL')
    hang = sum(1 for t in test_results if t['status'] == 'HANG')
    
    index_html += f"""
                <div class="stat-card">
                    <h3>{total_tests}</h3>
                    <p>Total Tests</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);">
                    <h3>{passed}</h3>
                    <p>Passed</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #f44336 0%, #da190b 100%);">
                    <h3>{failed}</h3>
                    <p>Failed</p>
                </div>
                <div class="stat-card" style="background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%);">
                    <h3>{hang}</h3>
                    <p>Hanging</p>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>📋 Test Results</h2>
            <table class="test-table">
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Status</th>
                        <th>Errors</th>
                        <th>Warnings</th>
                        <th>Log File</th>
                    </tr>
                </thead>
                <tbody>
"""
    
    for test in test_results:
        index_html += f"""
                    <tr>
                        <td><strong>{test['name']}</strong></td>
                        <td><span class="status-badge status-{test['status'].lower()}">{test['status']}</span></td>
                        <td>{test['errors']}</td>
                        <td>{test['warnings']}</td>
                        <td><a href="{test['html_file']}" class="test-link">View Log →</a></td>
                    </tr>
"""
    
    index_html += """
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>📁 Additional Resources</h2>
            <ul>
                <li>Coverage Report: <a href="cov_html/index.html" style="color: #667eea;">View Coverage Analysis</a></li>
                <li>Waveform Images: Available in uvm_test_logs/ directory</li>
                <li>Source Logs: Original .log / .txt files in uvm_test_logs/ directory</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Generated: """ + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + """</p>
            <p>UVM Version: 1.1d | QuestaSim 10.7c</p>
        </div>
    </div>
</body>
</html>"""
    
    # Write index.html
    index_path = os.path.join(output_dir, 'index.html')
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(index_html)
    
    if not test_results:
        print(f"[WARN] No .log or .txt files found in '{log_dir}'. Run simulation to produce logs there.")
    print(f"[OK] HTML reports generated successfully in '{output_dir}' directory")
    print(f"   - Master report: {index_path}")
    print(f"   - Individual test logs: {len(test_results)} HTML files")
    
    return index_path

if __name__ == '__main__':
    import sys
    
    log_dir = sys.argv[1] if len(sys.argv) > 1 else 'uvm_test_logs'
    output_dir = sys.argv[2] if len(sys.argv) > 2 else 'html_reports'
    
    print("Generating HTML reports from UVM logs...")
    generate_master_report(log_dir, output_dir)