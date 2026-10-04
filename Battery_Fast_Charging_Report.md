ENGINEERING STUDY  /  MATHWORKS CHALLENGE 256

Battery fast chargingoptimization

MATLAB + Simulink + Simscape BatteryDocumented public LG M50 cell | Reproducible simulation and validation

Final technical report | 12 September 2026 | MATLAB R2026a

| Baseline: 20-80% | Best evaluated staged profile | Time reduction |
| --- | --- | --- |
| 72.71 min | 45.25 min | 37.8% |

The recommended simulation candidate requests 7.5 A to 40% SOC, 5 A to 75%, then 2.5 A to 80%. Feedback continuously reduces these requests when a constraint becomes active. The actual applied current is recorded in the delivered traces.

In the nominal 25 C case, this candidate reaches 80.006% SOC with a maximum terminal voltage of 4.1707 V and a maximum core temperature of 33.69 C. This is the best feasible candidate found by the stated search, not a proof of global optimality.

### What this deliverable establishes

The project implements and executes the required baseline, staged charging comparison and each optional advanced workstream. It includes an actual .slx model, public experimental records, fitting, holdout validation, direct collocation, learning-policy exploration, two thermal states and a six-cycle degradation study.

### Limits of the conclusion

The result is a model-based charging recommendation. The measured dataset does not validate the proposed high-current charging rates, and the aging parameters are illustrative. Training and holdout errors, including cases where fitting worsens the prediction, are reported without being treated as safety certification or measured lifetime improvement.

Read the requirement map on page 2, model assumptions on pages 4-6, and the validation and aging results before reusing the charging requests. The report and all reported metrics were generated from the delivered run artifacts.

## Requirement coverage

Core and optional advanced work from the linked MathWorks project. Implemented describes completed technical work, not hardware qualification.

| Workstream | Status | Evidence / scope |
| --- | --- | --- |
| SPM understanding | Implemented | Solid diffusion, electrolyte transport, electrode potential and concentration risk indicators; model equations and parameter mapping. |
| Simscape setup | Executed | BatteryFastCharging.slx uses the actual Battery Single Particle block, current source, physical network and probes. |
| Built-in CC-CV baseline | Executed | Actual Battery CC-CV PI block; 20-80% comparison plus a 98% SOC run to demonstrate voltage taper. |
| 2-4 stage profiles | Executed | SOC-switched 2, 3 and 4-stage profiles with measured time, voltage, temperature and final SOC. |
| Comparison and recommendation | Completed | Numerical and visual comparison; best evaluated feasible profile and limitations. |
| Optimal control | Executed | 25-node direct collocation, independent RK4 replay and guarded Simscape replay; separate full-plant pattern search. |
| Two-state thermal model | Executed | Core thermal mass, surface mass and two thermal resistances; core-temperature feedback. |
| Electrochemical / thermal coupling | Executed | Temperature-dependent reaction rates; explicit diffusion-activation sensitivity case. |
| Parameter fitting / validation | Executed; bounded evidence | Public capacity and OCP; effective diffusion and thermal fit; held-out discharge and charge comparison. No new EIS identification claimed. |
| Degradation / SOH | Executed; illustrative | Six continuous cycles with built-in SEI and reversible / irreversible plating states; lithium-inventory SOH proxy. |
| Adaptive / learning control | Executed; exploratory | Built-in PI and feedback limits; fixed-seed tabular Q-learning with full-plant schedule replay. |
| Registration / submission | Participant action | The package is prepared for review. No external form or forum message has been submitted. |

Data-dependent limits are part of the completed analysis. In particular, the absence of measured fast-charge cycle-life and raw EIS data prevents a quantitative lifetime claim and independent impedance-spectrum fitting. Published OCP curves and effective dynamic fitting are used with explicit provenance.

## Process workflow

A MATLAB-first path from a public cell definition to a reviewable charging recommendation.

### Physical signal path

Stage or scheduled current request  -> sampled thermal / anode-potential supervisor  -> built-in Battery CC-CV PI regulator  -> 0...7.5 A saturation -> 2 s current-source dynamics  -> Simscape Single Particle cell  -> voltage, current, SOC, temperature and concentration probes

### Thermal path and replay mode

The cell core exchanges heat with a surface thermal mass through 1.5 K/W. The surface exchanges heat with the ambient source through 6 K/W in the nominal charging fixture. Experimental and cyclic current replays use a separate input switch. Their broad diagnostic stopping envelope does not replace the charging-policy limits.

### Separation of numerical engines

Simscape is the primary plant. A five-state MATLAB surrogate supports direct collocation and Q-learning. An independently executed PyBaMM SPMe benchmark provides a cross-check. Surrogate times are always identified separately from full-plant replay times.

## Public cell and parameter mapping

LG M50, Chen et al. (2020), DOI 10.1149/1945-7111/ab9050. Public data: Zenodo 4032561.

| Parameter | Value | Basis |
| --- | --- | --- |
| Nominal capacity / comparison SOC | 5 Ah / coulomb counting | Published nominal capacity; explicit common SOC definition |
| Negative / positive thickness | 85.2 / 75.6 micrometers | Published |
| Separator thickness | 12 micrometers | Published |
| Effective electrode area | 0.1027 m^2 | 0.065 m x 1.58 m |
| Negative / positive particle radius | 5.86 / 5.22 micrometers | Published |
| Active volume fractions | 0.750 / 0.665 | Published |
| Maximum solid concentrations | 33133 / 63104 mol/m^3 | Negative / positive |
| Negative stoichiometry range | 0.02635 to 0.91062 | Chen2020 endpoint calculation |
| Positive stoichiometry range | 0.26385 to 0.85397 | Decreases during charge |
| Reference solid diffusivities | 3.30e-14 / 4.00e-15 m^2/s | Published nominal values |
| Initial electrolyte concentration | 1000 mol/m^3 | Explicit high-priority initial target |
| Electrolyte conductivity / diffusivity | 0.9487 S/m / 1.7694e-10 m^2/s | Chen functions evaluated at 1000 mol/m^3 |
| Porosity, negative / separator / positive | 0.250 / 0.470 / 0.335 | Bruggeman exponent 1.5 |
| Cation transference number | 0.2594 | Published |
| Reaction activation energy | 35000 / 17800 J/mol | Negative / positive |
| Core thermal capacity | Computed from layer-weighted rho*Cp | Chen2020 volume 2.42e-5 m^3 |
| Surface capacity / thermal resistances | 8 J/K; 1.5 and 6 K/W | Added casing / fixture assumptions |

The parameter file contains units and the analytic half-cell OCP functions tabulated at 600 stoichiometry points. The exchange-current prefactors are divided by Faraday's constant to match the installed Simscape reaction-rate convention. Activation energies intended to be zero use 1e-6 J/mol because the block requires a positive value.

| Measured C/10 discharge | Capacity (Ah) | Duration (min) |
| --- | --- | --- |
| LGM50_cell02 | 4.99776 | 599.75 |
| LGM50_cell03 | 5.00181 | 600.24 |
| LGM50_cell04 | 4.99330 | 599.22 |

Capacity values are the maximum recorded cumulative discharge Ah in the three C/10 segments. This near-5 Ah result supports the common nominal capacity used in the charging comparison.

## Electrochemistry and thermal model

The implemented SPM retains particle diffusion and electrolyte dynamics; it does not resolve every particle in a porous electrode.

### Solid-phase diffusion and surface loading

dc_s/dt = (1/r^2) * d/dr [r^2 * D_s(T) * dc_s/dr]At r = 0: dc_s/dr = 0At r = R: the flux is set by electrode current / active areaSurface stoichiometry theta_s = c_s,surface / c_s,max

Each electrode is represented by a spherical particle. A surface-to-average concentration gradient grows when charge transport is faster than solid diffusion. The model solves 12 radial shells per electrode in nominal runs and 20 in the refinement check. Anode surface stoichiometry is logged as a concentration-based diagnostic.

### Electrolyte and terminal voltage

epsilon_e * dc_e/dt = d/dx [D_e,eff * dc_e/dx] + reaction sourceD_e,eff = D_e * epsilon_e^bV = U_p(surface) - U_n(surface) + kinetic + transport + ohmic terms

The electrolyte is divided into 12 layers in each region. Concentration and flux are continuous at interfaces, with zero external salt flux. Exchange current depends on electrolyte concentration and electrode surface filling; inverse Butler-Volmer kinetics contributes to voltage. The minimum concentration across all three regions is monitored.

### Core and surface energy balances

C_core * dT_core/dt = Q_cell - (T_core - T_surface)/R_csC_surface * dT_surface/dt = (T_core-T_surface)/R_cs                          - (T_surface-T_ambient)/R_sak(T) = k_ref * exp[(Ea/R) * (1/T_ref - 1/T)]

The built-in cell thermal mass provides the core energy state. The external Thermal Mass supplies the second state. Cell losses heat the core and temperature feeds back into reaction kinetics. Nominal Chen solid diffusion is effectively temperature independent; the separate 20 kJ/mol diffusion-activation case is a sensitivity assumption.

### Plating-risk interpretation

The block exposes an anode-electrolyte potential proxy formed from surface OCP plus kinetic overpotential. The supervisor uses a 20 mV floor and also monitors electrolyte concentration. This is an SPM approximation, not a spatially resolved solid-minus-liquid potential at the anode/separator interface. Concentration and potential margins do not demonstrate the absence of microscopic plating.

## Controller and charging profiles

Common initial SOC 20%, target SOC 80%, ambient and initial temperature 25 C. Positive project current means charging.

| Request | Currents (A) | SOC transition(s) |
| --- | --- | --- |
| Baseline CC-CV | 2.5 | Voltage regulation when 4.195 V is approached |
| Two stages | 5, 2.5 | 55% |
| Three stages | 7.5, 5, 2.5 | 40%, 65% |
| Four stages | 7.5, 5, 3.5, 2.5 | 35%, 50%, 68% |
| Adaptive maximum request | 7.5 | Feedback continuously limits current |
| Best evaluated three-stage request | 7.5, 5, 2.5 | 40%, 75% |

### Control law and implementation

I_request = min(I_stage, I_thermal, I_anode)I_thermal = max(0, 2*(T_limit - 1 K - T_core))I_anode = max(0, 100*(anode_potential - 0.020 V))CC-CV: V_set = 4.195 V; Kp = 20; Ki = 2Anti-windup / tracking gains = 1; sample period = 0.5 sI_applied(s) / I_command(s) = 1 / (2*s + 1)

The actual Battery CC-CV block receives the permitted charging-current request and measured voltage. A latched supervisory fault stops a run for voltage above 4.215 V, core temperature above 45.1 C, potential below -5 mV or electrolyte concentration below 100 mol/m^3. Independent result checks apply the tighter intended study envelope.

A successful charging result must reach the target without a fault. Numerical acceptance tolerances are +2 mV on the 4.2 V ceiling, +0.05 C on 45 C and -3 mV on the 20 mV potential floor. Reported maxima and minima remain visible, so an accepted flag never substitutes for the numerical margins.

The two-second actuator models finite current-source response and prevents controller-induced numerical chattering. SOC integrates the actual cell current, including that response. The internal electrode-based normalized SOC is retained separately in every trace.

### Why a second baseline run is included

A 20-80% comparison may finish before the CV loop dominates. The additional run to 98% SOC explicitly exercises the taper region and prevents a constant-current trajectory from being presented as evidence of tested CV behavior.

## Simscape charging comparison

Measured outputs from the actual delivered model. All rows use the same nominal cell, thermal fixture, SOC definition and feedback limits.

| Profile | Minutes | Max V | Max core C | Final SOC % |
| --- | --- | --- | --- | --- |
| CCCV baseline | 72.71 | 4.1686 | 27.87 | 80.000 |
| two stage | 53.15 | 4.1687 | 33.40 | 80.006 |
| three stage | 46.76 | 4.1697 | 33.69 | 80.004 |
| four stage | 48.38 | 4.1697 | 33.69 | 80.005 |
| adaptive | 45.25 | 4.1707 | 33.69 | 80.006 |
| optimized | 45.25 | 4.1707 | 33.69 | 80.006 |

Figure 1. Actual current, voltage, SOC and core temperature for the baseline, staged and adaptive comparisons.

![Figure 1. Actual current, voltage, SOC and core temperature for the baseline, staged and adaptive comparisons.](../figures/simscape_comparison.png)

The best evaluated staged candidate cuts charging time by 37.8% relative to the 0.5C baseline. Its requested plateaus can be reduced substantially by feedback. Compare the applied-current trace when attributing the gain to a stage transition or an active constraint.

The adaptive maximum request and optimized staged request have the same nominal completion time: feedback limits dominate both trajectories. The staged search does not demonstrate an improvement over that adaptive baseline.

## Electrochemical and thermal margins

Whole trajectories matter: endpoint SOC alone cannot establish voltage, temperature or transport compliance.

Figure 2. Potential proxy, minimum electrolyte concentration, anode surface filling and core-to-surface temperature gradient.

![Figure 2. Potential proxy, minimum electrolyte concentration, anode surface filling and core-to-surface temperature gradient.](../figures/electrochemical_margins.png)

| Optimized candidate | Observed value | Study criterion |
| --- | --- | --- |
| Anode potential proxy, minimum | 43.03 mV | 20 mV nominal floor |
| Electrolyte concentration, minimum | 149.87 mol/m^3 | 100 mol/m^3 floor |
| Surface temperature, maximum | 31.95 C | Core limit is 45 C |

Figure 3. The separate 98% SOC baseline confirms transition toward voltage-controlled current taper.

![Figure 3. The separate 98% SOC baseline confirms transition toward voltage-controlled current taper.](../figures/cccv_taper.png)

High-SOC baseline: 106.33 min to 98.000% SOC; maximum voltage 4.1957 V. The 98% result is a separate operating window and is not mixed into the 20-80% ranking.

## Constrained optimization and learning

A computational shortcut is useful only when its proposed schedule survives the full plant.

### Full-plant staged optimization

Pattern search evaluates three current levels and two SOC thresholds directly against Simscape. Currents are non-increasing; thresholds have a minimum 5% SOC separation. The search evaluated 39 candidates and returned exit flag 1. An infeasible or failed run receives a penalty; the saved candidate is the best feasible evaluated profile.

### Direct-collocation formulation

minimize t_finalstate x = [SOC, negative diffusion lag, positive diffusion lag,           core temperature, surface temperature]0 <= I <= 7.5 A; V <= 4.195 V; T_core <= 45 Canode potential >= 20 mV; theta_n <= 0.98; theta_p >= 0.02x[k+1]-x[k] = dt/2 * (f(x[k],I[k]) + f(x[k+1],I[k+1]))

The 25-node trapezoidal transcription uses fmincon SQP with a free final time and fixed initial/target SOC. It converged in 86 iterations (exit 1); maximum scaled defect 1.80e-14. A separate 2 s RK4 integration checks the surrogate schedule before Simscape replay. The surrogate omits resolved electrolyte dynamics and therefore can be optimistic.

| Method | Surrogate minutes | Guarded Simscape minutes |
| --- | --- | --- |
| Direct collocation | 26.00 | 45.51 |
| Q-learning policy | 43.83 | 55.03 |
| Full-plant staged search | Not used | 45.25 |

### Learning experiment

Tabular Q-learning uses 16 SOC bins, 8 core-temperature bins and 8 anode-diffusion-lag bins. Five current actions are filtered against the surrogate constraints. The fixed seed is 42; 100 episodes contain 22831 steps, with 100% training completion. Reward favors SOC increase and penalizes elapsed time and elevated temperature, with a terminal bonus. The delivered learned schedule is exploratory; it is replayed with full-plant feedback, not claimed to be an online optimal controller.

The built-in PI controller fulfills the feedback-control workstream. An MPC implementation is not necessary for the project's PI-or-MPC choice. No Reinforcement Learning Toolbox is needed for this tabular experiment.

## Experimental fitting and discharge validation

Real authors' LG M50 measurements. Cell 02 is used for fitting; cells 03 and 04 are held out.

The fit adjusts effective negative diffusion (9.127e-15 m^2/s), positive diffusion (2.508e-15 m^2/s) and surface-to-ambient resistance (7.839 K/W). Radii, OCP, capacity, core-to-surface resistance and casing capacity remain fixed. The least-squares objective normalizes voltage by 30 mV and surface temperature by 1 C, with equal sample-count weighting per trace.

| Cell / rate / role | V RMSE before (mV) | V RMSE fitted (mV) | T RMSE (C) | Coverage |
| --- | --- | --- | --- | --- |
| cell02 / 0.5C / fit | 55.04 | 30.62 | 0.76 | 100.0% |
| cell02 / 1.0C / fit | 59.98 | 39.88 | 1.78 | 100.0% |
| cell03 / 1.0C / validation | 54.26 | 39.84 | 2.28 | 100.0% |
| cell04 / 1.5C / validation | 55.24 | 91.64 | 2.84 | 100.0% |

Figure 4. Measured and fitted voltage on training and held-out discharges.

![Figure 4. Measured and fitted voltage on training and held-out discharges.](../figures/simscape_validation.png)

Coverage refers to the selected comparison window: the first 90% of each discharge duration, sampled at every second record. The terminal knee is excluded explicitly. Measured discharge replays use a broad diagnostic stopping envelope so a proposed charging temperature limit cannot censor the validation data.

Fitting is not automatically an improvement on held-out data. Differences in high-rate voltage and temperature remain model discrepancy. These effective parameters are stored separately from the published nominal parameter set and are not silently substituted into the headline comparison.

## Held-out charging and parameter sensitivity

The dataset contains 0.3C charging. It does not provide a measured 1.5C fast-charge validation of the proposed policy.

A separate cell 04, 0.3C charge segment is held out from parameter fitting. Initial SOC is inferred from the preceding rest-end voltage by inverting the fixed published OCP relation. The comparison uses the first 90% of the constant-current phase; no charge samples are used to fit the parameters or the initial state.

| Measured-charge validation | Result |
| --- | --- |
| Initial inferred SOC | 3.37% |
| Voltage RMSE | 50.52 mV |
| Surface-temperature RMSE | 0.99 C |
| Selected-window coverage | 100.00% |

Figure 5. Held-out charge voltage and surface temperature.

![Figure 5. Held-out charge voltage and surface temperature.](../figures/heldout_charge_validation.png)

| Charging sensitivity | Minutes | Max V | Max core C | Feasible |
| --- | --- | --- | --- | --- |
| Published nominal cell / nominal fixture | 45.25 | 4.1707 | 33.69 | True |
| Fitted diffusivities / nominal fixture | 47.67 | 4.1869 | 34.97 | True |
| Fitted diffusivities / fitted fixture | 46.00 | 4.1891 | 37.69 | True |

The capacity records are obtained from C/10 discharge. OCP comes from published cell parameterization, not an invented pulse test. No raw EIS spectra exist in the selected files, so neither an independently measured impedance spectrum nor a uniquely identified particle diffusivity is claimed.

## Operating-condition robustness

Eighteen Simscape runs: two strategies, three initial SOC values and three initial/ambient temperatures.

Figure 6. Baseline and optimized requests over 15, 25 and 35 C, with initial SOC 10%, 20% and 40%.

![Figure 6. Baseline and optimized requests over 15, 25 and 35 C, with initial SOC 10%, 20% and 40%.](../figures/robustness.png)

| Initial / ambient C | Initial SOC % | Baseline min | Optimized min | Opt. max core C | Opt. feasible |
| --- | --- | --- | --- | --- | --- |
| 15 | 10 | 89.14 | Fault @ 1.16 | 18.42 | 0 |
| 15 | 20 | 77.32 | 57.98 | 21.81 | 1 |
| 15 | 40 | 53.67 | 46.31 | 19.97 | 1 |
| 25 | 10 | 84.67 | Fault @ 1.16 | 28.21 | 0 |
| 25 | 20 | 72.71 | 45.25 | 33.69 | 1 |
| 25 | 40 | 48.79 | 35.77 | 31.66 | 1 |
| 35 | 10 | 84.03 | Fault @ 1.16 | 38.01 | 0 |
| 35 | 20 | 72.03 | Fault @ 1.16 | 37.58 | 0 |
| 35 | 40 | 48.03 | 31.29 | 41.92 | 1 |

Initial core and surface temperatures are explicitly enforced and asserted against the requested values. Electrolyte concentration is initialized at 1000 mol/m^3 with a high-priority target. A final audit corrected initial-state settings that otherwise retained block defaults; the reported results come from the corrected runs.

These deterministic scenarios check sensitivity to a limited set of operating conditions. They do not establish statistical reliability across manufacturing variation, cold-weather operation below 15 C, sensor errors, cooling faults or aged cells.

The staged request fails 4 of its nine initial-condition tests by triggering the electrolyte guard. These short, incomplete runs are failures, not fast-charge successes. select_tested_profile.m selects the baseline for failed conditions and the staged request for successful tested conditions. The selector is checked against the existing full-plant results; it does not establish safety between grid points.

## Numerical verification and cross-check

Execution success, constraint feasibility, numerical convergence and experimental accuracy are separate questions.

| Refinement check | Measured difference | Interpretation |
| --- | --- | --- |
| Spatial / temporal refinement | 0.2210% charge time | 12 to 20 shells and layers; max step 1 to 0.25 s |
| Maximum voltage | 0.2442 mV | Refined minus nominal |
| Maximum core temperature | 0.0118 C | Refined minus nominal |

Nominal integration uses ode23t with relative tolerance 1e-5 and absolute tolerance 1e-7. The refined case tightens these to 1e-6 and 1e-8. The controller sample period remains 0.5 s. Coulomb consistency is checked from the exported current integral versus the independent SOC increment.

### Independent PyBaMM SPMe result

| Profile | Time (min) | Maximum V | Maximum core C |
| --- | --- | --- | --- |
| CCCV_0p5C | 73.07 | 4.1542 | 26.63 |
| two_stage | 54.55 | 4.1543 | 29.45 |
| three_stage | 49.04 | 4.1548 | 29.88 |
| four_stage | 49.93 | 4.1549 | 29.88 |
| adaptive_max_request | 48.16 | 4.1551 | 29.88 |
| optimized_three_stage | 48.16 | 4.1551 | 29.88 |

The independent benchmark uses a separate implementation with concentration-dependent electrolyte transport and a proportional CV reference law. Simscape uses constant reference electrolyte transport with temperature scaling and the built-in PI CC-CV block. Their trajectories need not coincide. The benchmark is a model cross-check, not experimental validation.

### Recorded verification

MATLAB release: 2026a. Parse issues: 0. Pipeline steps executed successfully: 10 / 10. Detailed checks and step-level errors, if any, are preserved in verification/final_checks.json and verification/pipeline_status.json.

Interpretation tests also verify the initial core/surface temperatures, electrolyte concentration, initial SEI thickness for aging, completion of all aging cycles, and full selected-window validation coverage. A failed assertion raises an error instead of writing a successful metric.

## Six-cycle degradation and SOH analysis

Built-in R2026a SEI and plating states. This is an uncalibrated degradation experiment.

Figure 7. Lithium-inventory SOH proxy over six continuous charge/discharge cycles.

![Figure 7. Lithium-inventory SOH proxy over six continuous charge/discharge cycles.](../figures/aging_comparison.png)

| Strategy | Elapsed hours | SEI thickness (nm) | Irreversible Li (mol) | SOH proxy % |
| --- | --- | --- | --- | --- |
| CCCV baseline | 14.67 | 28.13 | 0.000e+00 | 99.1308 |
| optimized | 11.93 | 25.87 | 0.000e+00 | 99.2159 |

Each cycle replays the previously applied charge current, rests for 60 s, discharges at 2.5 A for equal coulomb throughput, then rests for 60 s. The six cycles are simulated in one continuous run per strategy, preserving the electrochemical, thermal and aging states. This cyclic replay characterizes a fixed waveform; it is not a re-optimized charger for every aged cycle.

Delta n_SEI = A_active * (L_SEI - L_SEI_initial) * 2 / V_mSOH_inventory = 1 - F*(Delta n_SEI + n_Li,irreversible)/(3600*5 Ah)

Illustrative inputs: initial SEI 5 nm, molar volume 9.585e-5 m^3/mol, interstitial diffusivity 1e-20 m^2/s, SEI conductivity 5e-6 S/m; plating exchange current 3e-4 A/m^2 and reversible fraction 0.5. Diffusion activation is effectively zero in this illustration; SEI conductivity and plating retain their explicitly documented built-in temperature dependence.

A shorter charge can reduce time available for SEI growth in this chosen model, while a hotter or more aggressive policy can increase other aging mechanisms. The plotted ordering is specific to these assumptions. Zero modeled irreversible plating does not prove its absence in a real cell. The proxy is not an experimentally measured capacity-retention or cycle-life prediction.

## Run, inspect and extend the project

The saved model and study scripts are the primary deliverable; the report is their evidence trail.

### Open the model

cd('<your extracted BatteryFastCharging folder>')run('start_project.m')

The saved .slx contains the nominal parameter structure in its model workspace and a 2.5 A baseline configuration. start_project adds the MATLAB source folder and opens the model. Run it from the extracted project folder, not from the ZIP.

### Reproduce all studies

addpath('matlab')status = run_project();

Required products: MATLAB, Simulink, Simscape, Simscape Battery, Optimization Toolbox and Global Optimization Toolbox. The project was executed in R2026a. The built-in SEI/plating options require this release. The pipeline continues independent steps after an error and records the outcome; inspect the status JSON before treating a rerun as complete.

| Location | Contents |
| --- | --- |
| matlab/ | Builder, supervisor, full-plant optimizer, fitting, collocation, Q-learning, replays, aging and checks. |
| data/raw/ and data/processed/ | Unmodified public measurements; time in seconds, positive charging current in A, voltage in V, temperatures in C. |
| data/source_manifest.json | Dataset DOI, CC BY 4.0 license, URLs and SHA-256 / source MD5 checksums. |
| results/ | Actual traces, per-run metrics, optimization histories, validation predictions and learning tables. |
| figures/ and report/ | Study graphics, model image, this PDF and editable Markdown report. |
| verification/ | Pipeline execution and assertion results; package integrity manifest. |
| python/ | Optional independent SPMe benchmark with pinned dependencies. |

### Changing the study

Edit project_parameters.m and rerun the pipeline. Keep published cell properties, fitted experimental parameters and hypothetical sensitivity assumptions distinguishable. The comparison SOC is a common 5 Ah current integral; the model's internal electrode SOC has a different normalization and is logged separately.

[p, choice] = select_tested_profile(0.2, 25);[metrics, trace] = run_case(p, 'recommended');

The optional Python benchmark uses positive discharge current internally. Its exports convert to the project's positive-charge convention. The primary MATLAB pipeline does not depend on the Python installation.

## Sources, provenance and remaining limits

Primary sources and explicit boundaries of the completed engineering study.

1. [MathWorks project 256](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/tree/main/projects/Battery%20Fast%20Charging%20Optimization)

2. [Battery Single Particle documentation](https://www.mathworks.com/help/simscape-battery/ref/batterysingleparticle.html)

3. [Battery CC-CV documentation](https://www.mathworks.com/help/simscape-battery/ref/batterycccv.html)

4. [Chen et al., cell parameterization paper (2020)](https://doi.org/10.1149/1945-7111/ab9050)

5. [Authors' LG M50 experimental measurements](https://zenodo.org/records/4032561)

6. [PyBaMM source and parameter implementations](https://github.com/pybamm-team/PyBaMM)

7. [MathWorks fast-charge methodology](https://www.mathworks.com/company/technical-articles/generating-safe-fast-charge-profiles-for-ev-batteries.html)

8. [Public Chen parameter reference and license](https://github.com/rtimms/compare-pybamm-models)

### Data and code attribution

The raw LG M50 records are redistributed with attribution under the dataset's CC BY 4.0 license. The source manifest preserves author-hosted URLs and checksums. The published parameter reference license is included as data/REFERENCE_LICENSE.txt. MATLAB and MathWorks library implementation files are not redistributed; the delivered .slx refers to installed library blocks.

### What remains outside the evidence

The selected measurements contain no raw EIS spectra or high-rate charging cycle-life series. OCP and geometry are adopted from the published public cell; diffusion and thermal estimates are effective fits to dynamic discharge. Anode potential is an SPM proxy. Aging inputs are illustrative. Real charger design would require cell-specific charge characterization, aging calibration, independent safety assessment and hardware validation before deployment.

The initial-state audit and full-plant replay are reflected in the final numerical results. Failed development runs and temporary licensing/runner logs are excluded from the final scientific evidence. All completed steps remain reproducible from the packaged sources, data and settings.

### Submission

The linked challenge provides registration and solution-submission forms. The participant must review the package and submit using their own identity. No registration, forum post or external submission has been made by this project run.
