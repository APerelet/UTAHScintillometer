%Split concatenated output from MWSC software to correspond to EC data
    %files
%USEFUL ONLY UNTIL RAW DATA PROCESSING CODE WORKS

%Inputs
    %fileName - string for filename w/o extension
    %days - how many days per split file [correspond with UTESpac EC]
    %origDir - string for scintillometer parent directory
    %rmSec - Remove seconds, this is necessary for scintillometer data
    %taken from MWSC output
    %options
        %'VAR' -> include variances
        %'HKD' -> include Housekeeping
        %'FLX' -> include MWSC calculated fluxes

function split_scint_data(fileName, days, origDir, rmSec, varargin)

%Check options
checkStr = {'VAR', 'HKD', 'FLX'};
checkFlag = [0 0 0];
for ii=1:length(checkStr)
    if any(cellfun(@(x) strcmp(x, checkStr{ii}), varargin))
        fileLoc = [origDir, filesep, checkStr{ii}, filesep, 'Concatenated', filesep, ...
            fileName, '.', checkStr{ii}, '.ASC'];
        if exist(fileLoc, 'file')
            %Load only data that is included in options
            data.(checkStr{ii}) = importdata(fileLoc);
            
            checkFlag(ii) = 1;
        
            %Save Headers
            tmp = [checkStr{ii}, 'header'];
            output.MWSC.(tmp) = [{'TIMESTAMP'}, data.(checkStr{ii}).colheaders(7:end)];
            
            %convert date to matlab DATENUM
            tmpOutput.(checkStr{ii}).Time = datenum([data.(checkStr{ii}).data(:, 1)+2000, data.(checkStr{ii}).data(:, 2:6)]);
            
            %Find number of days and indices where to split data
            [tmpOutput.(checkStr{ii}).date, tmpOutput.(checkStr{ii}).index, ~] = ...
                unique(floor(tmpOutput.(checkStr{ii}).Time));
            tmpOutput.(checkStr{ii}).index(end+1) = length(tmpOutput.(checkStr{ii}).Time);
            tmpOutput.(checkStr{ii}).freq = 24*diff(tmpOutput.(checkStr{ii}).Time(1:2));
            
            offsetCheck = mod(floor(datenum(tmpOutput.(checkStr{ii}).Time(1))), 2);
            if offsetCheck~=0
                tmpOutput.(checkStr{ii}).date = [floor(datenum(tmpOutput.(checkStr{ii}).Time(1)))-offsetCheck;tmpOutput.(checkStr{ii}).date];
                %tmpOutput.(checkStr{ii}).Offset = floor(datenum(tmpOutput.(checkStr{ii}).Time(1)));
            else
                %tmpOutput.(checkStr{ii}).Offset = floor(datenum(tmpOutput.(checkStr{ii}).Time(1)))-1;
            end
        else
            %Cannot find file in expected directory.
            error(['File: "', fileLoc, '" Does not exist. Check Inputs and make sure expected Directory Tree is followed'])
        end
    end
end

%Total Number of days
tmp = find(checkFlag==1, 1);
m = mod(length(tmpOutput.(checkStr{tmp}).date), days);
if m~=0
    days_tot = length(tmpOutput.(checkStr{tmp}).date)+m;
else
    days_tot = length(tmpOutput.(checkStr{tmp}).date);
end

for ii=1:days:(days_tot-days)
    for jj=1:length(checkStr)
        if checkFlag(jj)
            
            %Remove Seconds (Scintillometer MWSC output issues)
            if rmSec
                tmpTime1 = tmpOutput.(checkStr{jj}).Time-datenum(second(tmpOutput.(checkStr{jj}).Time)./(3600*24));
            end
            
            %Split time by days
            cutFlag = and(tmpTime1>(tmpOutput.(checkStr{jj}).date(ii)), tmpTime1<=(tmpOutput.(checkStr{jj}).date(ii+days)));
            tmpTime = tmpTime1(cutFlag);
            tmpData = data.(checkStr{jj}).data(cutFlag, 7:end);

            startDay = tmpOutput.(checkStr{jj}).date(ii);
                
            [corrData, corrTime, ~] = timestep_fix(tmpTime, ...
                tmpData, startDay, ...
                days, tmpOutput.(checkStr{jj}).freq, 'datenum');

            output.MWSC.(checkStr{jj}) = [corrTime, corrData];
        end
    end

    saveDir = [origDir, filesep, 'Split'];
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    file_save = [saveDir, filesep, fileName, '_', datestr(corrTime(1), 'yyyy_mm_dd')];
    save([file_save, '.mat'], 'output');
end
    



