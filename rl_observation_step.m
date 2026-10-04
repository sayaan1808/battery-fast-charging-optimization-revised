function [observation,reward,done]=rl_observation_step(z,T,ce,I,complete,fault,p)
%#codegen
% Tabular observations: 16 SOC bins x 8 temperature bins x 8 electrolyte bins.
persistent previousSOC previousTerminal initialized
if isempty(initialized),previousSOC=z;previousTerminal=false;initialized=true;end
zb=min(16,max(1,1+floor(z/.0625)));
tb=min(8,max(1,1+floor((T-273.15-10)/5)));
cb=min(8,max(1,1+floor(ce/150)));
observation=double(zb+16*(tb-1)+128*(cb-1));
reward=100*(z-previousSOC)-p.RLsampleTime/3600-.0001*max(0,T-308.15)*p.RLsampleTime;
terminal=complete || fault;
if terminal && ~previousTerminal
 if fault,reward=reward-100;else,reward=reward+10;end
end
done=terminal && abs(I)<=p.ShutdownCurrentTolerance;
previousSOC=z;previousTerminal=terminal;
end
