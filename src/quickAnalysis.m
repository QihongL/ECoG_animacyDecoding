%% Do some quick analysis for the Manchster ECoG data
% a single iteration of logistic regression with lasso or ridge penalty
clear variables; clc; close all;
% specify path information
% point to the project dir
% DIR.PROJECT = '/Users/Qihong/Dropbox/github/ECOG_Manchester';
% point to the directory for the data
DIR.DATA = '/Users/Qihong/Dropbox/github/ECOG_Manchester/data/ECoG/data/avg/BoxCar/010/WindowStart/0000/WindowSize/1000/';
% point to the output directory
DIR.OUT = '/Users/Qihong/Dropbox/github/ECOG_Manchester/results/';

% specify parameters
DATA_TYPE = 'raw'; % 'ref' OR 'raw'
CVCOL = 1;      % use the 1st column of cv idx for now
numCVB = 10;
options.nlambda = 100;

% get filenames and IDs for all subjects
[filename, subjIDs] = getFileNames(DIR.DATA, DATA_TYPE);
numSubjs = length(subjIDs); % number of subjects

for i = 1 : length(filename.data)
    fprintf(filename.data{i})
end

%% start the mvpa analysis
results = cell(numSubjs,1);
% loop over subjects
for i = 1 : numSubjs
    s = subjIDs(i);
    % preallocate: results{i} for the ith subject
    results{i}.subjID = s;
    results{i}.dataType = DATA_TYPE;
    results{i}.lasso.accuracy.onese = nan(numCVB,1);
    results{i}.lasso.accuracy.min = nan(numCVB,1);
    results{i}.ridge.accuracy.onese = nan(numCVB,1);
    results{i}.ridge.accuracy.min = nan(numCVB,1);
    
    % load the data
    load(strcat(DIR.DATA,filename.metadata))
    load(strcat(DIR.DATA,filename.data{i}))
    y = metadata(s).targets(1).target;  % target 1 = label
    [M,N] = size(X);
    % read data parameters
    cvidx = metadata(s).cvind(:,CVCOL);
    
    % loop over CV blocks
    for c = 1: numCVB
        % choose a cv index
        testIdx = cvidx == c;
        % hold out the test set
        X_train = X(~testIdx,:);
        X_test = X(testIdx,:);
        y_train = y(~testIdx);
        y_test = y(testIdx);
        
        % fit lasso
        options.alpha = 1; % 1 == lasso, 0 == ridge
        cvfit = cvglmnet(X_train, y_train, 'binomial', options);
        results{i}.lasso.coef_1se = cvglmnetCoef(cvfit, 'lambda_1se');
        results{i}.lasso.lambda_1se = cvfit.lambda_1se;
        results{i}.lasso.coef_min = cvglmnetCoef(cvfit, 'lambda_min');
        results{i}.lasso.lambda_min = cvfit.lambda_min;
        
        % compute the performance
        y_hat = myStepFunction(cvglmnetPredict(cvfit, X_test,cvfit.lambda_1se));
        results{i}.lasso.accuracy.onese(c) = sum(y_hat == y_test) / length(y_test);
        y_hat = myStepFunction(cvglmnetPredict(cvfit, X_test,cvfit.lambda_min));
        results{i}.lasso.accuracy.min(c) = sum(y_hat == y_test) / length(y_test);
        
        % fit ridge
        options.alpha = 0; % 1 == lasso, 0 == ridge
        cvfit = cvglmnet(X_train, y_train, 'binomial', options);
        results{i}.ridge.coef_1se = cvglmnetCoef(cvfit, 'lambda_1se');
        results{i}.ridge.lambda_1se = cvfit.lambda_1se;
        results{i}.ridge.coef_min = cvglmnetCoef(cvfit, 'lambda_min');
        results{i}.ridge.lambda_min = cvfit.lambda_min;
        
        % compute the performance
        y_hat = myStepFunction(cvglmnetPredict(cvfit, X_test,cvfit.lambda_1se));
        results{i}.ridge.accuracy.onese(c) = sum(y_hat == y_test) / length(y_test);
        y_hat = myStepFunction(cvglmnetPredict(cvfit, X_test,cvfit.lambda_min));
        results{i}.ridge.accuracy.min(c) = sum(y_hat == y_test) / length(y_test);
        
    end
    
end
% save the data
saveFileName = sprintf( strcat('results_', DATA_TYPE, '.mat'));
save(strcat(DIR.OUT,saveFileName), 'results')