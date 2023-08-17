path = 'results/cmats';
path_to_save = 'results/avg_cmats';
subs = get_subs(path);
nb_subs = length(subs);
nb_rois = 68;

mon = {'Biosemi_64','Biosemi_32','Biosemi_19'};
nb_montages = length(mon);

inv = {'eloreta','lcmv','wmne'};
nb_inv = length(inv);
% conn = {'plv','pli','wpli','wpli_debiased','aec','aec_orth'};
% conn = {'plv','pli','wpli','wpli_debiased','aec','aec_orth',...
%     'aec_corr_pairwise','plv_corr_pairwise','plv_orth'};
conn = {'plv','pli','aec','plv_orth','aec_orth',...
    'plv_corr_pairwise','aec_corr_pairwise','wpli'};

bands = {'theta','delta','alpha','beta','gamma'};

% loop over all subjects
for s = 1:nb_subs
    
    % make output directory
    if exist([path_to_save '/' subs{s}],'dir') ~= 7
        mkdir([path_to_save '/' subs{s}])
    end
    
    % loop over frequency bands
    for b = 1:length(bands)
        
        % loop over electrode montages
        for m = 1:nb_montages
            
            % loop over inverse algorithms
            for iv = 1:nb_inv
                
                % output matrix preallocation
                avg_cmats = zeros(length(conn),nb_rois,nb_rois);
                
                % get all epochs filenames for subject s
                files = dir([path '/' subs{s} '/cmats_' inv{iv} '_' mon{m} '_' bands{b} '*.mat']);
                
                % loop over all files/epochs
                for f = 1:length(files)
                    
                    load([path '/' subs{s} '/' files(f).name]);
                    avg_cmats = avg_cmats + cmats;
                    
                end
                
                avg_cmats = avg_cmats./length(files);
                
                
                save([path_to_save '/' subs{s} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b}],'avg_cmats')
            end
        end
    end
    
end

