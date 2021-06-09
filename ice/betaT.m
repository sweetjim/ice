function beta = betaT(T_in)

beta_T = [-50,0,88,207,303,385,457,522,582,640,695]*1e-6; %1/K
T       = [1 4 10:10:90];

p       = polyfit(T,beta_T,5);
That    = linspace(1,90);
beta_Tf = polyval(p,That);

beta = beta_Tf(find(That>=T_in,1));
end

