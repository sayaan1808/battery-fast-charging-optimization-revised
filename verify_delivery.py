"""Read-only package checks plus a provenance manifest; no scientific rerun."""
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'data/source_manifest.json').read_text())
for record in manifest['files']:
    file = root / 'data/raw' / record['file']
    assert hashlib.sha256(file.read_bytes()).hexdigest() == record['sha256'], file
missing = []
for doc in [root / 'README.md', root / 'data/DATA_ATTRIBUTION.md']:
    for target in re.findall(r'\]\(([^)]+)\)', doc.read_text(encoding='utf-8-sig')):
        if '://' not in target and not (doc.parent / target.split('#')[0]).exists():
            missing.append(f'{doc.name}: {target}')
assert not missing, missing
required = ['matlab/run_project.m', 'matlab/build_simscape_model.m',
            'report/Battery_Fast_Charging_Report.pdf', 'LICENSE',
            'verification/pipeline_status.json', 'verification/final_checks.json',
            'verification/revision_regressions.json']
for relative in required:
    assert (root / relative).is_file(), relative
pipeline = json.loads((root / 'verification/pipeline_status.json').read_text())
assert all(row['executed'] for row in pipeline), 'Pipeline has failed stages'
checks = json.loads((root / 'verification/final_checks.json').read_text())
assert checks['technical_checks_pass'], 'Scientific checks failed'
files = []
for file in sorted(root.rglob('*')):
    relative = file.relative_to(root)
    if not file.is_file() or any(x in {'.git','slprj','__pycache__','historical','mplconfig'} or x.endswith('.tmp') for x in relative.parts):
        continue
    if file.suffix in {'.slxc','.log','.asv'} or file.name in {'package_manifest.json','delivery_checks.json'}:
        continue
    files.append({'path': relative.as_posix(), 'bytes': file.stat().st_size,
                  'sha256': hashlib.sha256(file.read_bytes()).hexdigest()})
(root / 'verification/package_manifest.json').write_text(json.dumps(files, indent=2))
(root / 'verification/delivery_checks.json').write_text(json.dumps({
    'raw_checksums_match': True, 'readme_links_resolve': True,
    'required_files_present': True, 'pipeline_passed': True,
    'technical_checks_passed': True, 'manifest_files': len(files)}, indent=2))
print(f'Package checks passed: {len(files)} files')
