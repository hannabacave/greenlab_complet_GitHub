function error = cost_function(estimatedValues, paramNamesToEstimate, data, duration,params, optionsGreenlab)
    
    params = update_params(params, paramNamesToEstimate, estimatedValues);

    % Having the greenlab result with the current parameters
    results = main_greenlab(params,duration,optionsGreenlab); 
    
    % Use le quadratic error
    output_model = results.leaves.area;
    mask = ~isnan(data);
    usefull_output = output_model(mask);
    real_data = data(mask);
    error = usefull_output - real_data; 
    error = sum(error.^2)/length(error);  
end