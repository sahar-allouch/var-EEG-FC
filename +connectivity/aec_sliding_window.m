function aec = aec_sliding_window(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

env = zeros(nb_signals,nb_samples);
for i = 1:nb_signals
    tmp = hilbert(data(i, :));
    env(i, :) = abs(tmp);
end

%% dynamic AEC
aec = zeros(nb_windows,nb_signals,nb_signals);

for i = 1:nb_windows
    tmp = env(:,1 + mid_window(i) - win_samples/2 : mid_window(i)+win_samples/2);
    aec(i,:,:) = abs(ROInets.aec(tmp)) - eye(nb_signals); % !!! abs !!!
end

%% static AEC
aec = mean(aec,1);
aec = reshape(aec(1,:,:),[nb_signals,nb_signals]);

end
