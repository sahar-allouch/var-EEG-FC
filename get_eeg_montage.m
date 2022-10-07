function eeg = get_eeg_montage(eeg,montage)

switch montage
    case 'Biosemi_32'
        load('inputs/biosemi_64_to_32_ch_id','eeg_id')
        eeg = eeg(eeg_id,:);
        
    case 'Biosemi_19'
        load('inputs/biosemi_64_to_19_ch_id','eeg_id')
        eeg = eeg(eeg_id,:);
        
end
end



