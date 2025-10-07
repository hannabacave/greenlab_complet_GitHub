%-----------------------------------------------------
% Script running the estimation of GreenLab
% model parameters on each pot of a Phenoscope Manip
%-----------------------------------------------------

%%%%%%%%%%%%%%%%
% WARNINGS OFF
%%%%%%%%%%%%%%%%%
warning('off', 'all')

% equivalent to setwd
scriptDir = fileparts(mfilename('fullpath'));

addpath(fullfile(scriptDir, 'greenlab'));
addpath(fullfile(scriptDir, 'greenlab', 'utils'));

version = "v3_coherent_expansion_time";
path_all_manip = "C:/Users/Hanna Bacave/Documents/Développement/GreenLab/Données/";
Manips = ["P3ID76", "P3ID77"]; % on va lancer sur toutes les manips de la liste

for i_manip = 1:length(Manips)
    manip = Manips{i_manip}; % selection de la manip
    disp(" ")
    disp(" ")
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    disp("!!!!!!!!!!!! NEW MANIP !!!!!!!!!!!!")
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    disp(manip)

    % paths
    path_manip = path_all_manip+manip+"/";
    path_segmented = path_all_manip+manip+"/Segmented/";
    % absolute path towards Manip MetaData
    file_consignes_manip = path_manip+"Consigne_"+manip+".csv";
    
    % load Data PlantRBA
    % PRA_physio PRA_pheno_all Root DW SLA E_pheno p_PAR Light_period
    data = path_all_manip + "Data_for_Greenlab.mat";
    load(data); 
    
    % Calcul du PAR
    %CC12 (Ledpower) / Pheno-classique (220µmol) :
    %Blue = 33%. Green = 42%. Red = 21%
    %(Somme R+G+B = PAR = 96%)
    % Vegeled W1 / Pheno XL (300 µmol):
    % Blue: 9.82%. Green = 32.61%. Red: 48.18%
    % (Somme R+G+B = PAR = 90.61%)
    
    ParamPheno.E_pheno = E_pheno; % µmol/m2/s
    ParamPheno.Light_period = Light_period;
    ParamPheno.p_red = 21/100; % proportion de rouge dans le spectre
    ParamPheno.p_blue = 33/100; % proportion de bleu dans le spectre
    ParamPheno.p_green = 42/100; % proportion de vert dans le spectre
    ParamPheno.pPAR = (ParamPheno.p_red+ParamPheno.p_blue+ParamPheno.p_green);
    [PAR_estime,PAR_compare] = calcul_PAR(ParamPheno); % in MJ/m2/day
    % calcul PAR
    DataManip.PAR = PAR_estime*1e-4; % in MJ/cm2/day
    
    % Calcul SLA
    % en cm2/gDW
    conversion_pixel_vers_cm2 = 28900;
    
    % Results matrix
    results_matrix = zeros(735, 9);
    
    % Initialisation tableau pour erreurs
    pots_en_erreur = []; % liste des pots en erreur
    messages_erreur = {}; % messages d'erreur associés

    %fichier logs pour sauvegard
    tmp_dir = fullfile("results_greenlab", manip, "0_tabs_results", version, "tmp");
    if ~exist(tmp_dir, 'dir')
        mkdir(tmp_dir);
    end

    log_file = fullfile(tmp_dir, "log.txt");
    fid_log = fopen(log_file, 'a'); % 'a' pour append (ajouter)
    
    content_dir = dir(path_segmented);
    for i=4:length(content_dir)
        fprintf(fid_log, " \n ");
        fprintf(" \n ")

        if content_dir(i).isdir && length(content_dir(i).name) == 4 && startsWith(content_dir(i).name,'S')
            try
                num_pot=str2double(content_dir(i).name(2:end));
                fprintf(fid_log, "\n Pot num : %f\n", num_pot);
                fprintf("\n Pot num : %f\n", num_pot);
    
                pot_directory=content_dir(i).name+"/";%"S00"+num_pot+"/";
        
                % absolute path towards leaf area
                path_pot_segmented=path_manip+"/Segmented/"+pot_directory;
                file_pot_segmented=path_pot_segmented+"tailles_feuilles_ordonnees.csv";
                path_result_greenlab=pwd+"/results_greenlab/"+manip+"/"+pot_directory+"/"+version;
        
                % load Manip MetaData
                % Pot    Genotype    DateDeSemis    Traitement     Dur_eManip     Exp_rimentation
                % ___    ________    ___________    __________    ____________    _______________
                %
                %   3    {'Col'}     13-Jun-2022    {'W+N+'  }    {'24 jours'}      {'P3ID77'}
                %   4    {'Col'}     13-Jun-2022    {'W+N-'  }    {'24 jours'}      {'P3ID77'}
                T = readtable(file_consignes_manip);
                idPot = find(T.Pot == num_pot);
                genotype = T.Genotype{idPot};
                traitement = strrep(T.Traitement{idPot},'+','1');
                traitement = strrep(traitement,'-','0');
        
                index_pot_pheno = find(PRA_pheno_all.(genotype).(traitement).(manip).pot==num_pot);
                DataManip.rosette_area_cm2 = PRA_pheno_all.(genotype).(traitement).(manip).all(index_pot_pheno,:)'/conversion_pixel_vers_cm2;
                DataManip.SLA = PRA_physio.(genotype).(traitement).mean/(DW.(genotype).(traitement).mean*1e-3);
        
                % root dw
                DataManip.DWroot = NaN;
                % if isfield(Root,genotype)
                %     if isfield(Root.(genotype),traitement)
                %         % in g
                %         DataManip.DWroot = Root.(genotype).(traitement).DW.P3ID76.mean*1e-3;
                %     end
                % end
                DataManip.csv_path = file_pot_segmented;
        
                %cd greenlab/
        
                EstimatedParams = ["leaf.a","leaf.b","RUE", "app_leaf_3"];
    
                [R2, optimal_parameters, phy, fval, exitflag, output] = main_estimation(DataManip, EstimatedParams,path_result_greenlab);
    
                 results_matrix(i, :) = [num_pot, R2, phy, fval, exitflag, optimal_parameters(:)'];

                 % sauvegarde tmp                 
                 colNames = ["Pot", "R2", "phy", "fval", "exitflag", EstimatedParams{:}];
                 res_tmp = array2table(results_matrix, 'VariableNames', colNames); %mise en forme
                 writetable(res_tmp, fullfile(tmp_dir, "res_tmp.csv")); % save

                fprintf('Sauvegarde effectuée pour le pot %d\n', num_pot);
                fprintf(fid_log, 'Sauvegarde effectuée pour le pot %d\n', num_pot);
    
            catch ME
                % Ajoute le numéro de pot et le message d'erreur
                pots_en_erreur(end+1) = num_pot;
                messages_erreur{end+1} = ME.message;
                fprintf('Erreur rencontrée pour le pot %d : %s\n', num_pot, ME.message);
                fprintf(fid_log, 'Erreur rencontrée pour le pot %d : %s\n', num_pot, ME.message);
                
                % Continue avec les autres pots
                continue;
            end
        end
    end
    
    colNames = ["Pot", "R2", "phy", "fval", "exitflag", EstimatedParams{:}];
    
    % Conversion en table
    results_table = array2table(results_matrix, 'VariableNames', colNames);
    results_table(1:3, :) = [];
    disp(results_table(1:10, :))
    
    % Sauvegarde
    output_dir = fullfile("results_greenlab", manip, "0_tabs_results", version);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    writetable(results_table, fullfile(output_dir, "results_estim_greenlab.csv"));
    
    % Table des erreurs dans le try/catch
    erreurs_table = table(pots_en_erreur', messages_erreur', 'VariableNames', {'Pot', 'Message'});
    writetable(erreurs_table, fullfile(output_dir, "pots_en_erreur.csv"));
    
    fprintf(fid_log, "\n !!!!!! FIN !!!!");
    fclose(fid_log);
end

disp("\n fin du process")


