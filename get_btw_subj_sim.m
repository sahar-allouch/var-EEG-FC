path = 'results/avg_cmats';
path_to_save = 'results/subs_similarity';
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
bands = {'theta','beta','gamma'};

p_corr = ones(length(conn),nb_subs,nb_subs);

if exist(path_to_save,'dir') ~= 7
    mkdir(path_to_save)
end

% if exist('results/conditions_similarity','dir') ~= 7
%     mkdir('results/conditions_similarity/')
% end

for b = 1:length(bands)
    
    % loop over electrode montages
    for m = 1:nb_montages
        
        % loop over inverse solutions
        for iv = 1:nb_inv
            
            % two loops over subjects
            for s = 1:nb_subs
                
                % load connectivity mat for subject i
                load([path '/' subs{s} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'avg_cmats')
                avg_cmats_1 = avg_cmats;
                
                % load connectivity mats for subjects != i
                for ss = 1:nb_subs
                    load([path '/' subs{ss} '/avg_cmats_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'avg_cmats')
                    
                    avg_cmats_2 = avg_cmats;
                    clear avg_cmats
                    
                    % extract upper triangular elements
                    x = avg_cmats_1(:,triu(true(nb_rois),1));
                    y = avg_cmats_2(:,triu(true(nb_rois),1));
                   
                    % loop over connectivity matrices
                    for c = 1:length(conn)
                        
                        % correlation between subjects 
                        corr_mat = corrcoef(x(c,:),y(c,:));
                        p_corr(c,s,ss) = corr_mat(1,2);
                    end
                    
                end
                
            end
            
            % save between-subjects similarity matrix (rows & cols == subs)
            save([path_to_save '/subs_similarity_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'p_corr');
            
            % save upper triangular elements of the similarity mat
            p_corr_v = p_corr(:,triu(true(nb_subs),1));
            save([path_to_save '/subs_similarity_' inv{iv} '_' mon{m} '_' bands{b} '_vect.mat'],'p_corr_v');         
            
        end
    end
end
