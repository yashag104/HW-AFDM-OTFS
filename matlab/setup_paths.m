function setup_paths()
% SETUP_PATHS  Add every project folder to the MATLAB path.
root = fileparts(mfilename('fullpath'));
folders = {'config', 'common', 'fixed', 'channel', 'afdm', 'otfs', 'ofdm', 'detector', ...
           'estimation', 'sims'};
for i = 1:numel(folders)
    addpath(fullfile(root, folders{i}));
end
end
