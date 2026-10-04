# Battery Fast Charging Optimization

A reproducible MATLAB R2026a / Simscape Battery study of the public Chen2020 LG M50 cell, revised in response to the MathWorks Challenge review.

## Run the project

Clone this repository, open its folder in MATLAB, then run:

```matlab
run('start_project.m')
status = run_project;
```

The complete run rebuilds both models, tests protection, processes the public data with Predictive Maintenance Toolbox, compares five charging profiles, performs direct-plant pattern search, grouped SDO fitting, held-out validation, direct collocation, 100 episodes of full-plant RL training, the 18-case operating grid, spatial/time refinement and six-cycle aging, and generates the native PDF report. It records failures and raises an error if any required stage fails. Allow time for training and parallel workers to start.

Required products: MATLAB, Simulink, Simscape, Simscape Battery, Optimization Toolbox, Global Optimization Toolbox, Simulink Design Optimization, Reinforcement Learning Toolbox, Predictive Maintenance Toolbox, Parallel Computing Toolbox, MATLAB Report Generator and Simulink Report Generator. R2026a is required for the aging and diagnostic APIs used here. No Python installation is required for this pipeline.

For a quick model check:

```matlab
addpath('matlab');
p = project_parameters();
build_simscape_model(p);
revision_regression_tests;
[metrics, trace] = run_case(p, 'baseline_check');
```

## Evidence and interpretation

The complete 14-stage pipeline passed from a fresh local Git clone with pre-generated results removed (MATLAB R2026a, 48.6 minutes). It includes 100 full-plant RL episodes and 18/18 feasible operating-grid cases. See [fresh-clone provenance](verification/fresh_clone.json), [pipeline status](verification/pipeline_status.json), and [protection regressions](verification/revision_regressions.json). A subsequent report-only rebuild corrected chart sizing; the tested model and study sources are unchanged.

The revised nominal comparison gives 72.71 minutes for 0.5C CC-CV and 48.18 minutes for an adaptive maximum-current request. The best tested staged profile also takes 48.18 minutes. **The shared protection limits dominate the optimized request: the tie is a result, not an optimizer improvement.** These figures are simulation benchmarks. Read the newly generated [report](report/Battery_Fast_Charging_Report.pdf), [comparison](results/simscape_comparison.csv), [optimization](results/simscape_optimization.json) and elapsed-time-weighted `binding_fraction_*` fields for details.

The cell is charged from 20% to 80% coulomb-counted SOC, with nominal 5 Ah capacity and initial/ambient temperature 25 C. Study ceilings are 7.5 A, 4.2 V and 45 C; CC-CV regulates to 4.195 V. The anode-potential proxy target is 20 mV and the minimum electrolyte concentration is 100 mol/m^3. These are model-study assumptions, not manufacturer approval or experimental certification.

Public data cover low-rate charging and multiple discharge rates. High-rate charging and long-term degradation are not experimentally validated. The side-reaction coefficients are illustrative; the six-cycle lithium-inventory SOH proxy is not measured capacity retention. Measured IC features are a separate cross-cell characterization diagnostic, not a life-test series.

Fitting does not improve every holdout: inspect the before/after errors in [validation metrics](results/simscape_validation_metrics.csv), especially the higher-rate cell04 discharge. A completed validation window is not an accuracy acceptance criterion.

[Watch the 30-second recorded simulation playback](report/charging_demo.mp4). This shows saved model traces, not live experimental footage. Regenerate it with `record_demo` (also included in `run_project`).

## Protection and replay

Every mode passes through one bipolar current clamp and one terminal gate. Normal positive external requests also pass through the supervisor and CC-CV regulator. `CharacterizationReplay = 1` explicitly permits measured-current/aging replay outside the charging-specific soft envelope while retaining current saturation, declared diagnostic guards and settled shutdown. Diagnostic traces can never be labelled feasible charging policies. See [methods](report/methods.md) for exact thresholds.

Completion and faults latch a zero-current command. Simulation continues through actuator settling. The trace contains `complete`, `fault`, `termination_reason`, `stop_after_settling` and applied/commanded currents. Codes: 1 completed; 2 high V; 3 high T; 4 anode; 5 electrolyte; 6 low V/SOC; 7 nonfinite; 8 unfinished duration; 9 completed diagnostic schedule. Charging time and final stop time are separate metrics.

`p.Istages` is the single staged-request input. `make_simulation_input` derives the profile and strips the run-time root path. `p.EnableAging = true` selects SEI/plating per run and verifies 5 nm initial SEI; disabled channels are NaN.

```matlab
p = project_parameters();
p.EnableAging = true;
p.Duration = 60;
[metrics, trace] = run_case(p, 'enabled_aging_check');
```

## Repository contents

| Path | Contents |
|---|---|
| [matlab/](matlab/) | Builders, named supervisor, SimulationInput/parsim runners, all studies and verification |
| [data/raw/](data/raw/) | Three unmodified public Maccor records |
| [data/processed/](data/processed/) | Per-step records with positive charging current and unit-bearing headers |
| [data/source_manifest.json](data/source_manifest.json) | URLs and checksums |
| [data/chen2020_parameters.json](data/chen2020_parameters.json) | Published parameter snapshot |
| [data/DATA_ATTRIBUTION.md](data/DATA_ATTRIBUTION.md) | CC BY 4.0 attribution and changes to derived data |
| [results/](results/) | Executed traces, metrics, native features, fitted parameters, saved RL agent/statistics |
| [figures/](figures/) | Generated comparisons, diagnostics and validation plots |
| [verification/](verification/) | Protection regressions, pipeline status and final assertions |
| [report/](report/) | Native PDF builder, editable methods and revised report |
| [python/](python/) | Optional independent PyBaMM cross-check and pinned requirements |
| [REVIEW_RESPONSE.md](REVIEW_RESPONSE.md) | Review-item mapping to code and evidence |
| [LICENSE](LICENSE) | MIT license for original code/documentation |

`run_project` includes report generation. To rebuild only the PDF after executing the studies:

```matlab
addpath('matlab','report');
build_report;
```

For an exact tested grid condition, `select_tested_profile(0.2,25)` chooses a feasible request from recorded grid evidence. It makes no safety claim between or outside those conditions. The optional Python SPMe benchmark has different electrolyte transport laws and a different CV controller; it is not expected to match Simscape numerically. The earlier report, manuscript and video predate this revision and must not be used as its evidence. Optional MPC remains future work.

## Primary sources

- [MathWorks Challenge](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/tree/main/projects/Battery%20Fast%20Charging%20Optimization)
- [Chen et al., JES 2020](https://doi.org/10.1149/1945-7111/ab9050)
- [Public experimental dataset](https://zenodo.org/records/4032561)
- [Simscape Battery Single Particle](https://www.mathworks.com/help/simscape-battery/ref/batterysingleparticle.html)
- [Battery CC-CV](https://www.mathworks.com/help/simscape-battery/ref/batterycccv.html)

The data retain CC BY 4.0. The third-party BSD notice is retained in [data/REFERENCE_LICENSE.txt](data/REFERENCE_LICENSE.txt). MATLAB/toolbox products are separately licensed and are not redistributed.
