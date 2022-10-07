function [plv,aec] = plv_aec_sliding_window_corrected(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

% symmetric orthogonalization to remove source leakage
data = (ROInets.symmetric_orthogonalise(data'))';

inst_phase = zeros(nb_signals,nb_samples);
env = zeros(nb_signals,nb_samples);

for i = 1:nb_signals
    tmp = hilbert(data(i, :));
    
    inst_phase(i, :) = angle(tmp);
    env(i, :) = abs(tmp);
end

%% dynamic PLV & AEC
plv = zeros(nb_windows,nb_signals,nb_signals);
aec = zeros(nb_windows,nb_signals,nb_signals);

for i = 1:nb_windows
    % extract phase in window i
    tmp = inst_phase(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
    
    % compute plv in window i
    % plv(i,:,:) = ROInets.plv(tmp);
    plv(i,:,:) = connectivity.compute_plv(tmp);
    
    % extract envelope in window i
    tmp = env(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
    
    % compute AEC in window i
    aec(i,:,:) = abs(ROInets.aec(tmp)) - eye(nb_signals);
end

%% static PLV
% average conenctivity matrices across all windows
plv = squeeze(mean(plv,1));

%% static AEC
aec = squeeze(mean(aec,1));

end