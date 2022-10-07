function [plv,pli,aec] = plv_pli_aec_sliding_window(data,srate,window,step)

%% extract windows
[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

%% envelope and phase using Hilbert transform
inst_phase = zeros(nb_signals,nb_samples);
env = zeros(nb_signals,nb_samples);

for i = 1:nb_signals
    tmp = hilbert(data(i, :));
    inst_phase(i, :) = angle(tmp);
    env(i, :) = abs(tmp);
end

%% dynamic PLV, PLI, & AEC
plv = zeros(nb_windows,nb_signals,nb_signals);
pli = zeros(nb_windows,nb_signals,nb_signals);
aec = zeros(nb_windows,nb_signals,nb_signals);

% loop over windows - compute connectivity in each window
for i = 1:nb_windows
    
    % extract the phase in window i
    tmp = inst_phase(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
    
    % compute plv
    % plv(i,:,:) = ROInets.plv(tmp);
    plv(i,:,:) = connectivity.compute_plv(tmp);
    
    % compute pli
    pli(i,:,:) = ROInets.pli(tmp);
    
    % extract envelope in window i
    tmp = env(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
    
    % compute AEC
    aec(i,:,:) = abs(ROInets.aec(tmp)) - eye(nb_signals);
    
end

%% static PLV & AEC
% average connectivity matrices across all windows to get static
% connectivity
plv = squeeze(mean(plv,1));

pli = squeeze(mean(pli,1));

aec = squeeze(mean(aec,1));
end