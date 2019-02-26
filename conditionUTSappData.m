%fill any missing data gaps

function [OMS, ECDataCut] = conditionUTSappData(OMS, ECData, info)
fprintf('\nConditioning data...\n');

%Get fields from scintillometer data
firstDay = floor(OMS.MWSC(1, 1));


%despike data
datatmp = deSpike(OMS.MWSC, info, [1]);


%Fill missing timesteps
time = datatmp(:, 1);
%Clean seconds from timestamp
time = datenum(datestr(time, 'yymmddHHMM'), 'yymmddHHMM');
datatmp = datatmp(:, 2:end);
[datatmp, time, ~] = timestep_fix(time, datatmp, firstDay, 1, info.freq, 'datenum');

%Average data
datatmp = average(datatmp, info.avgPer);
dt = info.freq*info.avgPer*60;
if mod(dt, 1)
    error('time spacing needs to be an integer');
end
timetmp = time(dt:dt:end);
%Recreate structure
OMS.MWSC = [timetmp, datatmp];

%Cut ECData to match times of OMS data
ECDataCut = EC_reShape(OMS, ECData, info);