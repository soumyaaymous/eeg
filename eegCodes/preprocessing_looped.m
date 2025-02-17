%% Setup Directories
addpath('/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/'); % Replace with the correct path to EEGLAB
addpath('/home/soumyab/work/nexstem/organized_data/'); % Replace with the correct path to datasets
dataset_name = ["eyes_closed_instinct_headset1", "eyes_open_instinct_headset1", ...
                "eyes_closed_instinct_headset2", "eyes_open_instinct_headset2"];


%% Loop over all datasets

for i=1:length(dataset_name)
current_dataset = dataset_name(i); 
base_path = "/home/soumyab/work/nexstem/organized_data/" + current_dataset;

% Get the list of subjects (folders in current_dataset)
subjects = dir(base_path);

% Filter out non-folders and hidden files (like . and ..)
subjects = subjects([subjects.isdir]); % Keep only directories
subjects = subjects(~startsWith({subjects.name}, '.')); % Exclude hidden files

for i = 1:length(subjects)
    current_subject = subjects(i).name; % Get subject folder name
    subject_path = fullfile(base_path, current_subject); % Full path to the subject folder
    
    % Get the list of sessions within the subject folder
    sessions = dir(subject_path);
    sessions = sessions([sessions.isdir]); % Keep only directories
    sessions = sessions(~startsWith({sessions.name}, '.')); % Exclude hidden files
    
    % Inner loop: Iterate through each session
    for j = 1:length(sessions)
        current_session = sessions(j).name; % Get session folder name
        session_path = fullfile(subject_path, current_session); % Full path to the session folder
        
        % Display the current session being processed
        fprintf('Processing Subject: %s, Session: %s\n', current_subject, current_session);
        


eeg = load(['/home/soumyab/work/nexstem/organized_data/' + current_dataset + '/' + current_subject + '/' + current_session + '/data.csv']);

%% Save as .set File
% Specify the file path to save the .set file
save_path = '/home/soumyab/work/nexstem/nexstem_datasets/setFiles/raw/'; % Replace with your desired save location
save_filename = [current_dataset + '.set']; % Replace with your desired file name


%% Load nexEEG Data
% Replace 'your_eeg_file.mat' with your actual .mat file path
%mat_file_path = ['/home/soumyab/work/nexstem/eeg/preprocessedData/' dataset_name '.mat'];
%data_struct = load(mat_file_path); %time vs channels

% Assuming the variable name for nexEEG data is 'eeg_data'
% Replace 'eeg_data' with the actual variable name in your .mat file
nexEEG.data = transpose(eeg);  % nexEEG data matrix (channels x time points)

%% Input Essential Information
% Sampling rate (in Hz)
nexEEG.srate = 300;  % Example: 256 (Fill this with your actual sampling rate)

% Number of channels
nexEEG.nbchan = size(nexEEG.data, 1);

% Number of time points
nexEEG.pnts = size(nexEEG.data, 2);

% Number of epochs
% If continuous data, set trials = 1
% If epoched data, provide the number of epochs
nexEEG.epochs = 1;  % Example: 1 for continuous data or number of epochs

% Time vector (in milliseconds)
nexEEG.times = (0:(nexEEG.pnts-1)) / nexEEG.srate * 1000; % Adjust if epochs are present

nexEEG.trials = 1;  % Trials: number of repeats of the entire protocol that a subject experiences

% Required fields
nexEEG.filename = [current_dataset '.set']; % Replace with your desired file name
nexEEG.filepath = '/home/soumyab/work/nexstem/nexstem_datasets/setFiles/'; % Replace with your desired save location
nexEEG.xmin = min(nexEEG.times) / 1000; % Start time in seconds
nexEEG.xmax = max(nexEEG.times) / 1000; % End time in seconds
nexEEG.subject = 'subject1'; % Replace as needed
nexEEG.condition = 'eyes_closed'; % Replace as needed
nexEEG.group = 'nexstem'; % Replace as needed
nexEEG.session = 1; % Replace as needed


% Channel locations (use a standard template or provide custom locations)
% Example: Use nexEEGLAB's standard-10-5-cap385.elp file
% Define nexEEG.chanlocs structure
nexEEG.chanlocs = struct( ...
    'labels', {'timestamp', 'T5', 'C3', 'P3', 'O1', 'CMS', 'DRL', 'FZ', 'F3', 'F7', 'FP1', ...
               'T3', 'NC1', 'PZ', 'T6', 'P4', 'O2', 'CZ', 'NC2', 'F4', 'F8', ...
               'T4', 'C4', 'NC3', 'FP2', 'filler'}, ... % Channel labels
    'impedances', {0, 86.72, 665.08, 33.54, 78.30, 824.44, 104.89, 18.46, 106.83, 50.76, 20.55, ... 
                   29.16, 54837.68, 70.97, 180.26, 68.89, 69.42, 44.24, 71482.26, 548.21, 9093.75, ...
                   68.71, 287.13, 23253.53, 135189.57, 0}, ... % Impedance values in kΩ. Hard coded now, change this later xxxx
    'X', [], ... % Placeholder for X-coordinates (if available)
    'Y', [], ... % Placeholder for Y-coordinates (if available)
    'Z', [], ... % Placeholder for Z-coordinates (if available)
    'theta', [], ... % Placeholder for polar angle (if available)
    'radius', [] ... % Placeholder for radius (if available)
);

% Define channels to exclude
exclude_labels = {'timestamp','CMS', 'DRL', 'NC1', 'NC2', 'NC3', 'filler'}; % Labels to exclude
channel_labels = {nexEEG.chanlocs.labels}; % Extract channel labels as a cell array
exclude_indices = ismember(channel_labels, exclude_labels); % Logical array for excluded channels

% Remove excluded channels from nexEEG.data
nexEEG.data = nexEEG.data(~exclude_indices, :); % Keep only the valid channels

% Remove excluded channels from nexEEG.chanlocs
nexEEG.chanlocs = nexEEG.chanlocs(~exclude_indices);

% Remove corresponding impedances (if present)
% Verify 'impedances' field exists and filter it
if isfield(nexEEG.chanlocs, 'impedances')
    for i = 1:numel(nexEEG.chanlocs)
        nexEEG.chanlocs(i).impedances = nexEEG.chanlocs(i).impedances; % Ensure valid data persists
    end
end

%% Verify the Result
disp('Remaining Channels:');
disp({nexEEG.chanlocs.labels});
disp(['New Data Size: ', num2str(size(nexEEG.data, 1)), ' channels x ', num2str(size(nexEEG.data, 2)), ' time points']);

%% Add coordinates to channels
%nexEEG = pop_chanedit(EEG, 'lookup', '/home/soumyab/work/nexstem/eeg/eegCodes/eeglab/plugins/dipfit/standard_BESA/standard-10-5-cap385.elp');


%% Add Event Markers (Optional)
% Provide event information (type, latency, duration)
% Example:
% nexEEG.event(1).type = 'stimulus';
% nexEEG.event(1).latency = 128;  % Latency in samples
% nexEEG.event(1).duration = 0;   % Duration in samples
nexEEG.event = [];  % Leave empty if no event markers are present

%% Add Dataset Metadata
% Dataset name
nexEEG.setname = current_dataset;  % Example: 'My nexEEG Data'

% Comments or additional metadata (optional)
nexEEG.comments = 'Created from .mat file. nexstem data. eyes closed. sub1.';  % Add your own comments

%% Preprocessing Information
% Record any preprocessing steps applied to the data
% Example: Band-pass filter (1-50 Hz)
nexEEG.history = 'removed cms,drl,nc and timestamp column';%'Band-pass filtered (1-50 Hz)'

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

nexEEG.filename = save_filename; % Name of the .set file
nexEEG.filepath = save_path; % Path to save the file




% Save the nexEEG data as a .set file
eeglab; % Start nexEEGLAB to ensure functions are initialized
pop_saveset(nexEEG, 'filename', save_filename, 'filepath', save_path);

%% Verify Saved File
% Load the .set file back to ensure everything was saved correctly
%loaded_nexEEG = pop_loadset('filename', save_filename, 'filepath', save_path);
%disp('nexEEG dataset successfully saved and loaded!');

    end %ends session

end %ends subjects

end %ends dataset_name

