"""Independent PyBaMM SPMe benchmark. This does not execute Simscape.

Positive project current means charging; PyBaMM current has opposite sign.
Run from project root: python python/reference_study.py
"""
import os
os.environ['PYBAMM_DISABLE_TELEMETRY']='true'
os.environ.setdefault('MPLCONFIGDIR', str(__import__('pathlib').Path(__file__).resolve().parents[1]/'verification/mplconfig'))
import json, pathlib, time, hashlib
import numpy as np
import pandas as pd
import pybamm
from scipy.optimize import minimize, least_squares
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=pathlib.Path(__file__).resolve().parents[1]
F=96485.33212
PARAM=pybamm.ParameterValues('Chen2020')
SOLVER=lambda: pybamm.IDAKLUSolver(rtol=1e-6,atol=1e-8)
plt.rcParams.update({'font.size':10,'axes.spines.top':False,'axes.spines.right':False,'figure.dpi':130})

def save_json(name,value):
    (ROOT/'results'/name).write_text(json.dumps(value,indent=2,default=lambda x:float(x) if np.isscalar(x) else x.tolist()))

def scalar_parameters():
    d={k:v for k,v in PARAM.items() if isinstance(v,(int,float,str))}
    x0,x100,y100,y0=pybamm.lithium_ion.get_min_max_stoichiometries(PARAM)
    d.update({'negative_sto_at_0_SOC':float(x0),'negative_sto_at_100_SOC':float(x100),'positive_sto_at_0_SOC':float(y0),'positive_sto_at_100_SOC':float(y100)})
    (ROOT/'data/chen2020_parameters.json').write_text(json.dumps(d,indent=2))
    z=np.linspace(.001,.999,600)
    from pybamm.input.parameters.lithium_ion.Chen2020 import graphite_LGM50_ocp_Chen2020,nmc_LGM50_ocp_Chen2020
    pd.DataFrame({'stoichiometry':z,'anode_OCP_V':graphite_LGM50_ocp_Chen2020(z),'cathode_OCP_V':nmc_LGM50_ocp_Chen2020(z)}).to_csv(ROOT/'data/ocp_tables.csv',index=False)
    return d

def preprocess():
    records=[]
    for file in sorted((ROOT/'data/raw').glob('LGM50*.csv')):
        d=pd.read_csv(file,skiprows=13)
        for (cyc,step,mode),g in d.groupby(['Cycle C','Step','Md'],sort=False):
            if len(g)<4: continue
            t=g['Test Time [s]'].to_numpy(); t=t-t[0]
            rec={'cell':file.stem,'cycle':int(cyc),'step':int(step),'mode':mode,'duration_s':float(t[-1]),'current_A':float(g['Current [A]'].median()),'V_start':float(g['Voltage [V]'].iloc[0]),'V_end':float(g['Voltage [V]'].iloc[-1]),'capacity_Ah':float(g['Capacity [Ah]'].max()),'points':len(g)}
            records.append(rec)
            out=pd.DataFrame({'time_s':t,'current_charge_A':np.where(g.Md=='D',-g['Current [A]'],g['Current [A]']),'voltage_V':g['Voltage [V]'],'surface_C':g['Temperature Cell [degC]'],'ambient_C':g['Temperature Chamber [degC]']})
            out=out.drop_duplicates('time_s')
            out.to_csv(ROOT/f'data/processed/{file.stem}_cycle{cyc}_step{step}_{mode}.csv',index=False)
    pd.DataFrame(records).to_csv(ROOT/'data/experiment_inventory.csv',index=False)
    return pd.DataFrame(records)

class ChargingModel:
    """SPMe with algebraic CC/CV current law and two thermal states.

    CV is a proportional reference controller (1000 A/V), not the MathWorks PI.
    Electrochemical/thermal guards optionally derate current before a hard event.
    """
    def __init__(self,soc0=.2,target=.8,temp=25,guard=True,mesh=16,fit=None):
        self.soc0=soc0; self.target=target
        def control(v):
            soc=soc0-v['Discharge capacity [A.h]']/5
            s1=pybamm.InputParameter('S1'); s2=pybamm.InputParameter('S2'); s3=pybamm.InputParameter('S3')
            # Smooth switching for reliable algebraic solution; width = 0.2% SOC.
            h=lambda x:(1+pybamm.tanh(x/.002))/2
            i1,i2,i3,i4=[pybamm.InputParameter(f'I{i}') for i in range(1,5)]
            req=i1+(i2-i1)*h(soc-s1)+(i3-i2)*h(soc-s2)+(i4-i3)*h(soc-s3)
            vmax=pybamm.maximum(0,1000*(4.195-v['Voltage [V]']))
            cap=pybamm.minimum(req,vmax)
            if guard:
                tc=v['Volume-averaged cell temperature [K]']
                eta=v['X-averaged negative electrode surface potential difference [V]']
                cap=pybamm.minimum(cap,pybamm.maximum(0,2*(317.15-tc)))
                cap=pybamm.minimum(cap,pybamm.maximum(0,100*(eta-.020)))
            return v['Current [A]']+cap
        self.model=pybamm.lithium_ion.SPMe({'thermal':'lumped','surface temperature':'lumped','operating mode':control,'contact resistance':'true'})
        soc=soc0-self.model.variables['Discharge capacity [A.h]']/5
        self.model.events += [pybamm.Event('Target SOC', target-soc),pybamm.Event('Core temperature ceiling',318.15-self.model.variables['Volume-averaged cell temperature [K]'])]
        p=PARAM.copy()
        # Two-state thermal parameters are declared study assumptions, not measured Chen data.
        p.update({'Total heat transfer coefficient [W.m-2.K-1]':1/(1.5*.00531),'Environment thermal resistance [K.W-1]':6.0,'Casing heat capacity [J.K-1]':8.0,'Ambient temperature [K]':temp+273.15,'Initial temperature [K]':temp+273.15},check_already_exists=False)
        if fit: p.update(fit)
        pts={pybamm.standard_spatial_vars.x_n:mesh,pybamm.standard_spatial_vars.x_s:mesh,pybamm.standard_spatial_vars.x_p:mesh,pybamm.standard_spatial_vars.r_n:mesh,pybamm.standard_spatial_vars.r_p:mesh}
        self.sim=pybamm.Simulation(self.model,parameter_values=p,solver=SOLVER(),var_pts=pts)
    def solve(self,currents=(2.5,2.5,2.5,2.5),switches=(.4,.6,.7),duration=10000):
        inp={f'I{i+1}':float(a) for i,a in enumerate(currents)} | {f'S{i+1}':float(a) for i,a in enumerate(switches)}
        sol=self.sim.solve([0,duration],inputs=inp,initial_soc=self.soc0,t_interp=np.arange(0,duration+1,2.0))
        t=sol.t
        def val(name): return np.asarray(sol[name](t)).reshape(-1)
        out=pd.DataFrame({'time_s':t,'current_charge_A':-val('Current [A]'),'voltage_V':val('Voltage [V]'),'soc':self.soc0-val('Discharge capacity [A.h]')/5,'core_C':val('Volume-averaged cell temperature [K]')-273.15,'surface_C':val('Surface temperature [K]')-273.15,'anode_potential_V':val('X-averaged negative electrode surface potential difference [V]'),'anode_surface_sto':val('X-averaged negative particle surface stoichiometry'),'cathode_surface_sto':val('X-averaged positive particle surface stoichiometry')})
        ce=np.asarray(sol['Electrolyte concentration [mol.m-3]'](t))
        out['electrolyte_min_mol_m3']=np.min(ce,axis=0)
        reached=bool(out.soc.iloc[-1]>=self.target-1e-5)
        metrics={'duration_s':float(t[-1]),'final_soc':float(out.soc.iloc[-1]),'max_voltage_V':float(out.voltage_V.max()),'max_core_C':float(out.core_C.max()),'max_surface_C':float(out.surface_C.max()),'min_anode_potential_V':float(out.anode_potential_V.min()),'min_electrolyte_mol_m3':float(out.electrolyte_min_mol_m3.min()),'max_current_A':float(out.current_charge_A.max()),'energy_Wh':float(np.trapezoid(out.current_charge_A*out.voltage_V,t)/3600),'target_reached':reached,'termination':str(sol.termination)}
        metrics['feasible']=bool(reached and metrics['max_voltage_V']<=4.2+1e-5 and metrics['max_core_C']<=45+1e-4 and metrics['min_anode_potential_V']>=.0199 and metrics['min_electrolyte_mol_m3']>=100)
        return out,metrics

if __name__=='__main__':
    scalar_parameters(); inv=preprocess(); print(inv.to_string(index=False),flush=True)
    model=ChargingModel()
    d,m=model.solve(); d.to_csv(ROOT/'results/reference_baseline.csv',index=False); save_json('reference_baseline_metrics.json',m)
    print(m,flush=True)
