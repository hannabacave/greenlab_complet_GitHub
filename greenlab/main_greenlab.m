%main_greenlab.m 
%Runs a greenlab models 

%Paramters : 
%   -params : parameters of the greenlab such as the RUE, SLA...
%   -duration : time during when we want the model to run
%   -is_plot : having or not plots 
%   -experimental_data : having or not data to plot to compare the model
%   -days_or_phyllochron : steps of the model can be a day or a 
%       phyllochron. If true : days step. false : phyllochron step
%   -root_bool : tacking or not the root in the model 
%   -internode_bool : tacking or not the internode in the model
%   -is_variation_thickness : tacking or not the evolution of the SLA
%       during the time of a leaf

function [organs] = main_greenlab(params,duration,optionsGreenlab)

addpath('utils');

%% Default parameters
if nargin < 1 || isempty(params), params = default_parameters(); end
if nargin < 2 || isempty(duration), duration = 30; end
if nargin < 3 || isempty(optionsGreenlab)
    % on definit les options de simulation Greenlab par default
    optionsGreenlab.days_or_phyllochron = true; % en temps or thermal time
    optionsGreenlab.root_bool = true; % simul root
    optionsGreenlab.internode_bool = false; % simul internode
    optionsGreenlab.is_variation_thickness = false; % varying SLA
end

%% Loadings parameters
C_d_tot = params.C_d0; %Counting the degree days of the global experiment
Q= params.Q0; % Setting the production to the initial one
RUE = params.RUE; %
PAR_j = params.PAR_j;
Temp = params.Temp;
demand_a = params.leaf.a; %Parameters for beta law demand 
demand_b = params.leaf.b; %Parameters for beta law demand
demand_c = params.leaf.c; %Parameters for beta law demand
time_leaf = params.leaf.T_leaves; %Growth time of a leaf (°C.days)
time_cotyledon = params.leaf.T_cotyledon; %Growth time of cotyledon (°C.days)
root_demand = params.Root_demand; % % fraction of plant demand for roots

% Loading Simulation options
days_or_phyllochron = optionsGreenlab.days_or_phyllochron;
root_bool = optionsGreenlab.root_bool;
internode_bool = optionsGreenlab.internode_bool;
is_variation_thickness = optionsGreenlab.is_variation_thickness;

if internode_bool
    demand_internode_a = params.internode.a; %Parameters for beta law demand 
    demand_internode_b = params.internode.b; %Parameters for beta law demand
    demand_internode_c = params.internode.c; %Parameters for beta law demand
    Time_internode = params.internode.T; %Growth time of a leaf (°C.days)
end

if is_variation_thickness
    SLA0_coty = params.SLA0_coty; %Initial surface leaf area of the cotyledons (cm2/g)
    SLA1_coty = params.SLA1_coty; %Exponential decay constant of SLA of cotyledon (°C-1.day-1)
    SLA0 = params.SLA0; %Initial surface leaf area of the leaves m2/g
    SLA1_tau = params.SLA1_tau; %Exponential decay constant of leaves SLA (°C-1.day-1)
else 
    SLA_coty = params.SLA_coty; %Surface leaf area of cotyledons (cm2/g)
    SLA = params.SLA; %Surface leaf area of leaves (cm2/g)
end


%% Settings
% 1.Leaf
% Each elementcorresponding to a leaf

leaves = struct();
leaves.mass = zeros(1,1); % dry mass (starting without leaf)  
leaves.area = zeros(1,1); %leaf area
leaves.rank = ones(1,1); %rank of the leaf (starting at one)
leaves.demand = zeros(1,1); %demand of the leaf
leaves.age_C_d = zeros(1,1); %age of the leaf in degree days °C.day
N_objs = 1; %Number of leaves

% 2.Root
% We only need its mass during time
root = struct();
root.mass = 0;
root.age_C_d = 0;
root.demand = 0;


% 3.Internode
internode = struct();
internode.mass = 0;
internode.age_C_d = 0;
internode.demand = 0;


% Structure to save results
organs= struct();
%% Simulation

for n=1:duration
    %% Calculate the demand of each organ
    leaves.demand(1) =beta_law(leaves.age_C_d(1),demand_a,demand_b,demand_c,time_cotyledon);
    for k=2:N_objs
        leaves.demand(k) =beta_law(leaves.age_C_d(k),demand_a,demand_b,demand_c,time_leaf);
    end
    
    if internode_bool
        internode.demand = beta_law(internode.age_C_d,demand_internode_a,demand_internode_b,demand_internode_c,Time_internode);
    else 
        internode.demand = 0;
    end

    if root_bool
        root.demand = root_demand*sum(leaves.demand);
    else 
        root.demand = 0;
    end
  
    D = internode.demand + root.demand + sum(leaves.demand);
    %% Repartition of the biomass in each organ
    root.mass=root.mass+root.demand*Q/D;
    internode.mass = internode.mass + internode.demand*Q/D;
    
    %The two cotyledons are considered as one organ
    leaves.mass(1) = leaves.mass(1)+leaves.demand(1)*Q/D;
    if is_variation_thickness
        SLA_coty  = SLA0_coty*exp(-SLA1_coty*leaves.age_C_d(1));
    end
    leaves.area(1) = leaves.mass(1)*SLA_coty;
    for k=2:N_objs
        leaves.mass(k)=leaves.mass(k)+ leaves.demand(k)*Q/D;
        if is_variation_thickness
            SLA = SLA0*exp(-SLA1_tau*leaves.age_C_d(k));
        end
        leaves.area(k) = leaves.mass(k)*SLA;
    end
    
    % Calcul de la area relative pour la fonction production de biomasse
    
    S = leaves.area; % cm2
    S_prime = calculate_S_projected(S); % cm2
    
    
    %% Save the new values in the results
    organs.leaves.area(n,1:N_objs)=leaves.area; % cm2
    organs.leaves.mass(n,1:N_objs)=leaves.mass; % gDW
    organs.leaves.demand(n,1:N_objs) = leaves.demand;
    organs.root.mass(n)=root.mass;% gDW
    organs.root.demand(n) = root.demand;
    organs.internode.mass(n) = internode.mass; % gDW
    organs.internode.demand(n) = internode.demand;
    organs.bioma(n)=Q; %gDW
    organs.projected_leaves_area(n) = S_prime; % cm2
    organs.global_area(n) = sum(S); % cm2
    organs.C_d(n) = C_d_tot; % degree jours

     %% Calculate the next biomass production

    
    if days_or_phyllochron
        PAR = PAR_j;
    else 
        PAR = PAR_j*C_d_cycle/(Temp-params.T0);
    end

    Q = RUE * S_prime * PAR;

    %% Update organs age 
    if days_or_phyllochron
        C_d_tot = C_d_tot + (Temp-params.T0);
        for k=1:N_objs
            leaves.age_C_d(k) = leaves.age_C_d(k) + Temp - params.T0;
        end
        if root_bool
            root.age_C_d = root.age_C_d + Temp - params.T0;
        end
        if internode_bool
            internode.age_C_d = root.age_C_d +Temp - params.T0;
        end

        
    else 
        C_d_tot = C_d_tot + C_d_cycle;
        for k=1:N_objs
            leaves.age_C_d(k) = leaves.age_C_d(k) + C_d_cycle;
        end
        if root_bool
            root.age_C_d = root.age_C_d + C_d_cycle;
        end
        if internode_bool
            internode.age_C_d = root.age_C_d +C_d_cycle;
        end
    end

    %% Potential creation of new organs
      y = 3 + params.reg(2)*n + params.reg(1);  % nombre total de feuilles prédit à ce temps

        if floor(y) <= 2
            % Avant l'apparition des premières feuilles modélisées
            number_new_leaves = sum(params.first_leaves_days == n);
        
            for i = 1:number_new_leaves
                if N_objs < params.nb_leaves
                    N_objs = N_objs + 1;
                    leaves.mass(end+1)     = 0;
                    leaves.area(end+1)     = 0;
                    leaves.age_C_d(end+1)  = 0;
                    leaves.demand(end+1)   = 0;
                else
                    break;
                end
            end
        
        else
            if n >= params.app_leaf_3
                % temps d'apparition de la nouvelle feuille (si c'est 3 ça vaut
                % params.app_leaf_3, sinon ça vaut le temps prec + phy
                if N_objs == 3 % si on s'apprête à créer l'objet 4 (i.e la feuille 3)
                    tps_app_new_leaf = params.app_leaf_3;
                end 
    
                % Apparition de la 3e feuille et suivantes
                if n >= tps_app_new_leaf
                    number_new_leaves = max(0, floor(y) - N_objs);
    
                    if number_new_leaves > 0
                        % si on a de nouvelles feuilles, on les crée
                        for i = 1:number_new_leaves
                            if N_objs < params.nb_leaves
                                N_objs = N_objs + 1;
                                leaves.mass(end+1)     = 0;
                                leaves.area(end+1)     = 0;
                                leaves.age_C_d(end+1)  = (n - tps_app_new_leaf)*(Temp - params.T0);
                                leaves.demand(end+1)   = 0;
                            else
                                break;
                            end
                        end
                        % maj next appearing time
                        tps_app_new_leaf = tps_app_new_leaf + params.phy;
                    end
    
                end
            end 
        end
    end
end



      


