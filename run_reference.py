"""Optional independent benchmark; preserves native MATLAB data processing."""
import json
from datetime import datetime, timezone
import pybamm
from reference_study import ROOT, ChargingModel, save_json
from optimize_reference import execute

if __name__ == '__main__':
    trace, metrics = ChargingModel().solve()
    trace.to_csv(ROOT / 'results/reference_baseline.csv', index=False)
    save_json('reference_baseline_metrics.json', metrics)
    execute()
    (ROOT / 'verification/reference_run.json').write_text(json.dumps({
        'executed': True, 'pybamm_version': pybamm.__version__,
        'created_utc': datetime.now(timezone.utc).isoformat(),
        'scope': 'Independent SPMe and different CV/protection implementation; not a Simscape replay',
        'raw_or_processed_data_modified': False}, indent=2))
