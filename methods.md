# Battery fast charging: revised methods and evidence

## Scope and data
This study compares requests for charging a nominal 5 Ah LG M50 cell from 20% to 80% coulomb-counted SOC. The published Chen et al. parameterization fixes geometry, stoichiometry and OCP curves. The redistributed raw records are the authors' public cell02, cell03 and cell04 characterization files (Zenodo 4032561, CC BY 4.0). They contain low-rate charging and several discharge rates, not high-rate charge cycle-life validation.

The proposed currents, thermal fixture and constraint values are study assumptions. The model is not evidence of manufacturer-approved charging or of experimentally validated plating prevention. Its anode potential and lithium-inventory loss are model outputs, not measurements. The separate historical paper and video predate this revision and cannot substantiate its numerical results.

## Electrochemical and thermal model
The Simscape Battery Single Particle block includes solid diffusion and electrolyte dynamics. Each electrode uses 12 radial shells; the three electrolyte regions default to 12 layers each and may now be configured independently. The spatial minimum is computed within each region before comparing the three scalar minima. The OCP lookup has 600 absolute-stoichiometry points.

Positive current charges the cell. Reported SOC follows dz/dt = I/(3600 Q), with Q = 5 Ah; the block's internal normalized electrode SOC is also logged. Core thermal capacity is 42.775 J/K and surface capacity is 8 J/K. Explicit Foundation Thermal Resistance blocks connect core to surface (1.5 K/W) and surface to ambient (6 K/W). These thermal assumptions are distinct from the effective resistance fitted to experiments.

## Controller and termination
The four stage requests are derived from p.Istages at run time. A MATLAB Function supervisor receives named measurements and sets the charge-current ceiling to the minimum of the request, the 7.5 A ceiling and three proportional limits: thermal, anode potential and electrolyte concentration. The electrolyte term is max(0, 0.02 (ce_min - 100 - 100)) A. The additional 100 mol/m^3 soft margin leaves room for diffusion and actuator dynamics before the hard 100 mol/m^3 floor. All gains, soft margins and hard thresholds are named parameters.

The built-in Battery CC-CV controller regulates to 4.195 V under a 4.2 V hard ceiling. A shared downstream saturation clamps both operating modes to [-7.5, 7.5] A. A shared terminal gate commands zero on completion or fault, followed by a two-second actuator time constant. The model stops when measured current is at most 0.01 A after at least 0.5 seconds of settling, or after a 20-second maximum shutdown window. The recorded terminal current makes the distinction inspectable.

Termination codes are 0 running, 1 target completed, 2 high voltage, 3 high temperature, 4 low anode potential, 5 electrolyte depletion, 6 low voltage/SOC, 7 nonfinite measurement, 8 duration expired without completion, and 9 scheduled diagnostic replay finished. Codes 8 and 9 are assigned by postprocessing. A fault never qualifies as a completed charge. Duration is time to the completion event when reached; stop_time_s includes shutdown settling. Delivered charge and energy include the tail.

## External replay and degradation modes
Normal positive external requests pass through the same derating and CC-CV regulator. Negative current uses the shared bipolar clamp and hard protection. CharacterizationReplay is an explicit opt-in for matching measured current or charge-balanced aging schedules: it bypasses charging-specific soft limits and CV regulation, but retains the downstream current clamp, hard diagnostic guards and shutdown gate. Its declared diagnostic limits are 4.25 V, 2.0 V, 60 C, 1 mol/m^3 electrolyte and -50 mV anode potential. Such traces are never classified as feasible charging policies.

EnableAging selects diffusion-limited SEI growth and fractional reversible plating through SimulationInput block overrides. Enabled SEI starts at 5 nm and is asserted against the logged state. Disabled degradation outputs are NaN with aging_enabled = 0. The six-cycle demonstration uses illustrative side-reaction parameters, replays charge-balanced schedules and computes a lithium-inventory SOH proxy. It does not predict measured capacity retention or lifetime. Measured incremental-capacity curves provide a separate cross-cell diagnostic, not a calibration of these side reactions.

## Optimization, fitting and reinforcement learning
Pattern search evaluates staged requests directly against the protected Simscape model. Its finite budget supports a best-tested candidate claim, not a global optimum. Trapezoidal direct collocation remains explicitly a reduced-model calculation; its requested current must then complete a full-plant replay. A lower surrogate time alone is not accepted as a charging improvement.

Grouped estimation uses Simulink Design Optimization SimulationTest objects, SignalTracking residual requirements and sdo.optimize. Two cell02 discharge records provide the objective; cell03 and cell04 discharge windows and cell04 low-rate charging are held out. Effective anode/cathode diffusivities and surface-to-ambient resistance are estimated with geometry and OCP fixed. Each record uses its first 90% duration and every second sample. Voltage residuals are scaled by 30 mV and temperature residuals by 1 C, then by the square root of each record's sample count. Full-window coverage is required. The dataset contains no EIS spectra, so no measured impedance fit is claimed.

Reinforcement Learning Toolbox Q-learning trains directly through rlSimulinkEnv on the same protected electrochemical plant. The tabular observation encodes 16 SOC bins, 8 temperature bins and 8 electrolyte-concentration bins. Five actions request 1.5, 2.5, 3.5, 5 or 7.5 A every 10 seconds. The reward combines SOC progress, elapsed-time cost, a warm-cell penalty and terminal reward/penalty. Seed 42, training options, statistics and agent are saved. The nominal comparison uses a greedy full-plant evaluation with the shutdown tail. Finite training does not establish convergence or superiority.

## Reproducibility and interpretation
Profile, operating-condition and mesh sweeps use independent SimulationInput objects and parsim. The model stores no author-machine root path. Fresh-clone execution starts with start_project.m and run_project; the latter records each stage and fails explicitly if a required stage fails. Native MATLAB/Simulink Report Generator produces this PDF. Python is optional for the separate PyBaMM cross-check, whose electrolyte transport laws and CV implementation differ from Simscape.

The binding limiter is logged and its fraction is weighted by elapsed simulation time. Similar staged and adaptive results can arise when the common safety supervisor dominates the requested schedule. Report this tie prominently rather than attributing it to a sophisticated optimizer. The operating grid covers exact initial conditions only; it does not prove a continuous safe operating envelope. Optional MPC remains future work.

## Primary references
Chen C-H et al. Development of Experimental Techniques for Parameterization of Multi-scale Lithium-ion Battery Models. Journal of The Electrochemical Society 167 (2020), 080534. DOI: 10.1149/1945-7111/ab9050.

Chen C-H et al. Experimental dataset. Zenodo record 4032561. https://zenodo.org/records/4032561 (CC BY 4.0; full attribution in data/DATA_ATTRIBUTION.md).

MathWorks. Battery Single Particle; Battery CC-CV. https://www.mathworks.com/help/simscape-battery/ref/batterysingleparticle.html and https://www.mathworks.com/help/simscape-battery/ref/batterycccv.html.

MathWorks. sdo.SimulationTest; sdo.requirements.SignalTracking; sdo.optimize. https://www.mathworks.com/help/sldo/ref/sdo.simulationtest.html.

MathWorks. rlSimulinkEnv and rlTable. https://www.mathworks.com/help/reinforcement-learning/ref/rlsimulinkenv.html and https://www.mathworks.com/help/reinforcement-learning/ref/rltable.html.

MathWorks. batteryTestDataParser; batteryTestFeatureExtractor; batteryDifferentialCurves; batteryDifferentialCurveFeatures. https://www.mathworks.com/help/predmaint/ref/batterytestdataparser.html.
