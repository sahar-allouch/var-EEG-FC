function subs = get_subs(path)
 % get the subjects names in a directory
 
subs = dir(path);
subs = subs(find(~strcmp({'.'},{subs.name})));
subs = subs(find(~strcmp({'..'},{subs.name})));
subs = subs(find(~strcmp({'project_state.mat'},{subs.name})));
subs = subs(find(~strcmp({'nb_accepted.mat'},{subs.name})));

subs = {subs.name}';
end