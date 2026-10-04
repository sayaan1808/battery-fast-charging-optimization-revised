"""Build the final report from actual MATLAB artifacts. No simulated metrics here."""
from pathlib import Path
import csv, json, re, html, math
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, KeepTogether
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon
from PIL import Image as PILImage

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'report';OUT.mkdir(exist_ok=True)
def J(name):return json.loads((ROOT/'results'/name).read_text())
def C(name):
    with (ROOT/'results'/name).open(newline='') as f:return list(csv.DictReader(f))
def n(x):return float(x)
def f(x,d=2):return f'{float(x):.{d}f}'
def plain(s):return html.unescape(re.sub('<[^>]+>','',s))
baseline=J('simscape_CCCV_baseline_metrics.json');best=J('simscape_optimization.json');opt=best['metrics']
comparison=C('simscape_comparison.csv');fit=J('simscape_parameter_fit.json');validation=C('simscape_validation_metrics.csv')
charge=J('heldout_charge_validation.json');coll=J('direct_collocation.json');rl=J('rl_summary.json')
cr=J('simscape_collocation_replay_metrics.json');rr=J('simscape_rl_replay_metrics.json')
conv=J('simscape_convergence.json');robust=C('simscape_robustness.csv');aging=C('aging_summary.csv')
checks=json.loads((ROOT/'verification/final_checks.json').read_text())
pipeline=json.loads((ROOT/'verification/pipeline_status.json').read_text())
saving=100*(1-opt['duration_s']/baseline['duration_s'])

NAVY=colors.HexColor('#132E46');TEAL=colors.HexColor('#007F83');LIGHT=colors.HexColor('#EAF3F3');GRAY=colors.HexColor('#52616D')
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyX',fontName='Helvetica',fontSize=9.5,leading=13.5,textColor=NAVY,spaceAfter=9))
styles.add(ParagraphStyle(name='SmallX',fontName='Helvetica',fontSize=8,leading=10.5,textColor=GRAY,spaceAfter=6))
styles.add(ParagraphStyle(name='TitleX',fontName='Helvetica-Bold',fontSize=28,leading=32,textColor=NAVY,spaceAfter=15))
styles.add(ParagraphStyle(name='HeadX',fontName='Helvetica-Bold',fontSize=20,leading=24,textColor=NAVY,spaceAfter=15))
styles.add(ParagraphStyle(name='SubX',fontName='Helvetica-Bold',fontSize=11,leading=15,textColor=TEAL,spaceAfter=8))
styles.add(ParagraphStyle(name='CellX',fontName='Helvetica',fontSize=8,leading=10.5,textColor=NAVY))
styles.add(ParagraphStyle(name='CellH',fontName='Helvetica-Bold',fontSize=8,leading=10.5,textColor=colors.white))
styles.add(ParagraphStyle(name='CodeX',fontName='Courier',fontSize=8,leading=12,textColor=NAVY,backColor=LIGHT,borderPadding=9,spaceAfter=12))
story=[];md=[]
def P(s,kind='BodyX'):
    story.append(Paragraph(s,styles[kind]));md.append(plain(s)+'\n')
def H(s):P(s,'SubX');md[-1]='### '+md[-1]
def page(title,subtitle=None):
    if story:story.append(PageBreak())
    P(title,'HeadX');md[-1]='## '+md[-1]
    if subtitle:P(subtitle,'SmallX')
def table(headers,rows,widths=None):
    if widths is None:widths=[505/len(headers)]*len(headers)
    data=[[Paragraph(str(v),styles['CellH']) for v in headers]]+[[Paragraph(str(v),styles['CellX']) for v in row] for row in rows]
    t=Table(data,colWidths=widths,hAlign='LEFT',repeatRows=1)
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),NAVY),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F1F5F7')]),('LINEBELOW',(0,-1),(-1,-1),.5,colors.HexColor('#CCD8DF'))]))
    story.extend([t,Spacer(1,12)])
    md.append('| '+' | '.join(map(plain,headers))+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+'\n'.join('| '+' | '.join(plain(str(v)) for v in row)+' |' for row in rows)+'\n')
def fig(name,cap,maxh=330):
    path=ROOT/'figures'/name
    with PILImage.open(path) as im:w,h=im.size
    scale=min(505/w,maxh/h)
    story.append(Image(str(path),width=w*scale,height=h*scale,hAlign='LEFT'))
    P(cap,'SmallX');md.append(f'![{cap}](../figures/{name})\n')
def code(s):P(html.escape(s).replace('\n','<br/>'),'CodeX')
def workflow():
    d=Drawing(505,290)
    steps=[('1  Public cell and data','Chen2020 + three measured LG M50 cells'),('2  Build and initialize','Single Particle + electrical and thermal network'),('3  Closed-loop comparison','Built-in CC-CV + 2, 3 and 4-stage requests'),('4  Fit and optimize','Training / holdout split + constrained search'),('5  Challenge the candidates','Full-plant replay, temperature, mesh and aging'),('6  Verify and deliver','Saved model, traces, figures and evidence report')]
    for i,(a,b) in enumerate(steps):
        y=250-i*46;d.add(Rect(0,y,505,39,fillColor=LIGHT,strokeColor=colors.HexColor('#C7DEDF'),radius=4));d.add(String(12,y+24,a,fontName='Helvetica-Bold',fontSize=10,fillColor=NAVY));d.add(String(12,y+10,b,fontName='Helvetica',fontSize=8,fillColor=GRAY))
        if i<5:d.add(Line(252,y,252,y-6,strokeColor=TEAL));d.add(Polygon([249,y-3,255,y-3,252,y-7],fillColor=TEAL,strokeColor=TEAL))
    story.extend([d,Spacer(1,12)])

P('ENGINEERING STUDY  /  MATHWORKS CHALLENGE 256','SubX')
P('Battery fast charging<br/>optimization','TitleX')
P('MATLAB + Simulink + Simscape Battery<br/>Documented public LG M50 cell | Reproducible simulation and validation','BodyX')
P('Final technical report | 12 September 2026 | MATLAB R2026a','SmallX')
story.append(Spacer(1,15))
table(['Baseline: 20-80%','Best evaluated staged profile','Time reduction'],[[f(baseline['duration_s']/60)+' min',f(opt['duration_s']/60)+' min',f(saving,1)+'%']],[168,169,168])
P(f'The recommended simulation candidate requests {best["currents_A"][0]:g} A to {best["switch_soc"][0]*100:g}% SOC, {best["currents_A"][1]:g} A to {best["switch_soc"][1]*100:g}%, then {best["currents_A"][2]:g} A to 80%. Feedback continuously reduces these requests when a constraint becomes active. The actual applied current is recorded in the delivered traces.')
P(f'In the nominal 25 C case, this candidate reaches {opt["final_soc"]*100:.3f}% SOC with a maximum terminal voltage of {opt["max_voltage_V"]:.4f} V and a maximum core temperature of {opt["max_core_C"]:.2f} C. This is the best feasible candidate found by the stated search, not a proof of global optimality.')
H('What this deliverable establishes')
P('The project implements and executes the required baseline, staged charging comparison and each optional advanced workstream. It includes an actual .slx model, public experimental records, fitting, holdout validation, direct collocation, learning-policy exploration, two thermal states and a six-cycle degradation study.')
H('Limits of the conclusion')
P('The result is a model-based charging recommendation. The measured dataset does not validate the proposed high-current charging rates, and the aging parameters are illustrative. Training and holdout errors, including cases where fitting worsens the prediction, are reported without being treated as safety certification or measured lifetime improvement.')
P('Read the requirement map on page 2, model assumptions on pages 4-6, and the validation and aging results before reusing the charging requests. The report and all reported metrics were generated from the delivered run artifacts.','SmallX')

page('Requirement coverage','Core and optional advanced work from the linked MathWorks project. Implemented describes completed technical work, not hardware qualification.')
coverage=[
('SPM understanding','Implemented','Solid diffusion, electrolyte transport, electrode potential and concentration risk indicators; model equations and parameter mapping.'),
('Simscape setup','Executed','BatteryFastCharging.slx uses the actual Battery Single Particle block, current source, physical network and probes.'),
('Built-in CC-CV baseline','Executed','Actual Battery CC-CV PI block; 20-80% comparison plus a 98% SOC run to demonstrate voltage taper.'),
('2-4 stage profiles','Executed','SOC-switched 2, 3 and 4-stage profiles with measured time, voltage, temperature and final SOC.'),
('Comparison and recommendation','Completed','Numerical and visual comparison; best evaluated feasible profile and limitations.'),
('Optimal control','Executed','25-node direct collocation, independent RK4 replay and guarded Simscape replay; separate full-plant pattern search.'),
('Two-state thermal model','Executed','Core thermal mass, surface mass and two thermal resistances; core-temperature feedback.'),
('Electrochemical / thermal coupling','Executed','Temperature-dependent reaction rates; explicit diffusion-activation sensitivity case.'),
('Parameter fitting / validation','Executed; bounded evidence','Public capacity and OCP; effective diffusion and thermal fit; held-out discharge and charge comparison. No new EIS identification claimed.'),
('Degradation / SOH','Executed; illustrative','Six continuous cycles with built-in SEI and reversible / irreversible plating states; lithium-inventory SOH proxy.'),
('Adaptive / learning control','Executed; exploratory','Built-in PI and feedback limits; fixed-seed tabular Q-learning with full-plant schedule replay.'),
('Registration / submission','Participant action','The package is prepared for review. No external form or forum message has been submitted.')]
table(['Workstream','Status','Evidence / scope'],coverage,[119,104,282])
P('Data-dependent limits are part of the completed analysis. In particular, the absence of measured fast-charge cycle-life and raw EIS data prevents a quantitative lifetime claim and independent impedance-spectrum fitting. Published OCP curves and effective dynamic fitting are used with explicit provenance.','SmallX')

page('Process workflow','A MATLAB-first path from a public cell definition to a reviewable charging recommendation.')
workflow()
H('Physical signal path')
code('Stage or scheduled current request\n  -> sampled thermal / anode-potential supervisor\n  -> built-in Battery CC-CV PI regulator\n  -> 0...7.5 A saturation -> 2 s current-source dynamics\n  -> Simscape Single Particle cell\n  -> voltage, current, SOC, temperature and concentration probes')
H('Thermal path and replay mode')
P('The cell core exchanges heat with a surface thermal mass through 1.5 K/W. The surface exchanges heat with the ambient source through 6 K/W in the nominal charging fixture. Experimental and cyclic current replays use a separate input switch. Their broad diagnostic stopping envelope does not replace the charging-policy limits.')
H('Separation of numerical engines')
P('Simscape is the primary plant. A five-state MATLAB surrogate supports direct collocation and Q-learning. An independently executed PyBaMM SPMe benchmark provides a cross-check. Surrogate times are always identified separately from full-plant replay times.')

page('Public cell and parameter mapping','LG M50, Chen et al. (2020), DOI 10.1149/1945-7111/ab9050. Public data: Zenodo 4032561.')
params=[('Nominal capacity / comparison SOC','5 Ah / coulomb counting','Published nominal capacity; explicit common SOC definition'),('Negative / positive thickness','85.2 / 75.6 micrometers','Published'),('Separator thickness','12 micrometers','Published'),('Effective electrode area','0.1027 m^2','0.065 m x 1.58 m'),('Negative / positive particle radius','5.86 / 5.22 micrometers','Published'),('Active volume fractions','0.750 / 0.665','Published'),('Maximum solid concentrations','33133 / 63104 mol/m^3','Negative / positive'),('Negative stoichiometry range','0.02635 to 0.91062','Chen2020 endpoint calculation'),('Positive stoichiometry range','0.26385 to 0.85397','Decreases during charge'),('Reference solid diffusivities','3.30e-14 / 4.00e-15 m^2/s','Published nominal values'),('Initial electrolyte concentration','1000 mol/m^3','Explicit high-priority initial target'),('Electrolyte conductivity / diffusivity','0.9487 S/m / 1.7694e-10 m^2/s','Chen functions evaluated at 1000 mol/m^3'),('Porosity, negative / separator / positive','0.250 / 0.470 / 0.335','Bruggeman exponent 1.5'),('Cation transference number','0.2594','Published'),('Reaction activation energy','35000 / 17800 J/mol','Negative / positive'),('Core thermal capacity','Computed from layer-weighted rho*Cp','Chen2020 volume 2.42e-5 m^3'),('Surface capacity / thermal resistances','8 J/K; 1.5 and 6 K/W','Added casing / fixture assumptions')]
table(['Parameter','Value','Basis'],params,[162,160,183])
P('The parameter file contains units and the analytic half-cell OCP functions tabulated at 600 stoichiometry points. The exchange-current prefactors are divided by Faraday\'s constant to match the installed Simscape reaction-rate convention. Activation energies intended to be zero use 1e-6 J/mol because the block requires a positive value.','SmallX')
caps=C('measured_capacity.csv')
table(['Measured C/10 discharge','Capacity (Ah)','Duration (min)'],[[r['cell'],f(r['capacity_Ah'],5),f(n(r['duration_s'])/60)] for r in caps],[233,136,136])
P('Capacity values are the maximum recorded cumulative discharge Ah in the three C/10 segments. This near-5 Ah result supports the common nominal capacity used in the charging comparison.','SmallX')

page('Electrochemistry and thermal model','The implemented SPM retains particle diffusion and electrolyte dynamics; it does not resolve every particle in a porous electrode.')
H('Solid-phase diffusion and surface loading')
code('dc_s/dt = (1/r^2) * d/dr [r^2 * D_s(T) * dc_s/dr]\nAt r = 0: dc_s/dr = 0\nAt r = R: the flux is set by electrode current / active area\nSurface stoichiometry theta_s = c_s,surface / c_s,max')
P('Each electrode is represented by a spherical particle. A surface-to-average concentration gradient grows when charge transport is faster than solid diffusion. The model solves 12 radial shells per electrode in nominal runs and 20 in the refinement check. Anode surface stoichiometry is logged as a concentration-based diagnostic.')
H('Electrolyte and terminal voltage')
code('epsilon_e * dc_e/dt = d/dx [D_e,eff * dc_e/dx] + reaction source\nD_e,eff = D_e * epsilon_e^b\nV = U_p(surface) - U_n(surface) + kinetic + transport + ohmic terms')
P('The electrolyte is divided into 12 layers in each region. Concentration and flux are continuous at interfaces, with zero external salt flux. Exchange current depends on electrolyte concentration and electrode surface filling; inverse Butler-Volmer kinetics contributes to voltage. The minimum concentration across all three regions is monitored.')
H('Core and surface energy balances')
code('C_core * dT_core/dt = Q_cell - (T_core - T_surface)/R_cs\nC_surface * dT_surface/dt = (T_core-T_surface)/R_cs\n                          - (T_surface-T_ambient)/R_sa\nk(T) = k_ref * exp[(Ea/R) * (1/T_ref - 1/T)]')
P('The built-in cell thermal mass provides the core energy state. The external Thermal Mass supplies the second state. Cell losses heat the core and temperature feeds back into reaction kinetics. Nominal Chen solid diffusion is effectively temperature independent; the separate 20 kJ/mol diffusion-activation case is a sensitivity assumption.')
H('Plating-risk interpretation')
P('The block exposes an anode-electrolyte potential proxy formed from surface OCP plus kinetic overpotential. The supervisor uses a 20 mV floor and also monitors electrolyte concentration. This is an SPM approximation, not a spatially resolved solid-minus-liquid potential at the anode/separator interface. Concentration and potential margins do not demonstrate the absence of microscopic plating.')

page('Controller and charging profiles','Common initial SOC 20%, target SOC 80%, ambient and initial temperature 25 C. Positive project current means charging.')
table(['Request','Currents (A)','SOC transition(s)'],[['Baseline CC-CV','2.5','Voltage regulation when 4.195 V is approached'],['Two stages','5, 2.5','55%'],['Three stages','7.5, 5, 2.5','40%, 65%'],['Four stages','7.5, 5, 3.5, 2.5','35%, 50%, 68%'],['Adaptive maximum request','7.5','Feedback continuously limits current'],['Best evaluated three-stage request',', '.join(f'{v:g}' for v in best['currents_A'][:3]),', '.join(f'{100*v:g}%' for v in best['switch_soc'][:2])]],[153,142,210])
H('Control law and implementation')
code('I_request = min(I_stage, I_thermal, I_anode)\nI_thermal = max(0, 2*(T_limit - 1 K - T_core))\nI_anode = max(0, 100*(anode_potential - 0.020 V))\nCC-CV: V_set = 4.195 V; Kp = 20; Ki = 2\nAnti-windup / tracking gains = 1; sample period = 0.5 s\nI_applied(s) / I_command(s) = 1 / (2*s + 1)')
P('The actual Battery CC-CV block receives the permitted charging-current request and measured voltage. A latched supervisory fault stops a run for voltage above 4.215 V, core temperature above 45.1 C, potential below -5 mV or electrolyte concentration below 100 mol/m^3. Independent result checks apply the tighter intended study envelope.')
P('A successful charging result must reach the target without a fault. Numerical acceptance tolerances are +2 mV on the 4.2 V ceiling, +0.05 C on 45 C and -3 mV on the 20 mV potential floor. Reported maxima and minima remain visible, so an accepted flag never substitutes for the numerical margins.')
P('The two-second actuator models finite current-source response and prevents controller-induced numerical chattering. SOC integrates the actual cell current, including that response. The internal electrode-based normalized SOC is retained separately in every trace.')
H('Why a second baseline run is included')
P('A 20-80% comparison may finish before the CV loop dominates. The additional run to 98% SOC explicitly exercises the taper region and prevents a constant-current trajectory from being presented as evidence of tested CV behavior.')

page('Simscape charging comparison','Measured outputs from the actual delivered model. All rows use the same nominal cell, thermal fixture, SOC definition and feedback limits.')
rows=[]
for m in comparison+[opt]:
    rows.append([m['name'].replace('_',' '),f(n(m['duration_s'])/60),f(m['max_voltage_V'],4),f(m['max_core_C']),f(100*n(m['final_soc']),3)])
table(['Profile','Minutes','Max V','Max core C','Final SOC %'],rows,[168,72,86,89,90])
fig('simscape_comparison.png','Figure 1. Actual current, voltage, SOC and core temperature for the baseline, staged and adaptive comparisons.',320)
P(f'The best evaluated staged candidate cuts charging time by {saving:.1f}% relative to the 0.5C baseline. Its requested plateaus can be reduced substantially by feedback. Compare the applied-current trace when attributing the gain to a stage transition or an active constraint.','SmallX')
P('The adaptive maximum request and optimized staged request have the same nominal completion time: feedback limits dominate both trajectories. The staged search does not demonstrate an improvement over that adaptive baseline.','SmallX')

page('Electrochemical and thermal margins','Whole trajectories matter: endpoint SOC alone cannot establish voltage, temperature or transport compliance.')
fig('electrochemical_margins.png','Figure 2. Potential proxy, minimum electrolyte concentration, anode surface filling and core-to-surface temperature gradient.',310)
table(['Optimized candidate','Observed value','Study criterion'],[['Anode potential proxy, minimum',f(1000*opt['min_anode_potential_V'])+' mV','20 mV nominal floor'],['Electrolyte concentration, minimum',f(opt['min_electrolyte_mol_m3'])+' mol/m^3','100 mol/m^3 floor'],['Surface temperature, maximum',f(opt['max_surface_C'])+' C','Core limit is 45 C']],[190,160,155])
fig('cccv_taper.png','Figure 3. The separate 98% SOC baseline confirms transition toward voltage-controlled current taper.',177)
hi=J('simscape_high_soc_CCCV_metrics.json')
P(f'High-SOC baseline: {hi["duration_s"]/60:.2f} min to {100*hi["final_soc"]:.3f}% SOC; maximum voltage {hi["max_voltage_V"]:.4f} V. The 98% result is a separate operating window and is not mixed into the 20-80% ranking.','SmallX')

page('Constrained optimization and learning','A computational shortcut is useful only when its proposed schedule survives the full plant.')
H('Full-plant staged optimization')
P(f'Pattern search evaluates three current levels and two SOC thresholds directly against Simscape. Currents are non-increasing; thresholds have a minimum 5% SOC separation. The search evaluated {best["evaluations"]} candidates and returned exit flag {best["exitflag"]}. An infeasible or failed run receives a penalty; the saved candidate is the best feasible evaluated profile.')
H('Direct-collocation formulation')
code('minimize t_final\nstate x = [SOC, negative diffusion lag, positive diffusion lag,\n           core temperature, surface temperature]\n0 <= I <= 7.5 A; V <= 4.195 V; T_core <= 45 C\nanode potential >= 20 mV; theta_n <= 0.98; theta_p >= 0.02\nx[k+1]-x[k] = dt/2 * (f(x[k],I[k]) + f(x[k+1],I[k+1]))')
P(f'The 25-node trapezoidal transcription uses fmincon SQP with a free final time and fixed initial/target SOC. It converged in {coll["iterations"]} iterations (exit {coll["exitflag"]}); maximum scaled defect {coll["max_defect"]:.2e}. A separate 2 s RK4 integration checks the surrogate schedule before Simscape replay. The surrogate omits resolved electrolyte dynamics and therefore can be optimistic.')
table(['Method','Surrogate minutes','Guarded Simscape minutes'],[['Direct collocation',f(coll['time_s']/60),f(cr['duration_s']/60)],['Q-learning policy',f(rl['nominal_replay_time_s']/60),f(rr['duration_s']/60)],['Full-plant staged search','Not used',f(opt['duration_s']/60)]],[201,145,159])
H('Learning experiment')
P(f'Tabular Q-learning uses 16 SOC bins, 8 core-temperature bins and 8 anode-diffusion-lag bins. Five current actions are filtered against the surrogate constraints. The fixed seed is 42; {rl["episodes"]} episodes contain {rl["steps"]} steps, with {100*rl["training_completion_fraction"]:.0f}% training completion. Reward favors SOC increase and penalizes elapsed time and elevated temperature, with a terminal bonus. The delivered learned schedule is exploratory; it is replayed with full-plant feedback, not claimed to be an online optimal controller.')
P('The built-in PI controller fulfills the feedback-control workstream. An MPC implementation is not necessary for the project\'s PI-or-MPC choice. No Reinforcement Learning Toolbox is needed for this tabular experiment.','SmallX')

page('Experimental fitting and discharge validation','Real authors\' LG M50 measurements. Cell 02 is used for fitting; cells 03 and 04 are held out.')
P(f'The fit adjusts effective negative diffusion ({fit["Dn"]:.3e} m^2/s), positive diffusion ({fit["Dp"]:.3e} m^2/s) and surface-to-ambient resistance ({fit["RsurfaceAmbient"]:.3f} K/W). Radii, OCP, capacity, core-to-surface resistance and casing capacity remain fixed. The least-squares objective normalizes voltage by 30 mV and surface temperature by 1 C, with equal sample-count weighting per trace.')
table(['Cell / rate / role','V RMSE before (mV)','V RMSE fitted (mV)','T RMSE (C)','Coverage'],[[f"{r['cell']} / {n(r['current_A'])/5:.1f}C / {r['role']}",f(r['voltage_RMSE_before_mV']),f(r['voltage_RMSE_after_mV']),f(r['temperature_RMSE_C']),f(100*n(r['coverage_fraction']),1)+'%'] for r in validation],[169,89,89,78,80])
fig('simscape_validation.png','Figure 4. Measured and fitted voltage on training and held-out discharges.',310)
P('Coverage refers to the selected comparison window: the first 90% of each discharge duration, sampled at every second record. The terminal knee is excluded explicitly. Measured discharge replays use a broad diagnostic stopping envelope so a proposed charging temperature limit cannot censor the validation data.','SmallX')
P('Fitting is not automatically an improvement on held-out data. Differences in high-rate voltage and temperature remain model discrepancy. These effective parameters are stored separately from the published nominal parameter set and are not silently substituted into the headline comparison.','SmallX')

page('Held-out charging and parameter sensitivity','The dataset contains 0.3C charging. It does not provide a measured 1.5C fast-charge validation of the proposed policy.')
P('A separate cell 04, 0.3C charge segment is held out from parameter fitting. Initial SOC is inferred from the preceding rest-end voltage by inverting the fixed published OCP relation. The comparison uses the first 90% of the constant-current phase; no charge samples are used to fit the parameters or the initial state.')
table(['Measured-charge validation','Result'],[['Initial inferred SOC',f(100*charge['initial_soc'],2)+'%'],['Voltage RMSE',f(charge['voltage_RMSE_mV'])+' mV'],['Surface-temperature RMSE',f(charge['temperature_RMSE_C'])+' C'],['Selected-window coverage',f(100*charge['coverage_fraction'],2)+'%']],[290,215])
fig('heldout_charge_validation.png','Figure 5. Held-out charge voltage and surface temperature.',235)
rows=[]
for file,label in [('simscape_optimized_metrics.json','Published nominal cell / nominal fixture'),('simscape_fitted_diffusion_sensitivity_metrics.json','Fitted diffusivities / nominal fixture'),('simscape_fitted_fixture_sensitivity_metrics.json','Fitted diffusivities / fitted fixture')]:
    q=J(file);rows.append([label,f(q['duration_s']/60),f(q['max_voltage_V'],4),f(q['max_core_C']),str(q['feasible'])])
table(['Charging sensitivity','Minutes','Max V','Max core C','Feasible'],rows,[217,67,77,81,63])
P('The capacity records are obtained from C/10 discharge. OCP comes from published cell parameterization, not an invented pulse test. No raw EIS spectra exist in the selected files, so neither an independently measured impedance spectrum nor a uniquely identified particle diffusivity is claimed.','SmallX')

page('Operating-condition robustness','Eighteen Simscape runs: two strategies, three initial SOC values and three initial/ambient temperatures.')
fig('robustness.png','Figure 6. Baseline and optimized requests over 15, 25 and 35 C, with initial SOC 10%, 20% and 40%.',220)
rows=[]
for temp in [15,25,35]:
    for soc in [.1,.2,.4]:
        a=next(x for x in robust if n(x['temperature_C'])==temp and n(x['initial_soc'])==soc and n(x['profile'])==1)
        b=next(x for x in robust if n(x['temperature_C'])==temp and n(x['initial_soc'])==soc and n(x['profile'])==2)
        bt=f(n(b['duration_s'])/60) if str(b['feasible']).lower() in ('true','1') else 'Fault @ '+f(n(b['duration_s'])/60)
        rows.append([str(temp),str(round(100*soc)),f(n(a['duration_s'])/60),bt,f(b['max_core_C']),str(b['feasible'])])
table(['Initial / ambient C','Initial SOC %','Baseline min','Optimized min','Opt. max core C','Opt. feasible'],rows,[87,83,86,87,91,71])
P('Initial core and surface temperatures are explicitly enforced and asserted against the requested values. Electrolyte concentration is initialized at 1000 mol/m^3 with a high-priority target. A final audit corrected initial-state settings that otherwise retained block defaults; the reported results come from the corrected runs.')
P('These deterministic scenarios check sensitivity to a limited set of operating conditions. They do not establish statistical reliability across manufacturing variation, cold-weather operation below 15 C, sensor errors, cooling faults or aged cells.')
bad=sum(str(r['feasible']).lower() in ('0','false') for r in robust if n(r['profile'])==2)
P(f'The staged request fails {bad} of its nine initial-condition tests by triggering the electrolyte guard. These short, incomplete runs are failures, not fast-charge successes. select_tested_profile.m selects the baseline for failed conditions and the staged request for successful tested conditions. The selector is checked against the existing full-plant results; it does not establish safety between grid points.','SmallX')

page('Numerical verification and cross-check','Execution success, constraint feasibility, numerical convergence and experimental accuracy are separate questions.')
table(['Refinement check','Measured difference','Interpretation'],[['Spatial / temporal refinement',f(conv['time_difference_percent'],4)+'% charge time','12 to 20 shells and layers; max step 1 to 0.25 s'],['Maximum voltage',f(conv['voltage_difference_mV'],4)+' mV','Refined minus nominal'],['Maximum core temperature',f(conv['temperature_difference_C'],4)+' C','Refined minus nominal']],[170,145,190])
P('Nominal integration uses ode23t with relative tolerance 1e-5 and absolute tolerance 1e-7. The refined case tightens these to 1e-6 and 1e-8. The controller sample period remains 0.5 s. Coulomb consistency is checked from the exported current integral versus the independent SOC increment.')
H('Independent PyBaMM SPMe result')
ref=C('reference_comparison.csv')
table(['Profile','Time (min)','Maximum V','Maximum core C'],[[r.get('profile',r.get('name','profile')),f(n(r.get('duration_s',r.get('time_s',0)))/60),f(r.get('max_voltage_V',0),4),f(r.get('max_core_C',0))] for r in ref],[233,85,92,95])
P('The independent benchmark uses a separate implementation with concentration-dependent electrolyte transport and a proportional CV reference law. Simscape uses constant reference electrolyte transport with temperature scaling and the built-in PI CC-CV block. Their trajectories need not coincide. The benchmark is a model cross-check, not experimental validation.')
H('Recorded verification')
P(f'MATLAB release: {checks.get("matlab_release","R2026a")}. Parse issues: {len(checks.get("parse_issues",[]))}. Pipeline steps executed successfully: {sum(bool(x["executed"]) for x in pipeline)} / {len(pipeline)}. Detailed checks and step-level errors, if any, are preserved in verification/final_checks.json and verification/pipeline_status.json.')
P('Interpretation tests also verify the initial core/surface temperatures, electrolyte concentration, initial SEI thickness for aging, completion of all aging cycles, and full selected-window validation coverage. A failed assertion raises an error instead of writing a successful metric.','SmallX')

page('Six-cycle degradation and SOH analysis','Built-in R2026a SEI and plating states. This is an uncalibrated degradation experiment.')
fig('aging_comparison.png','Figure 7. Lithium-inventory SOH proxy over six continuous charge/discharge cycles.',285)
endrows=[r for r in aging if n(r['cycle'])==6]
table(['Strategy','Elapsed hours','SEI thickness (nm)','Irreversible Li (mol)','SOH proxy %'],[[r['strategy'].replace('_',' '),f(n(r['time_s'])/3600),f(1e9*n(r['sei_m'])),f'{n(r["irreversible_plating_mol"]):.3e}',f(100*n(r['lithium_inventory_SOH_proxy']),4)] for r in endrows],[137,89,97,101,81])
P('Each cycle replays the previously applied charge current, rests for 60 s, discharges at 2.5 A for equal coulomb throughput, then rests for 60 s. The six cycles are simulated in one continuous run per strategy, preserving the electrochemical, thermal and aging states. This cyclic replay characterizes a fixed waveform; it is not a re-optimized charger for every aged cycle.')
code('Delta n_SEI = A_active * (L_SEI - L_SEI_initial) * 2 / V_m\nSOH_inventory = 1 - F*(Delta n_SEI + n_Li,irreversible)/(3600*5 Ah)')
P('Illustrative inputs: initial SEI 5 nm, molar volume 9.585e-5 m^3/mol, interstitial diffusivity 1e-20 m^2/s, SEI conductivity 5e-6 S/m; plating exchange current 3e-4 A/m^2 and reversible fraction 0.5. Diffusion activation is effectively zero in this illustration; SEI conductivity and plating retain their explicitly documented built-in temperature dependence.')
P('A shorter charge can reduce time available for SEI growth in this chosen model, while a hotter or more aggressive policy can increase other aging mechanisms. The plotted ordering is specific to these assumptions. Zero modeled irreversible plating does not prove its absence in a real cell. The proxy is not an experimentally measured capacity-retention or cycle-life prediction.','SmallX')

page('Run, inspect and extend the project','The saved model and study scripts are the primary deliverable; the report is their evidence trail.')
H('Open the model')
code("cd('<your extracted BatteryFastCharging folder>')\nrun('start_project.m')")
P('The saved .slx contains the nominal parameter structure in its model workspace and a 2.5 A baseline configuration. start_project adds the MATLAB source folder and opens the model. Run it from the extracted project folder, not from the ZIP.')
H('Reproduce all studies')
code("addpath('matlab')\nstatus = run_project();")
P('Required products: MATLAB, Simulink, Simscape, Simscape Battery, Optimization Toolbox and Global Optimization Toolbox. The project was executed in R2026a. The built-in SEI/plating options require this release. The pipeline continues independent steps after an error and records the outcome; inspect the status JSON before treating a rerun as complete.')
table(['Location','Contents'],[['matlab/','Builder, supervisor, full-plant optimizer, fitting, collocation, Q-learning, replays, aging and checks.'],['data/raw/ and data/processed/','Unmodified public measurements; time in seconds, positive charging current in A, voltage in V, temperatures in C.'],['data/source_manifest.json','Dataset DOI, CC BY 4.0 license, URLs and SHA-256 / source MD5 checksums.'],['results/','Actual traces, per-run metrics, optimization histories, validation predictions and learning tables.'],['figures/ and report/','Study graphics, model image, this PDF and editable Markdown report.'],['verification/','Pipeline execution and assertion results; package integrity manifest.'],['python/','Optional independent SPMe benchmark with pinned dependencies.']],[158,347])
H('Changing the study')
P('Edit project_parameters.m and rerun the pipeline. Keep published cell properties, fitted experimental parameters and hypothetical sensitivity assumptions distinguishable. The comparison SOC is a common 5 Ah current integral; the model\'s internal electrode SOC has a different normalization and is logged separately.')
code("[p, choice] = select_tested_profile(0.2, 25);\n[metrics, trace] = run_case(p, 'recommended');")
P('The optional Python benchmark uses positive discharge current internally. Its exports convert to the project\'s positive-charge convention. The primary MATLAB pipeline does not depend on the Python installation.','SmallX')

page('Sources, provenance and remaining limits','Primary sources and explicit boundaries of the completed engineering study.')
sources=[('MathWorks project 256','https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/tree/main/projects/Battery%20Fast%20Charging%20Optimization'),('Battery Single Particle documentation','https://www.mathworks.com/help/simscape-battery/ref/batterysingleparticle.html'),('Battery CC-CV documentation','https://www.mathworks.com/help/simscape-battery/ref/batterycccv.html'),('Chen et al., cell parameterization paper (2020)','https://doi.org/10.1149/1945-7111/ab9050'),("Authors' LG M50 experimental measurements",'https://zenodo.org/records/4032561'),('PyBaMM source and parameter implementations','https://github.com/pybamm-team/PyBaMM'),('MathWorks fast-charge methodology','https://www.mathworks.com/company/technical-articles/generating-safe-fast-charge-profiles-for-ev-batteries.html'),('Public Chen parameter reference and license','https://github.com/rtimms/compare-pybamm-models')]
for i,(title,url) in enumerate(sources,1):P(f'{i}. <link href="{html.escape(url,quote=True)}" color="#007F83">{html.escape(title)}</link>','BodyX');md[-1]=f'{i}. [{title}]({url})\n'
H('Data and code attribution')
P('The raw LG M50 records are redistributed with attribution under the dataset\'s CC BY 4.0 license. The source manifest preserves author-hosted URLs and checksums. The published parameter reference license is included as data/REFERENCE_LICENSE.txt. MATLAB and MathWorks library implementation files are not redistributed; the delivered .slx refers to installed library blocks.')
H('What remains outside the evidence')
P('The selected measurements contain no raw EIS spectra or high-rate charging cycle-life series. OCP and geometry are adopted from the published public cell; diffusion and thermal estimates are effective fits to dynamic discharge. Anode potential is an SPM proxy. Aging inputs are illustrative. Real charger design would require cell-specific charge characterization, aging calibration, independent safety assessment and hardware validation before deployment.')
P('The initial-state audit and full-plant replay are reflected in the final numerical results. Failed development runs and temporary licensing/runner logs are excluded from the final scientific evidence. All completed steps remain reproducible from the packaged sources, data and settings.')
H('Submission')
P('The linked challenge provides registration and solution-submission forms. The participant must review the package and submit using their own identity. No registration, forum post or external submission has been made by this project run.')

def footer(canvas,doc):
    canvas.saveState();w,h=doc.pagesize
    canvas.setStrokeColor(TEAL);canvas.setLineWidth(1);canvas.line(45,h-29,w-45,h-29)
    canvas.setFont('Helvetica',7);canvas.setFillColor(GRAY);canvas.drawString(45,24,'BATTERY FAST CHARGING  |  LG M50  |  SIMULATION STUDY')
    canvas.drawRightString(w-45,24,str(doc.page));canvas.restoreState()

doc=SimpleDocTemplate(str(OUT/'Battery_Fast_Charging_Report.pdf'),pagesize=(595.28,841.89),leftMargin=45,rightMargin=45,topMargin=45,bottomMargin=43,title='Battery Fast Charging Optimization - LG M50',author='Project engineering study')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
(OUT/'Battery_Fast_Charging_Report.md').write_text('\n'.join(md),encoding='utf-8')
(OUT/'requirement_coverage.csv').write_text('workstream,status,evidence\n'+''.join(','.join('"'+x.replace('"','""')+'"' for x in row)+'\n' for row in coverage),encoding='utf-8')
print(OUT/'Battery_Fast_Charging_Report.pdf')
