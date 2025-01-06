%% Setup Directories
train_dir = '/home/bhalla/soumyab/eeg/datasets/eeg_alcohol/test';
test_dir = '/home/bhalla/soumyab/eeg/datasets/eeg_alcohol/test';

%% Get File Lists
files_train = dir(fullfile(train_dir, '*.csv')); % List all .csv files in train_dir
files_test = dir(fullfile(test_dir, '*.csv'));   % List all .csv files in test_dir

%% Parallel Pool Setup
% parpool(12); % Open a parallel pool with 12 workers

%% Read Files in Parallel
% Training Data
for i = 1:length(files_train)
    file_path = fullfile(files_train(i).folder, files_train(i).name);
    df_list_train{i} = readtable(file_path); % Read CSV into a table
end

% Testing Data
for i = 1:length(files_test)
    file_path = fullfile(files_test(i).folder, files_test(i).name);
    df_list_test{i} = readtable(file_path); % Read CSV into a table
end

%% Combine Data into Single Tables
combined_df_train = vertcat(df_list_train{:}); % Concatenate all train data
combined_df_test = vertcat(df_list_test{:});   % Concatenate all test data
combined_df = vertcat(combined_df_train, combined_df_test); % Combine train and test

%% Filter Data for Subject Identifiers
EEG_data = combined_df(strcmp(combined_df.('subjectIdentifier'), 'a'), :); % Alcoholics
EEG_data_control = combined_df(strcmp(combined_df.('subjectIdentifier'), 'c'), :); % Control

%% Preview Data
% disp(head(EEG_data));

%% Remove unnecessary column
EEG_data(:, 'Var1') = []; % Remove 'Unnamed: 0' column if it exists

%% Standardize 'matchingCondition' naming
matchingConditionIdx = strcmp(EEG_data.('matchingCondition'), 'S2 nomatch,');
EEG_data.('matchingCondition')(matchingConditionIdx) = {'S2 nomatch'};

%% Standardize 'sensorPosition' naming
sensorMapping = {
    'AF1', 'AF3';
    'AF2', 'AF4';
    'PO1', 'PO3';
    'PO2', 'PO4';
    'FP1', 'Fp1';
    'FP2', 'Fp2';
    'CPZ', 'CPz';
    'FZ', 'Fz';
    'CZ', 'Cz';
    'PZ', 'Pz';
    'FPZ', 'Fpz';
    'AFZ', 'AFz';
    'FCZ', 'FCz';
    'POZ', 'POz';
    'OZ', 'Oz'
};

for i = 1:size(sensorMapping, 1)
    idx = strcmp(EEG_data.('sensorPosition'), sensorMapping{i, 1});
    EEG_data.('sensorPosition')(idx) = {sensorMapping{i, 2}};
end

%% Repeat the process for the control group
EEG_data_control(:, 'Var1') = []; % Remove 'Unnamed: 0' column if it exists

% Standardize 'matchingCondition' naming for the control group
matchingConditionIdxControl = strcmp(EEG_data_control.('matchingCondition'), 'S2 nomatch,');
EEG_data_control.('matchingCondition')(matchingConditionIdxControl) = {'S2 nomatch'};

% Standardize 'sensorPosition' naming for the control group
for i = 1:size(sensorMapping, 1)
    idxControl = strcmp(EEG_data_control.('sensorPosition'), sensorMapping{i, 1});
    EEG_data_control.('sensorPosition')(idxControl) = {sensorMapping{i, 2}};
end
save ('/home/bhalla/soumyab/eeg/preprocessedData/''eeg_alcohol.mat','EEG_data',"EEG_data_control")

%% Preview the data
% disp(head(EEG_data));        % Display first few rows of experimental data
% disp(head(EEG_data_control)); % Display first few rows of control data


%% Unique Value Analysis
% Analyze unique values in the specified column
column_name = 'name';

% Unique values for experimental data
unique_values_Alc = unique(EEG_data.(column_name));
num_unique_values_Alc = numel(unique_values_Alc);

disp(['Unique values in column "', column_name, '" for alcoholics:']);
disp(unique_values_Alc);
disp(['Number of unique values: ', num2str(num_unique_values_Alc)]);

% Unique values for control data
unique_values_Con = unique(EEG_data_control.(column_name));
num_unique_values_Con = numel(unique_values_Con);

disp(['Unique values in column "', column_name, '" for controls:']);
disp(unique_values_Con);
disp(['Number of unique values: ', num2str(num_unique_values_Con)]);

%% Grouping Data by Experimental Condition
% Group experimental data
Alc_S1Obj = EEG_data(strcmp(EEG_data.('matchingCondition'), 'S1 obj'), :);
Alc_S2Match = EEG_data(strcmp(EEG_data.('matchingCondition'), 'S2 match'), :);
Alc_S2Nomatch = EEG_data(strcmp(EEG_data.('matchingCondition'), 'S2 nomatch'), :);

% Group control data
Con_S1Obj = EEG_data_control(strcmp(EEG_data_control.('matchingCondition'), 'S1 obj'), :);
Con_S2Match = EEG_data_control(strcmp(EEG_data_control.('matchingCondition'), 'S2 match'), :);
Con_S2Nomatch = EEG_data_control(strcmp(EEG_data_control.('matchingCondition'), 'S2 nomatch'), :);


%% Perform Trial Length Integrity Check
% For control groups
Con_S1Obj_Index = trial_len_integrity_check(Con_S1Obj);
Con_S2Match_Index = trial_len_integrity_check(Con_S2Match);
Con_S2Nomatch_Index = trial_len_integrity_check(Con_S2Nomatch);

% For alcoholic groups
Alc_S1Obj_Index = trial_len_integrity_check(Alc_S1Obj);
Alc_S2Match_Index = trial_len_integrity_check(Alc_S2Match);
Alc_S2Nomatch_Index = trial_len_integrity_check(Alc_S2Nomatch);

%% Combine Results
% Concatenate results for all alcoholic and control groups
All_Alcs = [Alc_S1Obj_Index; Alc_S2Match_Index; Alc_S2Nomatch_Index];
All_Cons = [Con_S1Obj_Index; Con_S2Match_Index; Con_S2Nomatch_Index];

% Reset index by reassigning row numbers
All_Alcs = sortrows(All_Alcs, 'trialNumber'); % Optional sorting
All_Cons = sortrows(All_Cons, 'trialNumber'); % Optional sorting

%% Preview Data
disp('Preview of All Alcoholic Data:');
disp(head(All_Alcs));

disp('Preview of All Control Data:');
disp(head(All_Cons));

% Group by 'time' and 'sensorPosition', then calculate the mean of 'sensorValue'

% Assume EEG_data is a table with columns: 'time', 'sensorPosition', and 'sensorValue'

% Step 1: Find unique combinations of 'time' and 'sensorPosition'
[uniqueGroups, ~, groupIndices] = unique(EEG_data(:, {'time', 'sensorPosition'}), 'rows');

% Step 2: Calculate the mean 'sensorValue' for each group
meanSensorValues = accumarray(groupIndices, EEG_data.('sensorValue'), [], @mean);

% Step 3: Combine unique groups with their mean sensorValues
EEG_data_agg = [uniqueGroups, table(meanSensorValues, 'VariableNames', {'sensorValue'})];

% Display the aggregated table
disp(EEG_data_agg);


%% Trial Length Integrity Check Function
function nameAndTrialNumber = trial_len_integrity_check(inputTable)
    % Group data by trialNumber and name
    [trialNames, ~, groupIdx] = unique(inputTable(:, {'trialNumber', 'name'}), 'rows');
    disp(unique(groupIdx));  % Unique group indices
    disp(accumarray(groupIdx, 1));  % Count occurrences per group

    
    % Count occurrences for each group
    counts = accumarray(groupIdx, 1);
    trialNames.count = counts;
    
    % Check for data integrity issues
    if any(counts ~= 16384)
        error('Data Integrity problem: One or more arrays are not shaped 256x256');
        disp(trialNames(counts ~= 16384, :));

    end
    
    % Return table with trialNumber and name
    nameAndTrialNumber = trialNames(:, {'trialNumber', 'name'});
end
