%% PATHS
opts.patchPath           = 'C:\Projects\CometAnalyser\SampleImages02_SilverStanined\SampleImages02_SilverStanined\SegmentationModel\TrainingSet_new_patches';
opts.preTrainedModelPath = '';    % reserved for future warm-start; unused in k-fold expert training
opts.outputPath          = 'C:\Projects\CometAnalyser\SampleImages02_SilverStanined\SampleImages02_SilverStanined\SegmentationModel';

%% ARCHITECTURE
opts.encoderDepth        = 4;
opts.patchSize           = [512 512];

%% TRAINING
opts.maxEpochs           = 6;
opts.initialLR           = 1e-4;
opts.continueLR          = 1e-5;    % LR when resuming from existing model
opts.l2Reg               = 1e-4;
opts.miniBatchSize       = 8;
opts.diceWeight          = 0.7;
opts.ceWeight            = 0.3;
opts.gradientThresh      = 1.0;
opts.rngSeed             = 428;
opts.testFraction        = 0.15;
opts.validationPatience  = 6;
opts.averagingThreshold  = 0.05;    % selective weight averaging threshold
opts.continueFromRun     = fullfile(opts.outputPath, 'run_20260503_235055');  % path to previous run, empty = fresh start
% opts.continueFromRun  = '';       % uncomment for fresh start

% Use warmup only for fresh training, not continuation
if ~isempty(opts.continueFromRun)
    opts.useWarmup = false;
else
    opts.useWarmup = true;
end

%% AUGMENTATION                       % Default values
augOpts.xTrans           = [-30 30];  % [-30 30]
augOpts.yTrans           = [-30 30];  % [-30 30]
augOpts.rotVector        = [-90 90];  % [-90 90]
augOpts.scaleVector      = [0.8 1.2]; % [0.8 1.2]
augOpts.intensityRange   = [0.9 1.1]; % [0.7 1.5]
augOpts.gammaRange       = [0.9 1.1]; % [0.7 1.3]
augOpts.maxNoiseStd      = 0;    % set to 0 to disable - 0.02
augOpts.maxBlurSigma     = 0;     % set to 0 to disable - 1.5
augOpts.vignetteStrength = 0;     % set to 0 to disable - 0.3
augOpts.doFlip           = true;

opts.augParams = augOpts;

[bool, msg] = trainSemanticSegmentationModelExpert( ...
    opts.patchPath, ...
    opts.outputPath, ...
    opts);

% Save complete opts (including augParams) to the run directory.
% The training function creates the run dir internally, so we find it
% by picking the most recently modified run_* directory.
d = dir(fullfile(opts.outputPath, 'run_*'));
d = d([d.isdir]);
if ~isempty(d)
    [~, newest] = max([d.datenum]);
    runDir = fullfile(opts.outputPath, d(newest).name);
    save(fullfile(runDir, 'run_opts.mat'), 'opts');
    fprintf('Run parameters saved: %s\n', fullfile(runDir, 'run_opts.mat'));
end
