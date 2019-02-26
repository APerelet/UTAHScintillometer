function dataFiles = findScintFiles_sub(dirInfo)

%Load Variace Data
dirVAR = dir([dirInfo(1).folder, filesep, dirInfo(1).name, filesep, '*.ASC']);
for ii=1:length(dirVAR)
    VARdate(ii) = datenum(dirVAR(ii).name(1:6), 'yymmdd');
end

%Find Unique days
[Days, ~, Ind] = unique(VARdate);
for ii=1:length(Days)
    dataFiles{ii} = dirVAR(Ind==ii);
    displayNames{ii, 1} = ['[',num2str(ii),']'];
    displayNames{ii, 2} = dataFiles{ii}(1).name;
end

%Ask User which data to process
fprintf('\nDisplaying all files.\nNote: only displaying first file found for each day.\n');
tmp = [];
for kk=1:size(displayNames, 1)
    for jj=1:size(displayNames, 2)
        if jj==size(displayNames, 2)
            tmp = [tmp, char(9), displayNames{kk, jj}, char(13)];
            fprintf(tmp);
            tmp = [];
        else
            tmp = [tmp, displayNames{kk, jj}];
        end
    end
end

SOI = input('Please input dates of interest. e.g. [1 3 4:7] or ''0'' for all dates: ');

if ~(length(SOI)==1 && SOI==0)
    dataFiles = dataFiles(SOI);
end