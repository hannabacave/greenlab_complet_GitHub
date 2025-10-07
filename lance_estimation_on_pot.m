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
manip = "P3ID76";
num_pot=3;
pot_directory="S00"+num_pot+"/";
path_manip = path_all_manip+manip+"/";

% absolute path towards leaf area
path_pot_segmented=path_manip+"/Segmented/"+pot_directory;
file_pot_segmented=path_pot_segmented+"tailles_feuilles_ordonnees.csv";
path_result_greenlab=pwd+"/results_greenlab/"+manip+"/"+pot_directory+"/"+version;

% absolute path towards Manip MetaData
file_consignes_manip = path_manip+"Consigne_"+manip+".csv";

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


% Choix des paramètres à estimer
EstimatedParams = ["leaf.a","leaf.b","RUE", "app_leaf_3"];

optimal_parameters = main_estimation(DataManip, EstimatedParams,path_result_greenlab);



