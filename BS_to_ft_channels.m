function elec = BS_to_ft_channels(bs_channel_file,eeg_id)
load(bs_channel_file,'Channel')
%eeg_id = 1:257;
% Create electrode structure
elec = struct();
elec.label = {Channel(eeg_id).Name};
elec.unit  = 'm';
% Electrode position
elec.chanpos = zeros(length(eeg_id),3);
for i = 1:length(eeg_id)
    if all(size(Channel(eeg_id(i)).Loc) >= [3,1])
        elec.chanpos(i,:) = Channel(eeg_id(i)).Loc(:,1);
    else
        elec.chanpos(i,:) = [0;0;0];
    end
end
elec.elecpos = elec.chanpos;
% Default montage
elec.tra = eye(length(eeg_id));

end