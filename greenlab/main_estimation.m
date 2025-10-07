%Estimation of given parameter with the leaves area datas

%Parameter 
%   -data_manip: structure containint data information
%       * csv_path : path of the leaves areas (in cm2)
%       * SLA: SLA at D30 in cm2/g (common for all leaves)
%       * PAR : cumulative PAR in MJ/cm2/day
%       * DWroot: g of root DW
%   -output_folder : name of the output folder we want
%   -paramNamesToEstimate : names of the parameter we want to estimate
%   as a list with the structure given in params (for exemple
%   ["leaf.a","leaf.b","RUE"]
%   -initialGuess : by default the ones of default_parameters() file
%   -row_offset : offset of days between data and phenoscope (greenlab
%   days)
%   -other params : main_greenlab options 

function [R2, optimal_parameters, phy, fval, exitflag, output] = main_estimation(data_manip, paramNamesToEstimate,output_folder, initialGuess,row_offset,params, optionsGreenlab)

    addpath('utils');
    
    if nargin < 3, output_folder = "./results"; end
    % Chargement des paramètres initiaux si non fournis
    if nargin < 4 || isempty(initialGuess)
        params_ini = default_parameters();
        initialGuess = zeros(length(paramNamesToEstimate), 1);
        pattern_leaf = '^leaf\.(.+)$';
        pattern_root = '^root\.(.+)$';
        pattern_internode = '^internode\.(.+)$';

        for i = 1:length(paramNamesToEstimate)
            match_leaf = regexp(paramNamesToEstimate{i}, pattern_leaf, 'tokens');
            match_root = regexp(paramNamesToEstimate{i}, pattern_root, 'tokens');
            match_internode = regexp(paramNamesToEstimate{i}, pattern_internode, 'tokens');

            if ~isempty(match_leaf) && isfield(params_ini.leaf, match_leaf{1}{1})
                initialGuess(i) = params_ini.leaf.(match_leaf{1}{1});
            elseif ~isempty(match_root) && isfield(params_ini.root, match_root{1}{1})
                initialGuess(i) = params_ini.root.(match_root{1}{1});
            elseif ~isempty(match_internode) && isfield(params_ini.internode, match_internode{1}{1})
                initialGuess(i) = params_ini.internode.(match_internode{1}{1});
            elseif isfield(params_ini, paramNamesToEstimate{i})
                initialGuess(i) = params_ini.(paramNamesToEstimate{i});
            else
                error("Paramètre inconnu : %s", paramNamesToEstimate{i});
            end
        end
    end

    % Définition des valeurs par défaut pour les autres paramètres
    % delta jours pheno/greenlab: 7 jours
    if nargin < 5 || isempty(row_offset), row_offset = 7; end
    if nargin <6 || isempty(params),params = default_parameters(); end
    if nargin < 7 || isempty(optionsGreenlab)
        % on definit les options de simulation Greenlab par default
        optionsGreenlab.days_or_phyllochron = true; % en temps or thermal time
        optionsGreenlab.root_bool = true; % simul root
        optionsGreenlab.internode_bool = false; % simul internode
        optionsGreenlab.is_variation_thickness = false; % varying SLA
    end
    
    % Chargement des données expérimentales
    data = phenoscope_matrix(data_manip.csv_path, row_offset);
    [duration, ~] = size(data);
    
    % update of SLA, PAR.
    if isfield(data_manip,'SLA')
        params.SLA = data_manip.SLA;
        params.SLA_coty = data_manip.SLA;
    end
    if isfield(data_manip,'PAR')
        params.PAR_j = data_manip.PAR;
    end    

        % Calcul du phyllochrone 
    viewed_leaves = cumsum(~isnan(data), 1) > 0; % count also leaves that were seen before
    leaf_counts = sum(viewed_leaves, 2); %nb de feuilles à chaque pas de temps
    time = (1:size(data,1))'; %instants
    mdl = fitlm(time(leaf_counts>3), leaf_counts(leaf_counts>3));
    params.reg = mdl.Coefficients.Estimate;  % [intercept ; slope]
    R2 = mdl.Rsquared.Ordinary;
    % Affichage du résultat
    fprintf("R2 : %f\n", mdl.Rsquared.Ordinary);
    phy = 1 / params.reg(2);
    % Recupération des paramètres
    params.phy = phy;
    params.nb_leaves = max(leaf_counts);

    % Optimisation avec la méthode de Nelder-Mead
    np = length(paramNamesToEstimate);
    optionsOptim = optimset('Display', 'off', 'MaxIter', 100000);
    [optimal_parameters, fval, exitflag, output] = fmincon(@(x) cost_function(x, paramNamesToEstimate, data, duration,params, optionsGreenlab), initialGuess, [],[],[],[],zeros(np,1),[],[], optionsOptim);

    %OLD VERSION 
    %[optimal_parameters, fval,exitflag, output] = fminsearch(@(x) cost_function(x, paramNamesToEstimate, data, duration, params, optionsGreenlab), initialGuess, optionsOptim);

    % Mise à jour des paramètres estimés
    estimated_params = update_params(params, paramNamesToEstimate, optimal_parameters);
    % Affichage du résultat
    fprintf("Erreur quadratique : %f\n", fval);
    fprintf("Exitflag : %f\n", exitflag);
    fprintf("Algorithm: "+ output.algorithm);

    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end
    save(fullfile(output_folder, 'estimated_values.mat'), "optimal_parameters");
    save(fullfile(output_folder, 'estimation_param.mat'), 'estimated_params');

    % Lancement du modèle avec les paramètres estimés
    organs = main_greenlab(estimated_params,duration, optionsGreenlab);
    disp("Parameter to estimate : ")
    disp(paramNamesToEstimate)

    %% Save the plots and the results
    fileName = fullfile(output_folder, 'simulation_results.mat');
    save(fileName, 'organs');
    % prepare structure to plot
    data_for_plot.leaves_area = data;
    if isfield(data_manip,'DWroot')
        data_for_plot.root_mass = data_manip.DWroot; 
    else
        data_for_plot.root_mass = NaN;
    end
    if isfield(data_manip,'rosette_area_cm2')
        data_for_plot.rosette_area = [NaN(row_offset,1); data_manip.rosette_area_cm2];
    else
        data_for_plot.rosette_area = [data NaN(duration,1)];
    end
    plot_all(organs,data_for_plot,output_folder)
end
