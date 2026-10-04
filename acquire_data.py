"""Optional: re-download the three original public records using the manifest.
The delivered data are already present; normal MATLAB execution is offline.
"""
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'data/source_manifest.json').read_text())
for record in manifest['files']:
    data = urlopen(record['url'], timeout=120).read()
    assert hashlib.sha256(data).hexdigest() == record['sha256']
    assert 'md5:' + hashlib.md5(data).hexdigest() == record['zenodo_checksum']
    (root / 'data/raw' / record['file']).write_bytes(data)
    print('Verified:', record['file'])
