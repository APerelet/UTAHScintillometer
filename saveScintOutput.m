function saveScintOutput(OMS, ECData, info)
if ~exist(info.saveDir, 'dir')
    mkdir(info.saveDir);
end

%Organize fields by alphabetical order
OMS = orderfields(OMS);
ECData = orderfields(ECData);

%combine ECData and Scintillometer data to one structure
ScintData.ECData = ECData;
ScintData.OMS = OMS;

%Save File
save([info.saveDir, filesep, ...
    info.siteName, ...  %Site name
    '_', num2str(info.avgPer), 'MinAvg_',... %Averaging period
    info.Coeff,'_',... %MOST Coefficients
    datestr(OMS.MWSC(1,1), 'yyyy_mm_dd')], 'ScintData');