path = 'results/grp_consistency';
path_to_save = 'results/grp_consistency/edge_cont_dist';

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

nb_rois = 68;
load('inputs/distance_mat_desikan','distance_mat')

if exist(path_to_save,'dir') ~= 7
    mkdir(path_to_save)
end

for b = 2:2
    for m = 1:nb_montages
        for iv = 1:nb_inv
            load([path '/mean_edge_contribution_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'mean_edge_contribution')
           
            x = distance_mat(triu(true(nb_rois),1));
            
            y = (mean_edge_contribution(:,triu(true(nb_rois),1)))';
            y = y./max(y);
            
            var_to_corr = [x,y];
            %             corr_mat = corrcoef(distance_mat,mean_edge_contribution);
            %             p_corr(t,c) = corr_mat(1,2);
            
            save([path_to_save '/edge_contribution_dist_desikan_' inv{iv} '_' mon{m} '_' bands{b}],'var_to_corr')
        end
    end
end

