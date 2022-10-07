function scouts_data = get_scouts_timeseries(src_data)

load('inputs/scout_Desikan-Killiany_68.mat','Scouts')
load('inputs/tess_cortex_pial_low','VertNormals')

scouts_data = zeros(length(Scouts),size(src_data,2));

for i = 1:length(Scouts)
    Orient = VertNormals(Scouts(i).Vertices,:);
    scouts_data(i,:) = bst_scout_value(src_data(Scouts(i).Vertices,:),'mean', Orient, 1, 'none', 1);
end