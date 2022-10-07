addpath S://Matlab_Toolboxes//fieldtrip-20200423
ft_defaults

% addpath BRAINSTORM

% path of subjects folders
path = 'resting_marseille\epochs_20-39yo_512Hz_preprocessed_ica_to_use';

% get all subjects in directory
subs = get_subs(path);
nb_subs = length(subs);

% loop over all subjects in directory
for  s = 1:nb_subs
    
    run_pipeline(subs{s},path)
    
end


