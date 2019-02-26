function OMS = loadScintData(dataFiles, ii, OMS)

fprintf(['\n----------------------------------------------------\n',...
    'Loading full day of data. Starting with:\n',...
    dataFiles{ii}(1).name, char(10),...
    '----------------------------------------------------\n']);
for jj=1:length(dataFiles{ii})
    tmp = importdata([dataFiles{ii}(jj).folder, filesep, dataFiles{ii}(jj).name], ',', 29);
    if jj==1
        Data = tmp.data;
        Header = tmp.colheaders;
        Header = ['Timestamp', Header(7:end)];
    else
        Data = [Data; tmp.data];
    end
end
timeStamp = datenum(Data(:, 1)+2000, Data(:, 2), Data(:, 3), Data(:, 4), Data(:, 5), Data(:, 6));
Data = [timeStamp, Data(:, 7:end)];

OMS.MWSC = Data;
OMS.MWSCHeader = Header;