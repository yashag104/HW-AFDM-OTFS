function d = results_dir()
% RESULTS_DIR  Absolute path of the repository's results/ folder (created if missing).
d = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'results');
if ~exist(d, 'dir'), mkdir(d); end
end
