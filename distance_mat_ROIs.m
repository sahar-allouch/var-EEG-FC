load('inputs/scout_Desikan-Killiany_68.mat','Scouts');
load('inputs/tess_cortex_pial_low.mat','Vertices');

seed_points = [Scouts.Seed];
nb_rois = length(seed_points);
distance_mat = zeros(nb_rois,nb_rois);

for i=1:nb_rois
    for j=1:nb_rois
        % distance from seed to seed
        distance_mat(i,j) = vecnorm(Vertices(seed_points(i))-Vertices(seed_points(j)));
    end
end

distance_mat = distance_mat*100;
save('inputs/distance_mat_desikan','distance_mat')
