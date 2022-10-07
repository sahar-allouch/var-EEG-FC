function plv = plv_sliding_window_corrected(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

data = (ROInets.symmetric_orthogonalise(data'))';

inst_phase = zeros(nb_signals,nb_samples);
for i = 1:nb_signals
    tmp = hilbert(data(i, :));
    inst_phase(i, :) = angle(tmp);
end

%% dynamic plv
plv = zeros(nb_windows,nb_signals,nb_signals);

for i = 1:nb_windows
    tmp = inst_phase(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
%     plv(i,:,:) = ROInets.plv(tmp);
    plv(i,:,:) = connectivity.compute_plv(tmp);
end

%% static plv
plv = mean(plv,1);
plv = reshape(plv(1,:,:),[nb_signals,nb_signals]);

end