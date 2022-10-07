path = 'results/avg_cmats';
path_to_save = 'results/grp_consistency';
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

bands = {'theta','beta','gamma'};

% number of iterations
nb_iter = 100;

nb_rois = 68;

% output matrices preallocation
p_corr = zeros(nb_iter,nb_conn);
edge_contribution = zeros(nb_iter,nb_conn,nb_rois,nb_rois);

if exist(path_to_save,'dir') ~= 7
    mkdir(path_to_save)
end

% loop over bands
for b = 1:length(bands)
    
    % loop over electrode montages
    for m = 1:nb_montages
        
        % loop over inverse solutions
        for iv = 1:nb_inv
            
            % loop over iterations
            for t = 1:nb_iter
                
                % assign subjects for each group (1 & 2) randomly
                rnd_samples_1 = randsample(nb_subs,floor(nb_subs/2));
                rnd_samples_2 = setdiff((1:nb_subs)', rnd_samples_1);
                
                
                % group matrices preallocation
                cmats_1 = zeros (length(rnd_samples_1),length(conn),nb_rois,nb_rois);
                cmats_2 = zeros (length(rnd_samples_1),length(conn),nb_rois,nb_rois);
                
                % load matrices for subjects in each group
                for i = 1:length(rnd_samples_1)
                    
                    load([path '/' subs{rnd_samples_1(i)} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'avg_cmats');
                    cmats_1(i,:,:,:) = avg_cmats;
                    
                end
                
                for i = 1:length(rnd_samples_2)
                    
                    load([path '/' subs{rnd_samples_2(i)} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'avg_cmats');
                    cmats_2(i,:,:,:) = avg_cmats;
                    
                end
                
                
                % grp conn mat == average over subject in group Gi
                avg_cmats_1 = squeeze(mean(cmats_1,1));
                avg_cmats_2 = squeeze(mean(cmats_2,1));
                
                % extract elements in upper triangle
                x = avg_cmats_1(:,triu(true(nb_rois),1));
                y = avg_cmats_2(:,triu(true(nb_rois),1));
                
                % loop over connectivity metrics
                for c = 1:nb_conn
                    % corr_mat = corrcoef(avg_cmats_1(c,:,:),avg_cmats_2(c,:,:));
                    % corr_mat = corrcoef(zscore(x(c,:)),zscore(y(c,:)));
                    
                    % correaltion btw grp matrices (upper tri)
                    corr_mat = corrcoef(x(c,:),y(c,:));
                    p_corr(t,c) = corr_mat(1,2);
                    
                    % get edge contribution
                    edge_contribution(t,c,:,:) = get_edge_contribution(x(c,:),y(c,:));
                end
                save(['results/grp_consistency/edge_contribution_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'edge_contribution');              
            end
            
            % average edge contribution over iterations
            mean_edge_contribution = squeeze(mean(edge_contribution,1));
            
            save([path_to_save '/grp_consistency_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'p_corr');
            save(['results/grp_consistency/mean_edge_contribution_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'mean_edge_contribution');

        end
    end
end

