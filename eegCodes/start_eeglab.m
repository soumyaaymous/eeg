%% Initialize and Set Up EEGLAB
% Add EEGLAB to your MATLAB path
addpath('/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/'); % Replace with the correct path to EEGLAB
addpath('/home/soumyab/work/nexstem/organized_data/'); % Replace with the correct path to datasets
dataset_name = ['eyes_open_instinct_headset1'  'subject2'  'session2'];

%% Load EEG Dataset
% Load your EEG data file (adjust the file format as needed)
% The dataset should ideally be in `.set` format (EEGLAB's native format)
data_path = (['/home/soumyab/work/nexstem/preprocessed_data/setFiles/raw/' dataset_name '.set']); % Replace with your EEG file path
EEG = pop_loadset(data_path);

% Display the EEG dataset structure
disp(EEG);

%% Complete channel location data
% Check if channel location fields are missing or empty
fields_to_check = {'X', 'Y', 'Z', 'theta', 'radius'};
need_to_load_chanlocs = false;

for i = 1:numel(EEG.chanlocs)
    for j = 1:numel(fields_to_check)
        if ~isfield(EEG.chanlocs(i), fields_to_check{j}) || isempty(EEG.chanlocs(i).(fields_to_check{j}))
            need_to_load_chanlocs = true;
            break;
        end
    end
    if need_to_load_chanlocs
        break;
    end
end

% Load standard channel locations if needed
if need_to_load_chanlocs
    disp('Missing or incomplete channel locations detected. Loading standard locations...');
    EEG = pop_chanedit(EEG, 'lookup', '/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp');
else
    disp('Channel locations are already complete.');
end


%% Preprocessing: Filter the Data
% Band-pass filter to remove low-frequency drift and high-frequency noise
% Here, we filter between 1 Hz and 50 Hz
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 50);

%% Preprocessing: Re-reference the Data
% Re-reference the EEG data to the average of all channels
EEG = pop_reref(EEG, []);

%% Run ICA
% Perform ICA decomposition to identify independent components
EEG = pop_runica(EEG, 'extended', 1);

% Save the ICA decomposition results
pop_saveset(EEG, 'filename', [dataset_name '_ica_decomposed.set'], 'filepath', '/home/soumyab/work/nexstem/preprocessed_data/setFiles/cleaned/');

%% Visualize ICA Components
% Use EEGLAB's GUI to visualize ICA components and select artifacts
% Check and adjust the number of components to plot
num_components = size(EEG.icawinv, 2);
max_components_to_plot = min(20, num_components); % Up to 20 or the total number available
pop_selectcomps(EEG, 1:max_components_to_plot);
ica_fig = gcf; % Get the current figure handle
ica_fig_path = '/home/soumyab/work/nexstem/eeg/preprocessedData/ica_components.jpeg'; % File path for saving
saveas(ica_fig, ica_fig_path);

% In the GUI, you can select components corresponding to eye-blink or muscle artifacts.

%% Remove Artifact Components
% Remove selected components based on your manual inspection
artifact_components = [1, 3]; % Replace with the components you identify as artifacts
EEG = pop_subcomp(EEG, artifact_components, 0);

% Save the cleaned EEG dataset
pop_saveset(EEG, 'filename', 'dataset_name.set', 'filepath', '/home/soumyab/work/nexstem/preprocessed_data/setFiles/cleaned/');

%% Visualize Cleaned Data
% Plot the EEG data after artifact removal
pop_eegplot(EEG, 1, 1, 1);

%% Export Data for Further Analysis
% Export the cleaned EEG data for further analysis or processing
cleaned_data = EEG.data; % The EEG data matrix (channels x time points)
fs = EEG.srate;          % Sampling frequency
save('/home/soumyab/work/nexstem/preprocessed_data/setFiles/cleaned/cleaned_data.mat', 'cleaned_data', 'fs');
