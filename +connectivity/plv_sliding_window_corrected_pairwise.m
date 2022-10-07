function plv = plv_sliding_window_corrected_pairwise(data,srate,window,step)

[nb_signals, nb_samples] = size(data);

win_samples = ceil(window*srate);
nb_shifts  = ceil(step*srate);

mid_window = win_samples/2:nb_shifts:nb_samples-win_samples/2;
nb_windows = length(mid_window);

plv = zeros(nb_windows,nb_signals,nb_signals);

for w = 1:nb_windows
    plv_tmp = zeros(nb_signals,nb_signals);
    
    for i = 1:nb_signals
        
        x = data(i,:);
        inv_x = pinv(x);
        phase_x = angle(hilbert(x));
        
        for j = 1:nb_signals
            if i ~= j
                y = data(j,:);
                
                % pairwise leakage correction/orthogonalisation
                t_inv_x = inv_x';
                t_y = y';
                y_cor = y - x*(t_inv_x*t_y);
                
                phase_y = hilbert(y_cor);
                phase_y = angle(phase_y);
                
                %         tmp = ROInets.plv([phase_x;phase_y]);
                tmp = connectivity.compute_plv([phase_x;phase_y]);
                
                plv_tmp(i,j) = tmp(1,2);
                
                
            end
        end
    end
    
    plv_tmp = (triu(plv_tmp)+tril(plv_tmp)')/2;
    plv(w,:,:) = abs(plv_tmp+plv_tmp');
end

%% static AEC
plv = mean(plv,1);
plv = reshape(plv(1,:,:),[nb_signals,nb_signals]);


end