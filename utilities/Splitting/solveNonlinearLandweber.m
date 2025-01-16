function [rho_rec,pwv] = solveNonlinearLandweber(rho,param)
%% Solve Pulsewave splitting problem with Tikhonov Regularization
%% Transform Problem into Frequency Domain

% Force the input to be a column vector.
Rho=zeros(param.Nwaves*param.m,1);
for i=1:param.Nwaves
    Rho(param.m*(i-1)+1:param.m*i)=fft(rho.sum{i});
end

%% Landweber Iteration
it=0;
stop=0;
sol=zeros(2*param.m+1,1);
sol(2*param.m+1)=5;
sol_old=sol;
%Include adjoint embedding operator for weighted spaces
d=(param.beta*abs([0:floor(param.m/2)-1 floor(-param.m/2):-1]).^2+1).^(-param.s);
Adj_embedding=diag([d d 1/param.c]);
HDP=zeros(3,1);
while it<param.max_it && ~stop
    it=it+1;
    if param.nesterov
        z=sol+(it-1)/(it+2)*(sol-sol_old);
    else
        z=sol;
    end
    residual=Rho -operatorF(z(1:param.m),z(param.m+1:2*param.m),z(2*param.m+1),param);
    FrDer=Frechetderivative(z(1:param.m),z(param.m+1:2*param.m),z(2*param.m+1),param);
    s=Adj_embedding*FrDer'*residual;
    %Omega chosen via steepest descent
    omega(it)=(norm_X(s,param)/norm(FrDer*s))^2;
    sol_old=sol;
    sol=z+omega(it)*s;
    if sol(2*param.m+1)<1
        sol(2*param.m+1)=1;
    end
    %Heuristic discrepancy principle, avoiding minimum for small iterations
    %(first 5)
    HDP=circshift(HDP,1);
    HDP_res=Rho-operatorF(sol(1:param.m),sol(param.m+1:2*param.m),sol(2*param.m+1),param);
    HDP(1)=sqrt(it)*norm(HDP_res,2); 
    res_norm(it)=norm(HDP_res,2);
    if it>5
        if HDP(1)>HDP(2) && HDP(2)<HDP(3) && ~param.justmax
            stop=1;
        end
    end
end
if it==param.max_it
    fprintf("Maximum iterations reached at %i iterations \n",it)
else
    fprintf("Landweber stopped after %i iterations via the Heuristic DP \n",it);
end
pwv=sol(2*param.m+1);
figure
plot(1:it,res_norm)
%legend("residual norm","step size")
rho_rec.for{1}=real(ifft(sol(1:param.m)));
rho_rec.back{param.Nwaves}=real(ifft(sol((param.m+1):(2*param.m))));

%Create whole set of reconstructed waves
tau=param.distance/param.effectivedT/pwv;
for it=2:param.Nwaves
rho_rec.for{it}=FourierShift(rho_rec.for{1},tau(it));
rho_rec.back{param.Nwaves+1-it}=FourierShift(rho_rec.back{param.Nwaves},tau(param.Nwaves)-tau(param.Nwaves+1-it));
end
for it=1:param.Nwaves
    rho_rec.sum{it}=rho_rec.for{it}+rho_rec.back{it};
end
end

