%----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
% BootstrapOLS.m                                            yyyy-mm-dd:2020-02-14
%
%--------------------------------------------------------------------------------
% This script runs a bootstrap procedure for OLS standard errors based on the 
% auto.csv file

clear

%%Read in data
DataIn  = dlmread('auto.csv');
X       = DataIn(:, 2:3);
X       = [X, ones(74, 1)];
y       = DataIn(:, 1);


%%Estimate and store coefficients and analytical standard errors
[beta]  = regress(y, X);


%%Set bootstrap replications, set seed for replicability, and pre-fill matrices
reps          = 10000;
rng(13032019)
BootstrapBeta = NaN(reps, 3);

%%Estimate each bootstrap resample
tic
for count = 1:reps
    MyIndex     = round(rand(74, 1) * 74 + 0.5);     
    BootstrapX  = X(MyIndex, :);
    BootstrapY  = y(MyIndex, :);
    
    BootstrapBeta(count, :)     = [regress(BootstrapY, BootstrapX)]';
end
toc

[beta, mean(BootstrapBeta)', std(BootstrapBeta)']


% bootstrap, reps(10000): reg mpg price weight, noheader

return
