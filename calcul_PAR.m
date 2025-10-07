
function [PAR_estime,PAR_approx] = calcul_PAR(ParamPheno)

%------------
% calcul du PAR d'après les données du phenoscope XL
pPAR = ParamPheno.pPAR; 
conv_MJ_mol = 1.6/8; % from Angelique et al. 2008
% 
p_red = ParamPheno.p_red;  % 600-700nm
p_blue = ParamPheno.p_blue; % 400-500nm
p_green = ParamPheno.p_green; % 500-600nm

% irradiation
E_pheno = ParamPheno.E_pheno; % µmol/m2/s

% Light_period
Light_period = ParamPheno.Light_period;%h

% energie pour une photon
% E = h*c/lamda
% h = cte de planck
% lamba: longueur d'onde en nm
% c = vitesse de la lumiere ds le vide
% et on multiplie par le nbre d'avogadro
% Na pour avoir une mole 
h = 6.62607015e-34; % J.s
c = 299792458; %m/s
Na = 6.022e23;
lambda_red = 650e-9; % m
lambda_blue = 450e-9; % m
lambda_green = 550e-9; %m

% E of 1 mol de red
E_red= Na*c*h/lambda_red/1e6; % MJ
E_blue = Na*c*h/lambda_blue/1e6; %MJ
E_green = Na*c*h/lambda_green/1e6; %MJ

PAR_cumulative_tot = E_pheno*3600*Light_period*1e-6; %mol/m2/day

PAR_red = PAR_cumulative_tot*p_red*E_red; % MJ/m2/day
PAR_blue = PAR_cumulative_tot*p_blue*E_blue; %MJ/m2/day
PAR_green = PAR_cumulative_tot*p_green*E_green;%MJ/m2/day


PAR_estime = PAR_red + PAR_blue + PAR_green;

PAR_approx = conv_MJ_mol*E_pheno*pPAR*3600*Light_period*1e-6;
