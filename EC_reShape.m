function output = EC_reShape(OMS, ECData, info)

%Find fieldnames
fields = fieldnames(ECData);

flag = cell2mat(cellfun(@(x) ~isempty(strfind(x, 'Time')), fields, 'UniformOutput', 0));
if any(flag)
    %Get index that matches Scintillometer data start Index
    [~, ECStartInd] = min(abs(OMS.MWSC(1,1)-ECData.(fields{flag})));
    
    startCheck = mod(ECData.(fields{flag})(ECStartInd, 1), 1);
    if startCheck==0
        ECStartInd = ECStartInd +1;
    end
    %Get index that matches scintillometer data end
    [~, ECEndInd] = min(abs(OMS.MWSC(end,1)-ECData.(fields{flag})));
else
    error('Cannot find Time field in ECData Structure.');
end

%EC Data
expandCoef = info.ECavgPer/info.avgPer;
if mod(expandCoef, 1)~=0
    error(['A scintillometer averaging time of: ', num2str(info.ScintavgPer),...
        ' minutes',char(10),'is not compatible with an Eddy covariance averaging time of: ',...
        num2str(info.ECavgPer), ' minutes',char(10),...
        'Qoutient between scintillometer and eddy covariance averaging times', char(10),'must be an integer'])
end

for ii=1:length(fields)
    tmp = expandVec(ECData.(fields{ii})(ECStartInd:ECEndInd), expandCoef);
    output.(fields{ii}) = tmp;
end
% % time = ECData.data(ECStartInd:ECEndInd, 1);
% % data = expandVec(ECData.data(ECStartInd:ECEndInd, 2:end), expandCoef);

% % output.data = [time, data];
% % output.Header = ECData.dataHeader;