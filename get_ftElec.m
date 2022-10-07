function ftElec = get_ftElec(montage)
switch montage
    case 'Biosemi_19'
        load('inputs/biosemi_64_to_19_ch_id','eeg_id')
    case 'Biosemi_32'
        load('inputs/biosemi_64_to_32_ch_id','eeg_id')
    case 'Biosemi_64'
        eeg_id = 1:64;
end
ftElec = BS_to_ft_channels('inputs/channel_Biosemi_64_bs',eeg_id);

end
