% All epochs similarities
path = 'results/cmats';
path_to_save = 'results/epochs_similarity';
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

% make output directory
if exist(path_to_save,'dir') ~= 7
    mkdir(path_to_save)
end

nb_epochs = 30;

for b = 1:length(bands)
    
    % loop over electrode montages
    for m = 1:nb_montages
        
        % loop over inverse solutions
        for iv = 1:nb_inv
            
            % output mat preallocation
            p_corr = ones(nb_subs,length(conn),(nb_epochs*nb_epochs-nb_epochs)/2);
            
            % loop over subjects
            for s = 1:length(subs)
                k = 0;
                
                % get filenames (epochs) for subject s
                files = dir([path '/' subs{s} '/cmats_' inv{iv} '_' mon{m} '_' bands{b} '*.mat']);
                
                % two loop over files
                for f = 1:length(files)-1
                    load([path '/' subs{s} '/' files(f).name]);                
                    x = cmats(:,triu(true(nb_rois),1));
                    
                    for ff = f+1:length(files)
                        load([path '/' subs{s} '/' files(ff).name]);
                        y = cmats(:,triu(true(nb_rois),1));
                        
                        k = k+1;

                        % loop over connectivity matrices
                        for c = 1:length(conn)
                            
                            % correlation between epochs i and j
                            corr_mat = corrcoef(x(c,:),y(c,:));
                            
                            p_corr(s,c,k) = corr_mat(1,2);
                            
                        end
                    end
                end
            end
            
            save([path_to_save '/all_epochs_similarity_' inv{iv} '_' mon{m} '_' bands{b} '.mat'],'p_corr');

        end
    end
end
