function cmats = get_all_connectivity_mats(src_data,srate,fmin,fmax)

% plv || pli || aec
cfg = cfg_connectivity(srate,fmin,fmax,'default');
[plv,pli,aec] = connectivity.plv_pli_aec_sliding_window(src_data, cfg.srate, cfg.window, cfg.step);
cmats(1,:,:) = plv;
cmats(2,:,:) = pli;
cmats(3,:,:) = aec;

% plv_orth || aec_orth
% cfg = cfg_connectivity(srate,fmin,fmax,'default');
[plv,aec] = connectivity.plv_aec_sliding_window_corrected(src_data, cfg.srate, cfg.window, cfg.step);
cmats(4,:,:) = plv;
cmats(5,:,:) = aec;

% plv_pairwise_correction || aec_pairwise_correction

% cfg = cfg_connectivity(srate,fmin,fmax,'default');
[plv,aec] = connectivity.plv_aec_sliding_window_corrected_pairwise(src_data, cfg.srate, cfg.window, cfg.step);
cmats(6,:,:) = plv;
cmats(7,:,:) = aec;

% wpli
cfg = cfg_connectivity(srate,fmin,fmax,'wpli');
debiased = 0;
cmats(8,:,:) = connectivity.wpli_ft(src_data, cfg.srate, cfg.window, cfg.step, cfg.fmin, cfg.fmax, debiased);

% wpli_debiased
% cfg = cfg_connectivity(srate,fmin,fmax,'wpli');
% debiased = 1;
% cmats(9,:,:) = connectivity.wpli_ft(src_data, cfg.srate, cfg.window, cfg.step, cfg.fmin, cfg.fmax, debiased);
end


%%% ========== GET CONFIGURATION STRUCT ========== %%%
function cfg = cfg_connectivity(srate,fmin,fmax,method)

cfg = [];
cfg.srate = srate;
cfg.fmin = fmin;
cfg.fmax = fmax;
cfg.conn_meth = method;

switch method
    case "wpli"
        cfg.window = 0.5; % Vinck et al. 2011
        cfg.step = 0.1; % Vinck et al. 2011: (((((0.01))))))
    otherwise
        cfg.window = 10; % sec (= epoch length; static fct conn)
        cfg.step = cfg.window;
      
end
end




