%% Setup Directories and Paths
addpath('/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/'); % EEGLAB path
addpath('/home/soumyab/work/nexstem/organized_data/'); % Dataset path
dataset_name = 'eyes_open_instinct_headset1_subject2_session2'; % Unified dataset name

% Define paths
data_csv_path = '/home/soumyab/work/nexstem/organized_data/eyes_open_instinct_headset1/subject2/session2/data.csv';
raw_set_path = '/home/soumyab/work/nexstem/preprocessed_data/setFiles/raw/';
cleaned_set_path = '/home/soumyab/work/nexstem/preprocessed_data/setFiles/cleaned/';
ica_fig_path = '/home/soumyab/work/nexstem/preprocessed_data/ica_components.jpeg';

%% Load Data
eeg = load(data_csv_path);

%% Create nexEEG Structure
nexEEG.data = transpose(eeg); % EEG data matrix (channels x time points)
nexEEG.srate = 300; % Sampling rate in Hz
nexEEG.nbchan = size(nexEEG.data, 1); % Number of channels
nexEEG.pnts = size(nexEEG.data, 2); % Number of time points
nexEEG.trials = 1; % Continuous data
nexEEG.times = (0:(nexEEG.pnts-1)) / nexEEG.srate * 1000; % Time vector in ms
nexEEG.xmin = min(nexEEG.times) / 1000; % Start time in seconds
nexEEG.xmax = max(nexEEG.times) / 1000; % End time in seconds
nexEEG.setname = dataset_name; % Dataset name
nexEEG.filename = [dataset_name '.set']; % Set file name
nexEEG.filepath = raw_set_path; % File path
nexEEG.comments = 'Created from CSV file. Nexstem data. Eyes open.'; % Comments

% Channel locations
nexEEG.chanlocs = struct( ...
    'labels', {'timestamp', 'T5', 'C3', 'P3', 'O1', 'CMS', 'DRL', 'FZ', 'F3', 'F7', 'FP1', ...
               'T3', 'NC1', 'PZ', 'T6', 'P4', 'O2', 'CZ', 'NC2', 'F4', 'F8', ...
               'T4', 'C4', 'NC3', 'FP2', 'filler'}, ...
    'impedances', {0, 86.72, 665.08, 33.54, 78.30, 824.44, 104.89, 18.46, 106.83, 50.76, ...
                   20.55, 29.16, 54837.68, 70.97, 180.26, 68.89, 69.42, 44.24, ...
                   71482.26, 548.21, 9093.75, 68.71, 287.13, 23253.53, 135189.57, 0});

% Exclude irrelevant channels
exclude_labels = {'timestamp', 'CMS', 'DRL', 'NC1', 'NC2', 'NC3', 'filler'};
channel_labels = {nexEEG.chanlocs.labels};
exclude_indices = ismember(channel_labels, exclude_labels);
nexEEG.data = nexEEG.data(~exclude_indices, :);
nexEEG.chanlocs = nexEEG.chanlocs(~exclude_indices);

% Optional fields
nexEEG.reject = [];
nexEEG.stats = [];
nexEEG.specdata = [];
nexEEG.specicaact = [];
nexEEG.splinefile = '';
nexEEG.icasplinefile = '';
nexEEG.dipfit = [];
nexEEG.saved = 'no';
nexEEG.etc = [];

% ICA-related fields
nexEEG.icaact = [];
nexEEG.icawinv = [];
nexEEG.icasphere = [];
nexEEG.icaweights = [];
nexEEG.icachansind = [];

% Epoch-related fields
nexEEG.epoch = [];
nexEEG.epochdescription = [];
nexEEG.urevent = [];
nexEEG.eventdescription = {};

% Channel-related fields
nexEEG.urchanlocs = nexEEG.chanlocs; % Original channel locations
nexEEG.chaninfo = struct(); % Empty struct for channel metadata

%% Save Raw Data as .set
eeglab; % Start EEGLAB
pop_saveset(nexEEG, 'filename', nexEEG.filename, 'filepath', nexEEG.filepath);

%% Load Saved Dataset
EEG = pop_loadset('filename', nexEEG.filename, 'filepath', nexEEG.filepath);

%% Complete Channel Locations
fields_to_check = {'X', 'Y', 'Z', 'theta', 'radius'};
need_to_load_chanlocs = any(arrayfun(@(chan) any(cellfun(@isempty, struct2cell(rmfield(chan, setdiff(fields(chan), fields_to_check))))), EEG.chanlocs));

if need_to_load_chanlocs
    disp('Missing or incomplete channel locations detected. Loading standard locations...');
    EEG = pop_chanedit(EEG, 'lookup', '/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp');
else
    disp('Channel locations are complete.');
end

%% Preprocessing: Band-pass Filter and Re-reference
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 50); % Band-pass filter
EEG = pop_reref(EEG, []); % Re-reference to average

%% Perform ICA and Save Results
EEG = pop_runica(EEG, 'extended', 1);
pop_saveset(EEG, 'filename', [dataset_name '_ica_decomposed.set'], 'filepath', cleaned_set_path);

%% Visualize ICA Components
num_components = size(EEG.icawinv, 2);
pop_selectcomps(EEG, 1:min(20, num_components));
saveas(gcf, ica_fig_path); % Save ICA component visualization

%% Remove Artifacts
artifact_components = [1, 3]; % Replace with identified components
EEG = pop_subcomp(EEG, artifact_components, 0);

%% Save Cleaned Dataset
pop_saveset(EEG, 'filename', [dataset_name '_cleaned.set'], 'filepath', cleaned_set_path);

%% Visualize Cleaned Data
% Plot the EEG data after artifact removal
pop_eegplot(EEG, 1, 1, 1);

%% Export Cleaned Data
cleaned_data = EEG.data; % Channels x Time Points
fs = EEG.srate; % Sampling Frequency
save(fullfile(cleaned_set_path, 'cleaned_data.mat'), 'cleaned_data', 'fs');

disp('Pipeline completed successfully.');
