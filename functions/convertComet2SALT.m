function data = convertComet2SALT(app)
% AUTHOR:	Attila Beleon
% DATE: 	July 26, 2021
% NAME: 	convertComet2SALT
% 
% It converts the training set to be used with SALT.
%
% INPUT:
%   CommonHandles   TODO.
%
% OUTPUT:
%   data            Structure to run SALT.
%
% COPYRIGHT


% prepare data for SALT
data.name = app.ProjectName;
% number of instances
metaDataFile = app.metaDataPath;
t = readtable(metaDataFile);
classNames = setdiff(fields(app.comet_handles.Classes),'Unclassified');
% classNames = setdiff(t.CometClass,'Unclassified');
N = 0;
for i = 1:length(classNames)
    N = N + app.comet_handles.Classes.(classNames{i}).num_el;
end
% N = length(app.TrainingSet.Features);
% number of features
FS = size(t(1,8:end),2);
% number of classes
CS = length(classNames);
for f=1:FS
    data.featureName{f} = ['feature' num2str(f)];
    data.featureTypes{f} = 'NUMERIC';
end
for c=1:CS
    data.classNames{c} =  classNames{c};
end
k = 0;
for i=1:size(t,1)
    if find(strcmp(classNames, t.CometClass{i})) > 0
        k = k + 1;
        data.labels(k) = find(strcmp(classNames, t.CometClass{i}));
        data.instances(k,:) = t{i,8:end};
    end
end