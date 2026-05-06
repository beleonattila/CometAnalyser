function oldTrainingDataTransform(inputPath, outputPath)
% AUTHOR: Attila Beleon
% DATE: April 28, 2026
% NAME: oldTrainingDataTransform
%
% INPUT:
%   inputPath   Path to folder containing PNG images (with Images/Masks subfolders)
%   outputPath  Path to folder where converted images will be saved
%
% OUTPUT:
%   Grayscale single-precision TIFF images written to outputPath/Images
%   Masks copied as-is to outputPath/Masks

if ~exist(fullfile(outputPath, 'Images'), 'dir')
    mkdir(fullfile(outputPath, 'Images'));
end

files = dir(fullfile(inputPath, 'Images', '*.png'));

if isempty(files)
    warning('No PNG files found in: %s', fullfile(inputPath, 'Images'));
    return
end

for i = 1:numel(files)
    imgPath = fullfile(files(i).folder, files(i).name);
    img = imread(imgPath);
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2single(img);

    [~, name, ~] = fileparts(files(i).name);
    outPath = fullfile(outputPath, 'Images', [name, '.tif']);

    t = Tiff(outPath, 'w');
    t.setTag('Photometric',         Tiff.Photometric.MinIsBlack);
    t.setTag('ImageLength',         size(img, 1));
    t.setTag('ImageWidth',          size(img, 2));
    t.setTag('BitsPerSample',       32);
    t.setTag('SampleFormat',        Tiff.SampleFormat.IEEEFP);
    t.setTag('SamplesPerPixel',     1);
    t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    t.write(img);
    t.close();

    fprintf('Processed %d/%d: %s\n', i, numel(files), files(i).name);
end

copyfile(fullfile(inputPath, 'Masks'), fullfile(outputPath, 'Masks'))
fprintf('Done. %d images written to: %s\n', numel(files), outputPath);
end