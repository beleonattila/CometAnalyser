function lgraph = loadPretrainedCometNetwrok(path)

params = load(path);

lgraph = layerGraph();

tempLayers = imageInputLayer([1024 1280 3],"Name","input_1","Normalization","rescale-symmetric","Max",params.input_1.Max,"Min",params.input_1.Min);
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],32,"Name","block1_conv1","BiasLearnRateFactor",0,"Padding","same","Stride",[2 2],"Bias",params.block1_conv1.Bias,"Weights",params.block1_conv1.Weights)
    batchNormalizationLayer("Name","block1_conv1_bn","Epsilon",0.001,"Offset",params.block1_conv1_bn.Offset,"Scale",params.block1_conv1_bn.Scale,"TrainedMean",params.block1_conv1_bn.TrainedMean,"TrainedVariance",params.block1_conv1_bn.TrainedVariance)
    reluLayer("Name","block1_conv1_act")
    convolution2dLayer([3 3],64,"Name","block1_conv2","BiasLearnRateFactor",0,"Padding","same","Bias",params.block1_conv2.Bias,"Weights",params.block1_conv2.Weights)
    batchNormalizationLayer("Name","block1_conv2_bn","Epsilon",0.001,"Offset",params.block1_conv2_bn.Offset,"Scale",params.block1_conv2_bn.Scale,"TrainedMean",params.block1_conv2_bn.TrainedMean,"TrainedVariance",params.block1_conv2_bn.TrainedVariance)
    reluLayer("Name","block1_conv2_act")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    groupedConvolution2dLayer([3 3],1,64,"Name","block2_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block2_sepconv1_channel_wise.Bias,"Weights",params.block2_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],128,"Name","block2_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block2_sepconv1_point_wise.Bias,"Weights",params.block2_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block2_sepconv1_bn","Epsilon",0.001,"Offset",params.block2_sepconv1_bn.Offset,"Scale",params.block2_sepconv1_bn.Scale,"TrainedMean",params.block2_sepconv1_bn.TrainedMean,"TrainedVariance",params.block2_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block2_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,128,"Name","block2_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block2_sepconv2_channel_wise.Bias,"Weights",params.block2_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],128,"Name","block2_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block2_sepconv2_point_wise.Bias,"Weights",params.block2_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block2_sepconv2_bn","Epsilon",0.001,"Offset",params.block2_sepconv2_bn.Offset,"Scale",params.block2_sepconv2_bn.Scale,"TrainedMean",params.block2_sepconv2_bn.TrainedMean,"TrainedVariance",params.block2_sepconv2_bn.TrainedVariance)
    maxPooling2dLayer([3 3],"Name","block2_pool","Padding","same","Stride",[2 2])];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],128,"Name","conv2d_1","BiasLearnRateFactor",0,"Padding","same","Stride",[2 2],"Bias",params.conv2d_1.Bias,"Weights",params.conv2d_1.Weights)
    batchNormalizationLayer("Name","batch_normalization_1","Epsilon",0.001,"Offset",params.batch_normalization_1.Offset,"Scale",params.batch_normalization_1.Scale,"TrainedMean",params.batch_normalization_1.TrainedMean,"TrainedVariance",params.batch_normalization_1.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_1");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block3_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,128,"Name","block3_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block3_sepconv1_channel_wise.Bias,"Weights",params.block3_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],256,"Name","block3_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block3_sepconv1_point_wise.Bias,"Weights",params.block3_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block3_sepconv1_bn","Epsilon",0.001,"Offset",params.block3_sepconv1_bn.Offset,"Scale",params.block3_sepconv1_bn.Scale,"TrainedMean",params.block3_sepconv1_bn.TrainedMean,"TrainedVariance",params.block3_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block3_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,256,"Name","block3_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block3_sepconv2_channel_wise.Bias,"Weights",params.block3_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],256,"Name","block3_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block3_sepconv2_point_wise.Bias,"Weights",params.block3_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block3_sepconv2_bn","Epsilon",0.001,"Offset",params.block3_sepconv2_bn.Offset,"Scale",params.block3_sepconv2_bn.Scale,"TrainedMean",params.block3_sepconv2_bn.TrainedMean,"TrainedVariance",params.block3_sepconv2_bn.TrainedVariance)
    maxPooling2dLayer([3 3],"Name","block3_pool","Padding","same","Stride",[2 2])];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],48,"Name","dec_c2","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.dec_c2.Bias,"Weights",params.dec_c2.Weights)
    batchNormalizationLayer("Name","dec_bn2","Offset",params.dec_bn2.Offset,"Scale",params.dec_bn2.Scale,"TrainedMean",params.dec_bn2.TrainedMean,"TrainedVariance",params.dec_bn2.TrainedVariance)
    reluLayer("Name","dec_relu2")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],256,"Name","conv2d_2","BiasLearnRateFactor",0,"Padding","same","Stride",[2 2],"Bias",params.conv2d_2.Bias,"Weights",params.conv2d_2.Weights)
    batchNormalizationLayer("Name","batch_normalization_2","Epsilon",0.001,"Offset",params.batch_normalization_2.Offset,"Scale",params.batch_normalization_2.Scale,"TrainedMean",params.batch_normalization_2.TrainedMean,"TrainedVariance",params.batch_normalization_2.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_2");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block4_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,256,"Name","block4_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block4_sepconv1_channel_wise.Bias,"Weights",params.block4_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block4_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block4_sepconv1_point_wise.Bias,"Weights",params.block4_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block4_sepconv1_bn","Epsilon",0.001,"Offset",params.block4_sepconv1_bn.Offset,"Scale",params.block4_sepconv1_bn.Scale,"TrainedMean",params.block4_sepconv1_bn.TrainedMean,"TrainedVariance",params.block4_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block4_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block4_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block4_sepconv2_channel_wise.Bias,"Weights",params.block4_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block4_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block4_sepconv2_point_wise.Bias,"Weights",params.block4_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block4_sepconv2_bn","Epsilon",0.001,"Offset",params.block4_sepconv2_bn.Offset,"Scale",params.block4_sepconv2_bn.Scale,"TrainedMean",params.block4_sepconv2_bn.TrainedMean,"TrainedVariance",params.block4_sepconv2_bn.TrainedVariance)
    maxPooling2dLayer([3 3],"Name","block4_pool","Padding","same","Stride",[2 2])];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],728,"Name","conv2d_3","BiasLearnRateFactor",0,"Padding","same","Stride",[2 2],"Bias",params.conv2d_3.Bias,"Weights",params.conv2d_3.Weights)
    batchNormalizationLayer("Name","batch_normalization_3","Epsilon",0.001,"Offset",params.batch_normalization_3.Offset,"Scale",params.batch_normalization_3.Scale,"TrainedMean",params.batch_normalization_3.TrainedMean,"TrainedVariance",params.batch_normalization_3.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_3");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block5_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block5_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block5_sepconv1_channel_wise.Bias,"Weights",params.block5_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block5_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block5_sepconv1_point_wise.Bias,"Weights",params.block5_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block5_sepconv1_bn","Epsilon",0.001,"Offset",params.block5_sepconv1_bn.Offset,"Scale",params.block5_sepconv1_bn.Scale,"TrainedMean",params.block5_sepconv1_bn.TrainedMean,"TrainedVariance",params.block5_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block5_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block5_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block5_sepconv2_channel_wise.Bias,"Weights",params.block5_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block5_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block5_sepconv2_point_wise.Bias,"Weights",params.block5_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block5_sepconv2_bn","Epsilon",0.001,"Offset",params.block5_sepconv2_bn.Offset,"Scale",params.block5_sepconv2_bn.Scale,"TrainedMean",params.block5_sepconv2_bn.TrainedMean,"TrainedVariance",params.block5_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block5_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block5_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block5_sepconv3_channel_wise.Bias,"Weights",params.block5_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block5_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block5_sepconv3_point_wise.Bias,"Weights",params.block5_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block5_sepconv3_bn","Epsilon",0.001,"Offset",params.block5_sepconv3_bn.Offset,"Scale",params.block5_sepconv3_bn.Scale,"TrainedMean",params.block5_sepconv3_bn.TrainedMean,"TrainedVariance",params.block5_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_4");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block6_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block6_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block6_sepconv1_channel_wise.Bias,"Weights",params.block6_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block6_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block6_sepconv1_point_wise.Bias,"Weights",params.block6_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block6_sepconv1_bn","Epsilon",0.001,"Offset",params.block6_sepconv1_bn.Offset,"Scale",params.block6_sepconv1_bn.Scale,"TrainedMean",params.block6_sepconv1_bn.TrainedMean,"TrainedVariance",params.block6_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block6_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block6_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block6_sepconv2_channel_wise.Bias,"Weights",params.block6_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block6_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block6_sepconv2_point_wise.Bias,"Weights",params.block6_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block6_sepconv2_bn","Epsilon",0.001,"Offset",params.block6_sepconv2_bn.Offset,"Scale",params.block6_sepconv2_bn.Scale,"TrainedMean",params.block6_sepconv2_bn.TrainedMean,"TrainedVariance",params.block6_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block6_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block6_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block6_sepconv3_channel_wise.Bias,"Weights",params.block6_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block6_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block6_sepconv3_point_wise.Bias,"Weights",params.block6_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block6_sepconv3_bn","Epsilon",0.001,"Offset",params.block6_sepconv3_bn.Offset,"Scale",params.block6_sepconv3_bn.Scale,"TrainedMean",params.block6_sepconv3_bn.TrainedMean,"TrainedVariance",params.block6_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_5");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block7_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block7_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block7_sepconv1_channel_wise.Bias,"Weights",params.block7_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block7_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block7_sepconv1_point_wise.Bias,"Weights",params.block7_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block7_sepconv1_bn","Epsilon",0.001,"Offset",params.block7_sepconv1_bn.Offset,"Scale",params.block7_sepconv1_bn.Scale,"TrainedMean",params.block7_sepconv1_bn.TrainedMean,"TrainedVariance",params.block7_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block7_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block7_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block7_sepconv2_channel_wise.Bias,"Weights",params.block7_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block7_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block7_sepconv2_point_wise.Bias,"Weights",params.block7_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block7_sepconv2_bn","Epsilon",0.001,"Offset",params.block7_sepconv2_bn.Offset,"Scale",params.block7_sepconv2_bn.Scale,"TrainedMean",params.block7_sepconv2_bn.TrainedMean,"TrainedVariance",params.block7_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block7_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block7_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block7_sepconv3_channel_wise.Bias,"Weights",params.block7_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block7_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block7_sepconv3_point_wise.Bias,"Weights",params.block7_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block7_sepconv3_bn","Epsilon",0.001,"Offset",params.block7_sepconv3_bn.Offset,"Scale",params.block7_sepconv3_bn.Scale,"TrainedMean",params.block7_sepconv3_bn.TrainedMean,"TrainedVariance",params.block7_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_6");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block8_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block8_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block8_sepconv1_channel_wise.Bias,"Weights",params.block8_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block8_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block8_sepconv1_point_wise.Bias,"Weights",params.block8_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block8_sepconv1_bn","Epsilon",0.001,"Offset",params.block8_sepconv1_bn.Offset,"Scale",params.block8_sepconv1_bn.Scale,"TrainedMean",params.block8_sepconv1_bn.TrainedMean,"TrainedVariance",params.block8_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block8_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block8_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block8_sepconv2_channel_wise.Bias,"Weights",params.block8_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block8_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block8_sepconv2_point_wise.Bias,"Weights",params.block8_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block8_sepconv2_bn","Epsilon",0.001,"Offset",params.block8_sepconv2_bn.Offset,"Scale",params.block8_sepconv2_bn.Scale,"TrainedMean",params.block8_sepconv2_bn.TrainedMean,"TrainedVariance",params.block8_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block8_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block8_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block8_sepconv3_channel_wise.Bias,"Weights",params.block8_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block8_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block8_sepconv3_point_wise.Bias,"Weights",params.block8_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block8_sepconv3_bn","Epsilon",0.001,"Offset",params.block8_sepconv3_bn.Offset,"Scale",params.block8_sepconv3_bn.Scale,"TrainedMean",params.block8_sepconv3_bn.TrainedMean,"TrainedVariance",params.block8_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_7");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block9_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block9_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block9_sepconv1_channel_wise.Bias,"Weights",params.block9_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block9_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block9_sepconv1_point_wise.Bias,"Weights",params.block9_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block9_sepconv1_bn","Epsilon",0.001,"Offset",params.block9_sepconv1_bn.Offset,"Scale",params.block9_sepconv1_bn.Scale,"TrainedMean",params.block9_sepconv1_bn.TrainedMean,"TrainedVariance",params.block9_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block9_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block9_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block9_sepconv2_channel_wise.Bias,"Weights",params.block9_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block9_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block9_sepconv2_point_wise.Bias,"Weights",params.block9_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block9_sepconv2_bn","Epsilon",0.001,"Offset",params.block9_sepconv2_bn.Offset,"Scale",params.block9_sepconv2_bn.Scale,"TrainedMean",params.block9_sepconv2_bn.TrainedMean,"TrainedVariance",params.block9_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block9_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block9_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block9_sepconv3_channel_wise.Bias,"Weights",params.block9_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block9_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block9_sepconv3_point_wise.Bias,"Weights",params.block9_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block9_sepconv3_bn","Epsilon",0.001,"Offset",params.block9_sepconv3_bn.Offset,"Scale",params.block9_sepconv3_bn.Scale,"TrainedMean",params.block9_sepconv3_bn.TrainedMean,"TrainedVariance",params.block9_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_8");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block10_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block10_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block10_sepconv1_channel_wise.Bias,"Weights",params.block10_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block10_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block10_sepconv1_point_wise.Bias,"Weights",params.block10_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block10_sepconv1_bn","Epsilon",0.001,"Offset",params.block10_sepconv1_bn.Offset,"Scale",params.block10_sepconv1_bn.Scale,"TrainedMean",params.block10_sepconv1_bn.TrainedMean,"TrainedVariance",params.block10_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block10_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block10_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block10_sepconv2_channel_wise.Bias,"Weights",params.block10_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block10_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block10_sepconv2_point_wise.Bias,"Weights",params.block10_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block10_sepconv2_bn","Epsilon",0.001,"Offset",params.block10_sepconv2_bn.Offset,"Scale",params.block10_sepconv2_bn.Scale,"TrainedMean",params.block10_sepconv2_bn.TrainedMean,"TrainedVariance",params.block10_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block10_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block10_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block10_sepconv3_channel_wise.Bias,"Weights",params.block10_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block10_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block10_sepconv3_point_wise.Bias,"Weights",params.block10_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block10_sepconv3_bn","Epsilon",0.001,"Offset",params.block10_sepconv3_bn.Offset,"Scale",params.block10_sepconv3_bn.Scale,"TrainedMean",params.block10_sepconv3_bn.TrainedMean,"TrainedVariance",params.block10_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_9");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block11_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block11_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block11_sepconv1_channel_wise.Bias,"Weights",params.block11_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block11_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block11_sepconv1_point_wise.Bias,"Weights",params.block11_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block11_sepconv1_bn","Epsilon",0.001,"Offset",params.block11_sepconv1_bn.Offset,"Scale",params.block11_sepconv1_bn.Scale,"TrainedMean",params.block11_sepconv1_bn.TrainedMean,"TrainedVariance",params.block11_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block11_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block11_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block11_sepconv2_channel_wise.Bias,"Weights",params.block11_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block11_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block11_sepconv2_point_wise.Bias,"Weights",params.block11_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block11_sepconv2_bn","Epsilon",0.001,"Offset",params.block11_sepconv2_bn.Offset,"Scale",params.block11_sepconv2_bn.Scale,"TrainedMean",params.block11_sepconv2_bn.TrainedMean,"TrainedVariance",params.block11_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block11_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block11_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block11_sepconv3_channel_wise.Bias,"Weights",params.block11_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block11_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block11_sepconv3_point_wise.Bias,"Weights",params.block11_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block11_sepconv3_bn","Epsilon",0.001,"Offset",params.block11_sepconv3_bn.Offset,"Scale",params.block11_sepconv3_bn.Scale,"TrainedMean",params.block11_sepconv3_bn.TrainedMean,"TrainedVariance",params.block11_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_10");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block12_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block12_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block12_sepconv1_channel_wise.Bias,"Weights",params.block12_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block12_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block12_sepconv1_point_wise.Bias,"Weights",params.block12_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block12_sepconv1_bn","Epsilon",0.001,"Offset",params.block12_sepconv1_bn.Offset,"Scale",params.block12_sepconv1_bn.Scale,"TrainedMean",params.block12_sepconv1_bn.TrainedMean,"TrainedVariance",params.block12_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block12_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block12_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block12_sepconv2_channel_wise.Bias,"Weights",params.block12_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block12_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block12_sepconv2_point_wise.Bias,"Weights",params.block12_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block12_sepconv2_bn","Epsilon",0.001,"Offset",params.block12_sepconv2_bn.Offset,"Scale",params.block12_sepconv2_bn.Scale,"TrainedMean",params.block12_sepconv2_bn.TrainedMean,"TrainedVariance",params.block12_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block12_sepconv3_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block12_sepconv3_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block12_sepconv3_channel_wise.Bias,"Weights",params.block12_sepconv3_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block12_sepconv3_point-wise","BiasLearnRateFactor",0,"Bias",params.block12_sepconv3_point_wise.Bias,"Weights",params.block12_sepconv3_point_wise.Weights)
    batchNormalizationLayer("Name","block12_sepconv3_bn","Epsilon",0.001,"Offset",params.block12_sepconv3_bn.Offset,"Scale",params.block12_sepconv3_bn.Scale,"TrainedMean",params.block12_sepconv3_bn.TrainedMean,"TrainedVariance",params.block12_sepconv3_bn.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = additionLayer(2,"Name","add_11");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    reluLayer("Name","block13_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block13_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block13_sepconv1_channel_wise.Bias,"Weights",params.block13_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],728,"Name","block13_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block13_sepconv1_point_wise.Bias,"Weights",params.block13_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block13_sepconv1_bn","Epsilon",0.001,"Offset",params.block13_sepconv1_bn.Offset,"Scale",params.block13_sepconv1_bn.Scale,"TrainedMean",params.block13_sepconv1_bn.TrainedMean,"TrainedVariance",params.block13_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block13_sepconv2_act")
    groupedConvolution2dLayer([3 3],1,728,"Name","block13_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block13_sepconv2_channel_wise.Bias,"Weights",params.block13_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],1024,"Name","block13_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block13_sepconv2_point_wise.Bias,"Weights",params.block13_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block13_sepconv2_bn","Epsilon",0.001,"Offset",params.block13_sepconv2_bn.Offset,"Scale",params.block13_sepconv2_bn.Scale,"TrainedMean",params.block13_sepconv2_bn.TrainedMean,"TrainedVariance",params.block13_sepconv2_bn.TrainedVariance)
    maxPooling2dLayer([3 3],"Name","block13_pool","Padding","same")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],1024,"Name","conv2d_4","BiasLearnRateFactor",0,"Bias",params.conv2d_4.Bias,"Weights",params.conv2d_4.Weights)
    batchNormalizationLayer("Name","batch_normalization_4","Epsilon",0.001,"Offset",params.batch_normalization_4.Offset,"Scale",params.batch_normalization_4.Scale,"TrainedMean",params.batch_normalization_4.TrainedMean,"TrainedVariance",params.batch_normalization_4.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","add_12")
    groupedConvolution2dLayer([3 3],1,1024,"Name","block14_sepconv1_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block14_sepconv1_channel_wise.Bias,"Weights",params.block14_sepconv1_channel_wise.Weights)
    convolution2dLayer([1 1],1536,"Name","block14_sepconv1_point-wise","BiasLearnRateFactor",0,"Bias",params.block14_sepconv1_point_wise.Bias,"Weights",params.block14_sepconv1_point_wise.Weights)
    batchNormalizationLayer("Name","block14_sepconv1_bn","Epsilon",0.001,"Offset",params.block14_sepconv1_bn.Offset,"Scale",params.block14_sepconv1_bn.Scale,"TrainedMean",params.block14_sepconv1_bn.TrainedMean,"TrainedVariance",params.block14_sepconv1_bn.TrainedVariance)
    reluLayer("Name","block14_sepconv1_act")
    groupedConvolution2dLayer([3 3],1,1536,"Name","block14_sepconv2_channel-wise","BiasLearnRateFactor",0,"Padding","same","Bias",params.block14_sepconv2_channel_wise.Bias,"Weights",params.block14_sepconv2_channel_wise.Weights)
    convolution2dLayer([1 1],2048,"Name","block14_sepconv2_point-wise","BiasLearnRateFactor",0,"Bias",params.block14_sepconv2_point_wise.Bias,"Weights",params.block14_sepconv2_point_wise.Weights)
    batchNormalizationLayer("Name","block14_sepconv2_bn","Epsilon",0.001,"Offset",params.block14_sepconv2_bn.Offset,"Scale",params.block14_sepconv2_bn.Scale,"TrainedMean",params.block14_sepconv2_bn.TrainedMean,"TrainedVariance",params.block14_sepconv2_bn.TrainedVariance)
    reluLayer("Name","block14_sepconv2_act")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    groupedConvolution2dLayer([3 3],1,2048,"Name","aspp_Conv_4_depthwise","BiasLearnRateFactor",0,"DilationFactor",[18 18],"Padding","same","WeightLearnRateFactor",10,"Bias",params.aspp_Conv_4_depthwise.Bias,"Weights",params.aspp_Conv_4_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","aspp_Conv_4_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.aspp_Conv_4_pointwise.Bias,"Weights",params.aspp_Conv_4_pointwise.Weights)
    batchNormalizationLayer("Name","aspp_BatchNorm_4","Offset",params.aspp_BatchNorm_4.Offset,"Scale",params.aspp_BatchNorm_4.Scale,"TrainedMean",params.aspp_BatchNorm_4.TrainedMean,"TrainedVariance",params.aspp_BatchNorm_4.TrainedVariance)
    reluLayer("Name","aspp_Relu_4")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    groupedConvolution2dLayer([3 3],1,2048,"Name","aspp_Conv_3_depthwise","BiasLearnRateFactor",0,"DilationFactor",[12 12],"Padding","same","WeightLearnRateFactor",10,"Bias",params.aspp_Conv_3_depthwise.Bias,"Weights",params.aspp_Conv_3_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","aspp_Conv_3_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.aspp_Conv_3_pointwise.Bias,"Weights",params.aspp_Conv_3_pointwise.Weights)
    batchNormalizationLayer("Name","aspp_BatchNorm_3","Offset",params.aspp_BatchNorm_3.Offset,"Scale",params.aspp_BatchNorm_3.Scale,"TrainedMean",params.aspp_BatchNorm_3.TrainedMean,"TrainedVariance",params.aspp_BatchNorm_3.TrainedVariance)
    reluLayer("Name","aspp_Relu_3")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    groupedConvolution2dLayer([1 1],1,2048,"Name","aspp_Conv_1_depthwise","BiasLearnRateFactor",0,"Padding","same","WeightLearnRateFactor",10,"Bias",params.aspp_Conv_1_depthwise.Bias,"Weights",params.aspp_Conv_1_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","aspp_Conv_1_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.aspp_Conv_1_pointwise.Bias,"Weights",params.aspp_Conv_1_pointwise.Weights)
    batchNormalizationLayer("Name","aspp_BatchNorm_1","Offset",params.aspp_BatchNorm_1.Offset,"Scale",params.aspp_BatchNorm_1.Scale,"TrainedMean",params.aspp_BatchNorm_1.TrainedMean,"TrainedVariance",params.aspp_BatchNorm_1.TrainedVariance)
    reluLayer("Name","aspp_Relu_1")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    groupedConvolution2dLayer([3 3],1,2048,"Name","aspp_Conv_2_depthwise","BiasLearnRateFactor",0,"DilationFactor",[6 6],"Padding","same","WeightLearnRateFactor",10,"Bias",params.aspp_Conv_2_depthwise.Bias,"Weights",params.aspp_Conv_2_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","aspp_Conv_2_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.aspp_Conv_2_pointwise.Bias,"Weights",params.aspp_Conv_2_pointwise.Weights)
    batchNormalizationLayer("Name","aspp_BatchNorm_2","Offset",params.aspp_BatchNorm_2.Offset,"Scale",params.aspp_BatchNorm_2.Scale,"TrainedMean",params.aspp_BatchNorm_2.TrainedMean,"TrainedVariance",params.aspp_BatchNorm_2.TrainedVariance)
    reluLayer("Name","aspp_Relu_2")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    depthConcatenationLayer(4,"Name","catAspp")
    convolution2dLayer([1 1],256,"Name","dec_c1","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.dec_c1.Bias,"Weights",params.dec_c1.Weights)
    batchNormalizationLayer("Name","dec_bn1","Offset",params.dec_bn1.Offset,"Scale",params.dec_bn1.Scale,"TrainedMean",params.dec_bn1.TrainedMean,"TrainedVariance",params.dec_bn1.TrainedVariance)
    reluLayer("Name","dec_relu1")
    transposedConv2dLayer([8 8],256,"Name","dec_upsample1","BiasLearnRateFactor",0,"Cropping",[2 2 2 2],"Stride",[4 4],"WeightLearnRateFactor",0,"Bias",params.dec_upsample1.Bias,"Weights",params.dec_upsample1.Weights)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = crop2dLayer("centercrop","Name","dec_crop1");
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    depthConcatenationLayer(2,"Name","dec_cat1")
    groupedConvolution2dLayer([3 3],1,304,"Name","dec_c3_depthwise","BiasLearnRateFactor",0,"Padding","same","WeightLearnRateFactor",10,"Bias",params.dec_c3_depthwise.Bias,"Weights",params.dec_c3_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","dec_c3_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.dec_c3_pointwise.Bias,"Weights",params.dec_c3_pointwise.Weights)
    batchNormalizationLayer("Name","dec_bn3","Offset",params.dec_bn3.Offset,"Scale",params.dec_bn3.Scale,"TrainedMean",params.dec_bn3.TrainedMean,"TrainedVariance",params.dec_bn3.TrainedVariance)
    reluLayer("Name","dec_relu3")
    groupedConvolution2dLayer([3 3],1,256,"Name","dec_c4_depthwise","BiasLearnRateFactor",0,"Padding","same","WeightLearnRateFactor",10,"Bias",params.dec_c4_depthwise.Bias,"Weights",params.dec_c4_depthwise.Weights)
    convolution2dLayer([1 1],256,"Name","dec_c4_pointwise","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.dec_c4_pointwise.Bias,"Weights",params.dec_c4_pointwise.Weights)
    batchNormalizationLayer("Name","dec_bn4","Offset",params.dec_bn4.Offset,"Scale",params.dec_bn4.Scale,"TrainedMean",params.dec_bn4.TrainedMean,"TrainedVariance",params.dec_bn4.TrainedVariance)
    reluLayer("Name","dec_relu4")
    convolution2dLayer([1 1],3,"Name","scorer","BiasLearnRateFactor",0,"WeightLearnRateFactor",10,"Bias",params.scorer.Bias,"Weights",params.scorer.Weights)
    transposedConv2dLayer([8 8],3,"Name","dec_upsample2","BiasLearnRateFactor",0,"Cropping",[2 2 2 2],"Stride",[4 4],"WeightLearnRateFactor",0,"Bias",params.dec_upsample2.Bias,"Weights",params.dec_upsample2.Weights)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    crop2dLayer("centercrop","Name","dec_crop2")
    softmaxLayer("Name","softmax-out")
    pixelClassificationLayer("Name","labels","ClassWeights",params.labels.ClassWeights,"Classes",params.labels.Classes)];
lgraph = addLayers(lgraph,tempLayers);

% clean up helper variable
clear tempLayers;

lgraph = connectLayers(lgraph,"input_1","block1_conv1");
lgraph = connectLayers(lgraph,"input_1","dec_crop2/ref");
lgraph = connectLayers(lgraph,"block1_conv2_act","block2_sepconv1_channel-wise");
lgraph = connectLayers(lgraph,"block1_conv2_act","conv2d_1");
lgraph = connectLayers(lgraph,"batch_normalization_1","add_1/in2");
lgraph = connectLayers(lgraph,"block2_pool","add_1/in1");
lgraph = connectLayers(lgraph,"add_1","block3_sepconv1_act");
lgraph = connectLayers(lgraph,"add_1","dec_c2");
lgraph = connectLayers(lgraph,"add_1","conv2d_2");
lgraph = connectLayers(lgraph,"dec_relu2","dec_crop1/ref");
lgraph = connectLayers(lgraph,"dec_relu2","dec_cat1/in1");
lgraph = connectLayers(lgraph,"batch_normalization_2","add_2/in2");
lgraph = connectLayers(lgraph,"block3_pool","add_2/in1");
lgraph = connectLayers(lgraph,"add_2","block4_sepconv1_act");
lgraph = connectLayers(lgraph,"add_2","conv2d_3");
lgraph = connectLayers(lgraph,"batch_normalization_3","add_3/in2");
lgraph = connectLayers(lgraph,"block4_pool","add_3/in1");
lgraph = connectLayers(lgraph,"add_3","block5_sepconv1_act");
lgraph = connectLayers(lgraph,"add_3","add_4/in2");
lgraph = connectLayers(lgraph,"block5_sepconv3_bn","add_4/in1");
lgraph = connectLayers(lgraph,"add_4","block6_sepconv1_act");
lgraph = connectLayers(lgraph,"add_4","add_5/in2");
lgraph = connectLayers(lgraph,"block6_sepconv3_bn","add_5/in1");
lgraph = connectLayers(lgraph,"add_5","block7_sepconv1_act");
lgraph = connectLayers(lgraph,"add_5","add_6/in2");
lgraph = connectLayers(lgraph,"block7_sepconv3_bn","add_6/in1");
lgraph = connectLayers(lgraph,"add_6","block8_sepconv1_act");
lgraph = connectLayers(lgraph,"add_6","add_7/in2");
lgraph = connectLayers(lgraph,"block8_sepconv3_bn","add_7/in1");
lgraph = connectLayers(lgraph,"add_7","block9_sepconv1_act");
lgraph = connectLayers(lgraph,"add_7","add_8/in2");
lgraph = connectLayers(lgraph,"block9_sepconv3_bn","add_8/in1");
lgraph = connectLayers(lgraph,"add_8","block10_sepconv1_act");
lgraph = connectLayers(lgraph,"add_8","add_9/in2");
lgraph = connectLayers(lgraph,"block10_sepconv3_bn","add_9/in1");
lgraph = connectLayers(lgraph,"add_9","block11_sepconv1_act");
lgraph = connectLayers(lgraph,"add_9","add_10/in2");
lgraph = connectLayers(lgraph,"block11_sepconv3_bn","add_10/in1");
lgraph = connectLayers(lgraph,"add_10","block12_sepconv1_act");
lgraph = connectLayers(lgraph,"add_10","add_11/in2");
lgraph = connectLayers(lgraph,"block12_sepconv3_bn","add_11/in1");
lgraph = connectLayers(lgraph,"add_11","block13_sepconv1_act");
lgraph = connectLayers(lgraph,"add_11","conv2d_4");
lgraph = connectLayers(lgraph,"block13_pool","add_12/in1");
lgraph = connectLayers(lgraph,"batch_normalization_4","add_12/in2");
lgraph = connectLayers(lgraph,"block14_sepconv2_act","aspp_Conv_4_depthwise");
lgraph = connectLayers(lgraph,"block14_sepconv2_act","aspp_Conv_3_depthwise");
lgraph = connectLayers(lgraph,"block14_sepconv2_act","aspp_Conv_1_depthwise");
lgraph = connectLayers(lgraph,"block14_sepconv2_act","aspp_Conv_2_depthwise");
lgraph = connectLayers(lgraph,"aspp_Relu_3","catAspp/in3");
lgraph = connectLayers(lgraph,"aspp_Relu_2","catAspp/in2");
lgraph = connectLayers(lgraph,"aspp_Relu_1","catAspp/in1");
lgraph = connectLayers(lgraph,"aspp_Relu_4","catAspp/in4");
lgraph = connectLayers(lgraph,"dec_upsample1","dec_crop1/in");
lgraph = connectLayers(lgraph,"dec_crop1","dec_cat1/in2");
lgraph = connectLayers(lgraph,"dec_upsample2","dec_crop2/in");

% plot(lgraph);