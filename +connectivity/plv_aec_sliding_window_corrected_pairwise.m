function [plv,aec] = plv_aec_sliding_window_corrected_pairwise(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

plv = zeros(nb_windows,nb_signals,nb_signals);
aec = zeros(nb_windows,nb_signals,nb_signals);

for w = 1:nb_windows
    
    plv_tmp = zeros(nb_signals,nb_signals);
    aec_tmp = zeros(nb_signals,nb_signals);

    for i = 1:nb_signals
        
        x = data(i,:);
        inv_x = pinv(x);
        
        hilbert_x = hilbert(x);
        phase_x = angle(hilbert_x);
        env_x = abs(hilbert_x);
        
        for j = 1:nb_signals
            if i ~= j
                y = data(j,:);
                
                % pairwise leakage correction/orthogonalisation
                t_inv_x = inv_x';
                t_y = y';
                y_cor = y - x*(t_inv_x*t_y);
                
                hilbert_y = hilbert(y_cor);
                phase_y = angle(hilbert_y);
                env_y = abs(hilbert_y);
                
                % compute plv
                % tmp = ROInets.plv([phase_x;phase_y]);
                tmp = connectivity.compute_plv([phase_x;phase_y]);
                plv_tmp(i,j) = tmp(1,2);
                
                % compute aec
                t_env_x = env_x';
                t_env_y = env_y';
                aec_tmp(i,j) = corr(t_env_x,t_env_y);
                
                
            end
        end
    end
    
    plv_tmp = (triu(plv_tmp)+tril(plv_tmp)')/2;
    plv(w,:,:) = abs(plv_tmp+plv_tmp');
    
    aec_tmp = (triu(aec_tmp)+tril(aec_tmp)')/2;
    aec(w,:,:) = abs(aec_tmp+aec_tmp');
    
end

%% static PLV
plv = squeeze(mean(plv,1));

%% static AEC
aec = squeeze(mean(aec,1));

end