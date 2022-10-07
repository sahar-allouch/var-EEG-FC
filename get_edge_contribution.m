function edge_contribution = get_edge_contribution(cmat_ref,cmat_est)

% nb_rois = size (cmat_ref,1);
nb_rois = 68;
% x = zscore(cmat_ref(triu(true(nb_rois),1)));
% y = zscore(cmat_est(triu(true(nb_rois),1)));
x = cmat_ref;
y = cmat_est;
% phi = edge-wise product vector 
phi = x.*y;

% normalization
% phi_n = (x.*y)./sum(x.*y);

edge_contribution = zeros(nb_rois);
k = 1;
for i=1:nb_rois
    for j=i+1:nb_rois
        edge_contribution(i,j) = phi(k);
        k = k+1;
    end
end

edge_contribution = edge_contribution'+edge_contribution;
if ~isequal(k,(nb_rois*(nb_rois-1)/2)+1)
    warning('ERROR')
end

% edge_contribution = reshape(phi,[nb_rois,nb_rois]);
% edge_contribution = edge_contribution .* (eye(nb_rois)==0);

% group_consistency = mean of phi over all subjects

end
