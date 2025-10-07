function params = default_parameters()
%% Default parameters of the simulation
params = struct();

%Leaves parameters
params.leaf = struct();

params.leaf.sink_strength_leaf = 1;
params.leaf.a = 4.8621; % parameter of Angelique : 3.07
params.leaf.b = 14.7978; %parameter of Angelique : 5.59
params.leaf.c = 0.5; %default value
params.leaf.T_cotyledon = 418; 
params.leaf.T_leaves = 470;
    
params.leaf.T_exp_C_d = [params.leaf.T_cotyledon,zeros(1,40)+params.leaf.T_leaves];

%Internode
params.internode = struct();

params.internode.T_exp_C_d = 357; %valeur de l'article de Anne et Véro
params.internode.T_exp = 13; %valeur de l'article de Anne et Véro
params.internode.sink_strength=0.69; 
params.internode.a = 2.62;
params.internode.b = 2.98;
params.internode.c = 0.5;

% Paramètre de la fonction de production
params.date = struct();

%-----------------------------------------
% RUE in gDW/MJ
% 2.5577 (SLA variable)
% 4.0847 (SLA fixe)
params.RUE = 4.0847; % qui marche (SLA variable


%-------------------------------------------------------
% PAR
% Phenoscope (standard robot) values
% For XL: (E_pheno = 300 and p_PAR = 0.9061)
conv_MJ_mol = 1.6/8; % from Angelique et al. 2008
E_pheno = 220; %µE: µmol/m2/s
p_PAR = 0.95; % fraction of light intensity with 400-700nm
Light_period = 8; % hour
PAR_cumulative = E_pheno*p_PAR*3600*Light_period*1e-6; % in mol/m2/day
params.PAR_j = conv_MJ_mol*PAR_cumulative*1e-4; % in MJ/cm2/day

%----------------------------------------------------------
% SLA
% default varying values
params.SLA0 = 1.5699e+03; %cm2/g
params.SLA1_tau = 0.0016; % 1/°Cd
params.SLA0_coty = 1.0489e+03; %cm2/g
params.SLA1_coty = 6.5205e-04; %1/°Cd
% values from angelique
% params.SLA0 = 1440; %cm2/g
% params.SLA1_tau = 0.002; % 1/°Cd
% params.SLA0_coty = 898; %cm2/g
% params.SLA1_coty = 8.0501e-04; %1/°Cd

% default constant values are the ones for Col in W+N+
% determined from PlantRBA (mean of all replicates)
PRA_col_w1n1 = 6.1750; % cm2
DW_col_w1n1 = 10.3163*1e-3; % g
params.SLA = PRA_col_w1n1/DW_col_w1n1; % cm2/g
params.SLA_coty = PRA_col_w1n1/DW_col_w1n1; %cm2:g
% 544 from angelique

% default Root demand.
% 10% de la demande totale
r_demand = 0.1;% 
params.Root_demand = r_demand/(1-r_demand);

% other default params
params.Q0=1.6*10^(-5); % Initial biomass of the seed (g)
params.C_d0 = 0; %Number of degree day at the begining of the simulation
params.Temp = 19; %Temperature in °C (21 the day and 18 the night : 8h day)
params.T0 = 3; %Reference temperature of arabidopsis thaliana
params.phy = 1/0.5; %phyllochron
params.C_d_phy = params.phy*params.Temp; % °Cd of the phyllochron
params.app_leaf_3 = 6.5+8; %S003
params.first_leaves_days = [2+8, 2+8];   

%params.C_d_phy = 39; % °Cd of the phyllochron
%params.new_leaves_days = [2,2,6,8,10,12,14,16,17,18,20,22,24,26]+8; %S003

end

