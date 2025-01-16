%% Frechet derivative F' in a point (x1,x2,u) as matrix-form
function [Frechet] = Frechetderivative_k(x1,x2,u,k,param)
Frechet=zeros(param.m,2*param.m+1);
omega=[0:floor(param.m/2)-1 floor(-param.m/2):-1]';
it=k;
tau_pos=param.distance(it)/param.effectivedT/u;
tau_neg=(param.distance(param.Nwaves)-param.distance(it))/param.effectivedT/u;
W_pos = exp(-1i * 2 * pi * tau_pos * omega / param.m); 
W_neg = exp(-1i * 2 * pi * tau_neg * omega / param.m); 
a_pos=2*pi*1i*omega*param.distance(it)/param.m;
a_neg=2*pi*1i*omega*(param.distance(param.Nwaves)-param.distance(it))/param.m;
Frechet(:,1:param.m)=diag(W_pos);
Frechet(:,param.m+1:2*param.m)=diag(W_neg);
Frechet(:,2*param.m+1)=(x1.*a_pos/((u*param.effectivedT)^2)).*W_pos+(x2.*a_neg/((u*param.effectivedT)^2)).*W_neg;
end