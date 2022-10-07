function aec = aec_sliding_window_corrected_pairwise(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

aec = zeros(nb_windows,nb_signals,nb_signals);

for w = 1:nb_windows
    aec_tmp = zeros(nb_signals,nb_signals);
    for i = 1:nb_signals
        
        x = data(i,:);
        inv_x = pinv(x);
        env_x = abs(hilbert(x));
        
        for j = 1:nb_signals
            if i ~= j
                y = data(j,:);
                
                % pairwise leakage correction/orthogonalisation
                
                y_corr = y - x*(inv_x'*y');
                
                env_y = hilbert(y_corr);
                env_y = abs(env_y);
                
                t_env_x = env_x';
                t_env_y = env_y';
                aec_tmp(i,j) = corr(t_env_x,t_env_y);
                
            end
        end
    end
    
    aec_tmp = (triu(aec_tmp)+tril(aec_tmp)')/2;
    aec(w,:,:) = abs(aec_tmp+aec_tmp');
end

%% static AEC
aec = mean(aec,1);
aec = reshape(aec(1,:,:),[nb_signals,nb_signals]);


end