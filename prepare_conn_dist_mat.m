path = 'results/avg_cmats';
path_to_save = 'results/grp_consistency/mat_distance_connectivity';

subs = get_subs(path);
nb_subs = length(subs);

mon = {'Biosemi_64','Biosemi_32','Biosemi_19'};
nb_montages = length(mon);

inv = {'eloreta','lcmv','wmne'};
% conn = {'plv','pli','wpli','wpli_debiased','aec','aec_orth'};
% conn = {'plv','pli','wpli','wpli_debiased','aec','aec_orth',...
%     'aec_corr_pairwise','plv_corr_pairwise','plv_orth'};
nb_inv = length(inv);

conn = {'plv','pli','aec','plv_orth','aec_orth',...
    'plv_corr_pairwise','aec_corr_pairwise','wpli'};
nb_conn = length(conn);

bands = {'delta','theta','alpha','beta','gamma'};

load('inputs/distance_mat_desikan','distance_mat')
x = distance_mat(triu(true(nb_rois),1));

nb_rois = 68;

if exist(path_to_save,'dir') ~= 7
    mkdir(path_to_save)
end


% loop over bands
for b = 3:4%length(bands)
    
    % loop over electrode montages
    for m = 1:nb_montages
        
        % loop over inverse solutions
        for iv = 1:nb_inv
            
            % loop over iterations
            
            for s = 1:nb_subs
                
                load([path '/' subs{s} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'avg_cmats');
                cmats(s,:,:,:) = avg_cmats;
                
            end

            % grp conn mat == average over subject in group Gi
            avg_cmats = squeeze(mean(cmats,1));
            
            % extract elements in upper triangle
            y = avg_cmats(:,triu(true(nb_rois),1));
            
            var_to_corr = [x,y'];
            %             corr_mat = corrcoef(distance_mat,mean_edge_contribution);
            %             p_corr(t,c) = corr_mat(1,2);
            
            save([path_to_save '/mat_dist_conn_' inv{iv} '_' mon{m} '_' bands{b}],'var_to_corr')
       
            % loop over connectivity metrics
            
        end
    end
end



