%load Scint Data

function outputStruct = getScintData(fold, ProcessedFold)

%Folder with processed data
%ProcessedFold = 'Processed';
%If no folder exists, throw error
if ~exist([fold, filesep, ProcessedFold], 'dir')
    error(['Directory:', char(10), [fold, filesep, ProcessedFold], ...
        char(10), 'Does not exist.']);
end

%Fir Info
dirInfo = dir([fold, filesep, ProcessedFold, filesep, '*.mat']);
checkScint = 0;

%Display files names to screen
for ii=1:length(dirInfo)
    fprintf(['[',num2str(ii),']', char(9), dirInfo(ii).name, char(10)]);
end

rows = input('Plese input dates of interest. e.g. [1 3 4:7] or ''0'' for all dates: ');clc;
% if '0' input, make rows of interest equal to all possible dates
if rows == 0
    rows = 1:numel(dirInfo);
end

for ii=rows
    load([fold, filesep, ProcessedFold, filesep, dirInfo(ii).name]);
    if ~exist('ScintData', 'var')
        error(['Incorrect Structure format for scintillometer data. \n',...
            'Format should be <ScintData.OMS>']);
    end
    field_namesScint = fieldnames(ScintData.OMS);
    if ~checkScint
        for kk=1:length(field_namesScint)
            outputStruct.Scint.(field_namesScint{kk}) = ScintData.OMS.(field_namesScint{kk});
        end
        checkScint = 1;
    else
        %Remove Weighting function frmo field names since one version of it
        %is enough
        flag = ~cell2mat(cellfun(@(x) ~isempty(strfind(x, 'WeightFunc')), field_namesScint, 'UniformOutput', 0));
        field_namesScint = field_namesScint(flag);
        for kk=1:length(field_namesScint)
            if isempty(strfind(field_namesScint{kk}, 'Header'))
                outputStruct.Scint.(field_namesScint{kk}) = ...
                    [outputStruct.Scint.(field_namesScint{kk}); ScintData.OMS.(field_namesScint{kk})];
            end
        end
    end
end