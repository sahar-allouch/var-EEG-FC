% addpath S://Matlab_Toolboxes//fieldtrip-20200423
% ft_defaults

% dataset resting_marseille
function [] = run_pipeline(sub,path)

% sampling rate
srate = 512;

% tested electrodes montages
montages = {'Biosemi_64','Biosemi_32','Biosemi_19'};
nb_montages = length(montages);

% tested inverse solutions
inv = {'eloreta','lcmv','wmne'};
nb_inv = length(inv);

% load mat of sources orientations to use in inverse solution computation
load('inputs/tess_cortex_pial_low.mat','VertNormals')

% get filenames of all epochs for subject s (30 epochs)
epochs = dir([path '/' sub '/*block*.mat']);
nb_epochs = length(epochs);

% number of tested connectivity measures to use for mat preallocation
nb_connectivity = 8;

% number of regions of interest to use for mat preallocation
nb_rois = 68;

% connectivity matrix preallocation
cmats = zeros(nb_connectivity,nb_rois,nb_rois);

% make directory for connectivity matrices
if exist(['results/cmats/' sub],'dir') ~= 7
    mkdir(['results/cmats/' sub])
end

% loop over all montages (64, 32, 19 electrodes)
for m = 1:nb_montages
    % montage name
    montage = montages{m};
    
    %% load/compute headmodel and leadfield struct
    [ftHeadmodel,ftLeadfield] = get_ftHeadmodel_and_ftLeadfield(montage);
    
    % get electrodes struct (fieldtrip format)
    ftElec = get_ftElec(montage);
    
    %% noise covariance mat
    
    % load an eeg epoch to use for noise covariance computation
    eeg_for_noise_cov = load([path '/' sub '/' 'eeg_for_noise_cov'],'eeg');
    
    % extract needed channels according to the tested montage
    eeg_for_noise_cov = get_eeg_montage(eeg_for_noise_cov.eeg,montage);
    
    % compute noise covariance
    noiseCov = wmne.CalculateNoiseCovarianceTimeWindow(eeg_for_noise_cov);
    
    clear eeg_for_noise_cov
    
    %% loop over all epochs of subject s
    for e = 1:nb_epochs
        
        %% load the EEG data
        eeg = load([path '/' sub '/' epochs(e).name],'eeg');
        
        % extract needed channels according to tested montage
        eeg = get_eeg_montage(eeg.eeg,montage);
        
        %% solving the inverse problem
        % filters = matrix of filters for eLORETA, LCMV, wMNE
        filters = get_inverse_solution(eeg,srate,noiseCov,ftHeadmodel,ftLeadfield,ftElec,VertNormals);
        
        % loop over inverse solutions {eLORETA, LCMV, wMNE)
        for iv = 1:nb_inv
            % compute cortical sources for inverse solution iv
            src_data = squeeze(filters(iv,:,:)) * eeg;
            
            % extract scout timeseries based on Desikan-Killiany atlas (68
            % ROIs) = average sources in single ROI (+ flipping the sign to
            % avoid sources cancellation)
            src_data = get_scouts_timeseries(src_data);
            
            
            %% connectivity
            
            % for each frequency band filter cortical sources and compute
            % connectivity matrices using (PLV, PLI, AEC, PLV*, AEC*,
            % PLV**, AEC**, wPLI)
            % cmats = nb_connectivity x nb_rois x nb_rois
%             
%            % delta
%                         fmin = 0.1;
%                         fmax = 4;
%             
%                         src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
%                         cmats(:,:,:) = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
%                         save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_delta_' epochs(e).name],'cmats')
%             
%            % theha
%                         fmin = 4;
%                         fmax = 8;
%                         src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
%                         cmats(:,:,:) = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
%                         save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_theta_' epochs(e).name],'cmats')
%             
            % alpha
            fmin = 8;
            fmax = 13;
            src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
            cmats(:,:,:) = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
            save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_alpha_' epochs(e).name],'cmats')
            
            %                 % alpha1
            %                 fmin = 8;
            %                 fmax = 10;
            %                 src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
            %                 cmats = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
            %                 save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_alpha1_' epochs(e).name],'cmats')
            %
            %                 % alpha2
            %                 fmin = 10;
            %                 fmax = 13;
            %                 src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
            %                 cmats = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
            %                 save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_alpha2_' epochs(e).name],'cmats')
            %
            % beta
%             fmin = 13;
%             fmax = 30;
%             src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
%             cmats(:,:,:) = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
%             save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_beta_' epochs(e).name],'cmats')
%             
%            % gamma
%                         fmin = 30;
%                         fmax = 45;
%                         src_data_filtered = bst_bandpass_filtfilt(src_data,srate,fmin,fmax);
%                         cmats(:,:,:) = get_all_connectivity_mats(src_data_filtered,srate,fmin,fmax);
%                         save(['results/cmats/' sub '/cmats_' inv{iv} '_' montage '_gamma_' epochs(e).name],'cmats')
%             
            
        end
    end
end
end


%%% ========== GET EEG MONTAGE ========== %%%
function eeg = get_eeg_montage(eeg,montage)

switch montage
    case 'Biosemi_32'
        load('inputs/biosemi_64_to_32_ch_id','eeg_id')
        eeg = eeg(eeg_id,:);
        
    case 'Biosemi_19'
        load('inputs/biosemi_64_to_19_ch_id','eeg_id')
        eeg = eeg(eeg_id,:);
end

end
