%Adapt data from phenoscope results to greenlab data

function data_matrix = phenoscope_matrix(csv_path,row_offset)
    if nargin <2, row_offset = 7; end
    % Read leaf area data
    data = readmatrix(csv_path);
    
    % Have the size
    [nb_rows, nb_columns] = size(data);
         
    
    % Initialize the matrix
    data_matrix = NaN(nb_rows+row_offset, nb_columns-2);
    
    %Two cotyledon are considered as one organ in greenlab model
    data_matrix((row_offset+1):end, 1) = sum(data(:, 2:3),2);
    
    % Remplir les colonnes 2 et suivantes avec les colonnes du CSV
    for col = 4:nb_columns
        data_matrix((row_offset+1):end, col-2) = data(:, col);
    end
end
