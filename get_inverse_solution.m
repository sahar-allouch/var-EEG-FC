function [filters] = get_inverse_solution(eeg,srate,noiseCov,ftHeadmodel,ftLeadfield,ftElec,VertNormals)

% compute EEG inverse solution using eLORETA, wMNE, and LCMV
% inputs: eeg: nb_channels*nb_samples
% srate: sampling rate
% montage: montage based on which EEG data was computed. {'EGI_HydroCel_256',
% 'EGI_HydroCel_128','EGI_HydroCel_64','EGI_HydroCel_32','10-20_19'}.

% Outputs: filters: nb_regions*nb_channels, nb_regions denotes the number
% of cortical sources, nb_channels denotes the number of EEG channels.

% This code was originally developped by Sahar Allouch.
% contact: saharallouch@gmail.com


% [ftHeadmodel,ftLeadfield] = get_ftHeadmodel_and_ftLeadfield(montage);
% %ftLeadfield = downsample_ftLeadfield(ftLeadfield,montage);
%
% load('inputs/tess_cortex_pial_low.mat','VertNormals')
% load('inputs/scout_Desikan-Killiany_68.mat','Scouts')
% seeds = [Scouts.Seed];
% VertNormals = VertNormals(seeds,:);
%
% ftElec = get_ftElec(montage);

epoch_length = size(eeg,2)/srate;

% number of sources
nb_sources = size(VertNormals,1);

% number of channels
nb_chan = size(eeg,1);

% preallocation
filters = zeros(3,nb_sources,nb_chan);

% prepare fieldtrip struct
ftData.trial{1} = eeg;
ftData.time{1}  = 0:1/srate:epoch_length-1/srate;
ftData.elec = ftElec;
ftData.label = ftElec.label';
ftData.fsample = srate;

clear eeg

%% timelock analysis
cfg                      = [];
cfg.covariance           = 'yes';
cfg.covariancewindow     = 'all';
cfg.keeptrials           = 'no';    %if 'yes' no avg field in the output struct

timelock                 = ft_timelockanalysis(cfg,ftData);

%% eLORETA
cfg                     = [];
cfg.method              = 'eloreta';
cfg.sourcemodel         = ftLeadfield;
cfg.sourcemodel.mom     = transpose(VertNormals);
cfg.headmodel           = ftHeadmodel;
cfg.eloreta.keepfilter  = 'yes';
cfg.eloreta.keepmom     = 'no';
cfg.eloreta.lambda      = 0.05; % default in ft = 0.05 (used before 0.01)

src                     = ft_sourceanalysis(cfg,timelock);

filters(1,:,:)            = cell2mat(transpose(src.avg.filter));

%% LCMV Beamformer
cfg                      = [];
cfg.method               = 'lcmv';
cfg.sourcemodel          = ftLeadfield;
cfg.sourcemodel.mom      = transpose(VertNormals);
cfg.headmodel            = ftHeadmodel;
cfg.lcmv.fixedori        = 'no';
cfg.lcmv.keepfilter      = 'yes';
cfg.lcmv.keepmom         = 'no';
cfg.keepleadfield        = 'no';
cfg.lcmv.lambda          = '5%'; % 1%';   % '5%'    '10%'   '15%'   '20%'    '25%'
cfg.lcmv.projectnoise    = 'no';
% cfg.lcmv.weightnorm      = 'unitnoisegain';

src                      = ft_sourceanalysis(cfg,timelock);

filters(2,:,:)            = cell2mat(src.avg.filter);

%% wMNE
weightExp = 0.5;
weightLimit = 10;
SNR = 3;

Gain=cell2mat(ftLeadfield.leadfield);
GridLoc = ftLeadfield.pos;
GridOrient = VertNormals;

filters(3,:,:) = wmne.ComputeWMNE(noiseCov,Gain,GridLoc,GridOrient,weightExp,weightLimit,SNR);

end
