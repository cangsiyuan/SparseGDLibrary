function [] = test_lasso_cv()

    clc;
    clear;
    close all;
    
    
    %% prepare dataset
    n = 1280; 
    d = 100; 
    k = 5; 
    noise_level = 0.01;
    [A, b, ~, ~, lambda_max] = generate_lasso_data(n, d, k, noise_level);      


    %% set only ONE algorithm
    % select from {'ADMM-LASSO','FISTA','PG-TFOCS-BKT','APG-TFOCS-BKT','CD-LASSO'}
    algorithm = {'FISTA'};

    switch algorithm{1}
        case {'PG-TFOCS-BKT'}

            options.step_alg = 'tfocs_backtracking';
            options.step_init_alg = 'bb_init';
            solver = @gd;     

        case {'APG-TFOCS-BKT'}

            options.step_alg = 'tfocs_backtracking';
            options.step_init_alg = 'bb_init';
            solver = @gd_nesterov; 

        case {'FISTA'}

            solver = @fista;

        case {'ADMM-LASSO'}

            options.rho = 0.1;
            solver = @admm_lasso;    

        case {'CD-LASSO'}

            options.sub_mode = 'lasso';
            solver = @cd_lasso_elasticnet;                   

        otherwise
            warn_str = [algorithm{1}, ' is not supported.'];
            warning(warn_str);
    end

    
    %% initialize
    % define parameters for cross-validation
    num_lambda = 10;
    lamda_unit = lambda_max/num_lambda;
    lamnda_array = 0+lamda_unit:lamda_unit:lambda_max;
    len = length(lamnda_array);
    
    % set options
    clear options;
    options.tol_gnorm = 1e-10;
    options.max_iter = 100;
    options.verbose = true;  
    options.w_init = zeros(n,1);    
    
    % prepare arrays for solutions
    W = zeros(n, num_lambda);
    l1_norm = zeros(num_lambda,1);    
    aprox_err = zeros(num_lambda,1);  
    
    
    %% perform cross-validations
    for i=1:len
        lambda = lamnda_array(i);
        problem = lasso_problem(A, b, lambda);
        
        [W(:,i), infos] = solver(problem, options);
        l1_norm(i) = infos.reg(end);
        aprox_err(i) = infos.cost(end);
    end
    

    %% plot all
    % display l1-norm vs coefficient
    display_graph('l1-norm','coeffs', algorithm, l1_norm, {W}, 'linear');
    % display lambda vs coefficient
    display_graph('lambda','coeffs', algorithm, lamnda_array, {W}, 'linear');
    % display l1-norm vs approximation error
    display_graph('l1-norm','aprox_err', algorithm, l1_norm, {aprox_err}, 'linear');    
    
end




