function OMS = loadScintData(dataFiles, fileFlag, ii)

fprintf(['\n----------------------------------------------------\n',...
    'Loading full day of data. Starting with:\n',...
    dataFiles{ii}(1).name, char(10),...
    '----------------------------------------------------\n']);

if fileFlag
    for jj=1:length(dataFiles{ii})
        %Old MWSC software header
        tmp = importdata([dataFiles{ii}(jj).folder, filesep, dataFiles{ii}(jj).name], ',', 29);
        %New MWSC software header
        if ~isstruct(tmp)
            tmp = importdata([dataFiles{ii}(jj).folder, filesep, dataFiles{ii}(jj).name], ',', 30);
        end
        if jj==1
            Data = tmp.data;
            Header = tmp.colheaders;
            Header = ['Timestamp', Header(7:end)];
        else
            Data = [Data; tmp.data];
        end
    end
else
    for jj=1:length(dataFiles{ii})
       tmp = importdata([dataFiles{ii}(jj).folder, filesep, dataFiles{ii}(jj).name], ',');
        if strfind(dataFiles{ii}(jj).name, 'header')
            Data = tmp.data;
            Header = tmp.colheaders;
            Header = ['Timestamp', Header(7:end)];
        else
            Data = [Data; tmp.data];
        end
    end
end
%Clear bad data (When Date is 01 01 01 -> Not sure what this means, never happened before CFOG)
badFlag = sum(Data(:, 1:3)==[01, 01, 01], 2)==3;
Data(badFlag, :) = [];

timeStamp = datenum(Data(:, 1)+2000, Data(:, 2), Data(:, 3), Data(:, 4), Data(:, 5), Data(:, 6));
Data = [timeStamp, Data(:, 7:end)];

OMS.MWSC = Data;
OMS.MWSCHeader = Header;