%Load data

function [OMS, EC, flag] = load_Data(info, index, OMS)

%load Scint data
Scint = load([info.OMSdatDir, filesep, info.dirInfoOMS(index).name]);

%check for EC data for same day range
for ii=1:length(info.dirInfoEC)
    if ~info.dirInfoEC(ii).isdir
        if strcmp(info.dirInfoEC(ii).name(end-13:end-4), info.dirInfoOMS(index).name(end-13:end-4))
            indexEC = ii;
            break;
        end
    end
end
%load EC data
file_tmp = [info.ECdatDir, filesep, info.dirInfoEC(indexEC).name];
if exist(file_tmp)
    EC = load(file_tmp);
    EC = EC.output;
    flag = 0;
else
    flag = 1;
    EC = NaN;
end

fieldname = fieldnames(Scint.output);
for ii=1:length(fieldname)
    OMS.(fieldname{ii}) = Scint.output.(fieldname{ii});
end

