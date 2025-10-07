function params = update_params(params, paramNamesToEstimate, estimatedValues)
    % Mise à jour des paramètres spécifiés par paramNamesToEstimate avec les valeurs estimées
    pattern_leaf = '^leaf\.(.+)$';
    pattern_root = '^root\.(.+)$';
    pattern_internode = '^internode\.(.+)$';
    pattern_app_leaf = '^app_leaf[._]?(.+)';
    for i = 1:length(paramNamesToEstimate)
        match_leaf = regexp(paramNamesToEstimate{i}, pattern_leaf, 'tokens');
        match_root = regexp(paramNamesToEstimate{i}, pattern_root, 'tokens');
        match_internode = regexp(paramNamesToEstimate{i}, pattern_internode, 'tokens');
        match_app_leaf = regexp(paramNamesToEstimate{i}, pattern_app_leaf, 'tokens');

        if ~isempty(match_leaf)
            params.leaf.(match_leaf{1}{1}) = estimatedValues(i);
        elseif ~isempty(match_root)
            params.root.(match_root{1}{1}) = estimatedValues(i);
        elseif ~isempty(match_internode)
            params.internode.(match_internode{1}{1}) = estimatedValues(i);
       elseif ~isempty(match_app_leaf)
            params.app_leaf_(match_app_leaf{1}{1}) = estimatedValues(i);
        else 
            params.(paramNamesToEstimate{i}) = estimatedValues(i);
        end 
    end
end
