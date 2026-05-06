opts.patchSize       = [512 512];
opts.patchesPerImage = 10;
opts.foregroundProb  = 0.5;
opts.rngSeed         = 42;
opts.verbose         = true;

% input_path = 'C:\Projects\CometAnalyser\SampleImages01_Fluorescent\SampleImages01_Fluorescent\SegmentationModel';
input_path = 'C:\Projects\CometAnalyser\SampleImages02_SilverStanined\SampleImages02_SilverStanined\SegmentationModel';

oldTrainingDataTransform(fullfile(input_path,'TrainingSet'), fullfile(input_path,'TrainingSet_new'))
preprocessPatchDataset(fullfile(input_path,'TrainingSet_new'),        fullfile(input_path,'TrainingSet_new_patches'),    opts);
