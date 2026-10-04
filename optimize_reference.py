"""Comparison, constrained profile search, robustness and numerical convergence."""
from reference_study import *

def execute():
    model=ChargingModel()
    strategies={'CCCV_0p5C':([2.5]*4,[.4,.6,.7]),'two_stage':([5,2.5,2.5,2.5],[.55,.65,.72]),'three_stage':([7.5,5,2.5,2.5],[.40,.65,.73]),'four_stage':([7.5,5,3.5,2.5],[.35,.50,.68]),'adaptive_max_request':([7.5]*4,[.4,.6,.7])}
    metrics=[]; traces={}
    def run(name,c,s,mod=model):
        d,m=mod.solve(c,s); d.to_csv(ROOT/f'results/reference_{name}.csv',index=False)
        m.update(name=name,requested_currents_A=list(c),switch_soc=list(s));metrics.append(m);traces[name]=d
        print(name,m,flush=True);return m
    for name,(c,s) in strategies.items(): run(name,c,s)
    history=[]
    def objective(x):
        try:
            _,m=model.solve([*x[:3],x[2]],[x[3],x[4],.79])
            score=m['duration_s'] if m['feasible'] else 1e5+1e4*(.8-m['final_soc'])
        except Exception as e: score=1e6;m={'error':str(e)}
        history.append({'x':x.tolist(),'objective':score,**m});return score
    opt=minimize(objective,[7.5,5,3.5,.45,.65],method='SLSQP',bounds=[(1.0,7.5)]*3+[(.25,.60),(.45,.77)],constraints=[{'type':'ineq','fun':lambda x:np.array([x[0]-x[1],x[1]-x[2],x[4]-x[3]-.05])}],options={'maxiter':25,'ftol':.2,'eps':.01})
    x=opt.x
    run('optimized_three_stage',[*x[:3],x[2]],[x[3],x[4],.79])
    save_json('profile_optimization.json',{'method':'SLSQP, simulation-based single shooting; local search, not global proof','success':bool(opt.success),'message':str(opt.message),'x':x,'history':history})
    pd.DataFrame(metrics).to_csv(ROOT/'results/reference_comparison.csv',index=False)
    fig,axs=plt.subplots(2,2,figsize=(11,7),constrained_layout=True)
    for name,d in traces.items():
        for ax,key,label in zip(axs.ravel(),['current_charge_A','voltage_V','soc','core_C'],['Charging current (A)','Voltage (V)','SOC','Core temperature (C)']):
            ax.plot(d.time_s/60,d[key],label=name);ax.set(xlabel='Time (min)',ylabel=label)
    axs[0,1].axhline(4.2,color='k',linestyle=':',linewidth=1)
    axs[1,1].axhline(45,color='k',linestyle=':',linewidth=1)
    axs[0,0].legend(fontsize=7)
    fig.savefig(ROOT/'figures/charging_comparison.png');plt.close(fig)
    robust=[]
    for temp in [15,25,35]:
        for soc in [.1,.2,.4]:
            mod=ChargingModel(temp=temp,soc0=soc)
            for name,c,s in [('baseline',[2.5]*4,[.4,.6,.7]),('optimized',[*x[:3],x[2]],[x[3],x[4],.79])]:
                try: _,m=mod.solve(c,s)
                except Exception as e:m={'feasible':False,'error':str(e)}
                robust.append({'temperature_C':temp,'initial_soc':soc,'profile':name,**m})
            print('Robustness',temp,soc,flush=True)
    # Diffusion uncertainty is separate from temperature dependence in Chen2020.
    for scale in [.7,1.3]:
        mod=ChargingModel(fit={'Negative particle diffusivity [m2.s-1]':3.3e-14*scale,'Positive particle diffusivity [m2.s-1]':4e-15*scale})
        _,m=mod.solve([*x[:3],x[2]],[x[3],x[4],.79]);robust.append({'temperature_C':25,'initial_soc':.2,'profile':f'optimized_diffusion_{scale}',**m})
    pd.DataFrame(robust).to_csv(ROOT/'results/robustness.csv',index=False)
    fine=ChargingModel(mesh=28);_,fm=fine.solve([*x[:3],x[2]],[x[3],x[4],.79])
    save_json('mesh_convergence.json',{'coarse_shells_and_x_points':16,'fine_shells_and_x_points':28,'coarse':metrics[-1],'fine':fm,'time_difference_percent':100*(fm['duration_s']-metrics[-1]['duration_s'])/metrics[-1]['duration_s']})
    # Explicitly demonstrate the CV region in a separate high-SOC test.
    full=ChargingModel(target=.98);d,m=full.solve(duration=25000)
    d.to_csv(ROOT/'results/reference_high_soc_CCCV.csv',index=False);save_json('high_soc_CCCV_metrics.json',m)
    return x

if __name__=='__main__':execute()
