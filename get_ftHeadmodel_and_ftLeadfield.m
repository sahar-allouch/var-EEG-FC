function [ftHeadmodel,ftLeadfield] = get_ftHeadmodel_and_ftLeadfield(montage)

% addpath S://Matlab_Toolboxes//fieldtrip-20200423
% ft_defaults

ftElec = BS_to_ft_channels('inputs/channel_Biosemi_64_bs',1:64);

if isfile('inputs/ftHeadmodel_biosemi_64.mat')
    load('inputs/ftHeadmodel_biosemi_64.mat','ftHeadmodel');
else
    % prepare headmodel and leadfield with fieldtrip for ICBM152
    SurfaceFiles = {'inputs/tess_head.mat';...
        'inputs/tess_outerskull.mat';...
        'inputs/tess_innerskull.mat'};
    
    ftGeometry = BS_to_ft_tess(SurfaceFiles);
    
    
    cfg = [];
    cfg.method = 'openmeeg';
    % cfg.elec   = ftElec;    % Sensor positions
    cfg.conductivity = [1,0.0125,1];
    % cfg.tissue = ['scalp','skull','brain'];
    ftHeadmodel = ft_prepare_headmodel(cfg, ftGeometry);
    
    save('inputs/ftHeadmodel_biosemi_64','ftHeadmodel');
    
end
% Convert to meters (same units as the sensors)
% ftHeadmodelEeg = ft_convert_units(ftHeadmodelEeg, 'm');

if isfile('inputs/ftLeadfield_biosemi_64.mat')
    load('inputs/ftLeadfield_biosemi_64.mat','ftLeadfield');
else
    % Load cortex surface
    SurfaceMat = load('inputs/tess_cortex_pial_low.mat');
    
    GridLoc    = SurfaceMat.Vertices;
    % Faces      = SurfaceMat.Faces;
    % GridOrient = SurfaceMat.VertNormals;
    
    
    % Convert to a FieldTrip grid structure
    ftGrid.pos    = GridLoc;            % source points
    ftGrid.inside = 1:size(GridLoc,1);  % all source points are inside of the brain
    ftGrid.unit   = 'm';
    
    
    cfg = [];
    cfg.elec      = ftElec;
    cfg.grid      = ftGrid;
    cfg.headmodel = ftHeadmodel;  % Volume conduction model
    
    ftLeadfield = ft_prepare_leadfield(cfg);
    
    % leadfield = cell2mat(ftLeadfield.leadfield);
    % leadfield = bst_gain_orient(leadfield,GridOrient);
    
    save('inputs/ftLeadfield_biosemi_64','ftLeadfield');
end

ftLeadfield = downsample_ftLeadfield(ftLeadfield,montage);
end


function ftLeadfield = downsample_ftLeadfield(ftLeadfield,montage)

% load('inputs/scout_Desikan-Killiany_68.mat','Scouts')
% seeds = [Scouts.Seed];
%
% ftLeadfield.leadfield = ftLeadfield.leadfield(seeds);
% ftLeadfield.pos = ftLeadfield.pos(seeds,:);
% ftLeadfield.inside = ftLeadfield.inside(seeds);

switch montage
    case 'Biosemi_32'
        load('inputs/biosemi_64_to_32_ch_id','eeg_id')
        ftLeadfield.label = ftLeadfield.label(eeg_id);
        for i = 1:length(ftLeadfield.leadfield)
            ftLeadfield.leadfield{1,i} = ftLeadfield.leadfield{1,i}(eeg_id,:);
        end
    case 'Biosemi_19'
        load('inputs/biosemi_64_to_19_ch_id','eeg_id')
        ftLeadfield.label = ftLeadfield.label(eeg_id);
        for i = 1:length(ftLeadfield.leadfield)
            ftLeadfield.leadfield{1,i} = ftLeadfield.leadfield{1,i}(eeg_id,:);
        end
end

end