clear ;
close all;
clc;
%% Parameters
h = 5000; % m (cruising altitude)

AR = 10;
L_D = 17.7; %L/D Guess
m_payload=1000; %Set payload weight
Range = 1000;% range in km

V_max_kmh = 500; %  maximum velocity not cruise (km/h)
V_cruise_kmh = 450;
V_stall_kmh = 145;
V_stall_mps = V_stall_kmh/3.6;
C_L_max = 1.8; %With flaps used during landing
Taper_rat = 0.4;  %Main wing taper ratio
e0=0.98;
per_a = 0.5; %Percentage of aileron span respect to total wing span 
g=9.81; 

F_rat = 8; %Fineness Ratio
T_vt = 0.7; %Vertical tail taper ratio
AR_vt = 0.6; %Aspect Ratio vertical tail
T_ht = 0.3; %Horizontal taper ratio
AR_ht = 2.8; %Aspect Ratio horizontal tail


%% Calculation
[T_sl, rho_sl, mu_sl] = atmosphere(0); % Sealevel
[T_cruise, rho_cruise, mu_cruise] = atmosphere(h); % Cruise altitude

[M_to,f_b] = Mass_Iteration1(Range,m_payload,L_D);
P_W = Power_Weight(V_max_kmh,L_D);
[W_S,S] = Wing_Loading(V_stall_kmh,V_cruise_kmh,C_L_max,AR,M_to,h,e0);

V_cruise_mps = V_cruise_kmh/3.6;

C_L_clean = W_S*g * 1/(0.5*V_stall_mps^2 *rho_sl);

[M_to_refined,M_e_refined,M_bat] = Mass_Iteration2(V_max_kmh,P_W,W_S,AR,f_b,m_payload);

[L_fuse, W_fuse,b,C_root,MAC,S_vt,b_vt,Cr_vt,S_ht,b_ht,Cr_ht,C_a,b_a,C_e,b_e,C_r,b_r,L_vt,L_ht]= Sizing(M_to_refined,F_rat,Taper_rat,AR,S,T_vt,AR_vt,T_ht,AR_ht,per_a);
[W_S,S] = Wing_Loading(V_stall_kmh,V_cruise_kmh,C_L_max,AR,M_to_refined,h,e0);
C_L_cruise = M_to_refined*g/(0.5*V_cruise_mps^2*rho_cruise*S);
C_L_landing = M_to_refined*g/(0.5*(V_stall_kmh/3.6)^2*rho_sl*S);

%Semi-Empirical case for now
S_fuse = pi*W_fuse^2*0.25 * 2 + L_fuse*pi*W_fuse;
Sw = S_fuse + S;
Sw_rat = Sw/S;
Cdf = Sw_rat * 0.0065;

[Re, M, Cl] = nondimensionalize(AR, S, V_cruise_kmh/3.6, M_to_refined, h);
airfoil = 'coord_seligFmt/naca652415.dat';
pol = xfoil(airfoil, 'alfa', 0:0.5:15, Re, M, 'ppar n 200', 'oper iter 500');
Cd3d = pol.CD + (pol.CL.^2)/(pi*0.98*AR)+Cdf;
LD = pol.CL./Cd3d;
plot(pol.alpha,LD)