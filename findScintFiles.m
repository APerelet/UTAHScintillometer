%Load Scintillometer Data

function [dataFiles, fileFlag] = findScintFiles(info)

dirMWSC = dir([info.rootDir, filesep, 'VAR_MWSC']);
dirUTSapp = dir([info.rootDir, filesep, '*UTSapp']);

if ~isempty(dirUTSapp)
    dataFiles = findScintFiles_sub(dirUTSapp);
    fileFlag = 0;
    
elseif ~isempty(dirMWSC) && isempty(dirUTSapp)
    dataFiles = findScintFiles_sub(dirMWSC);
    fileFlag = 1;
    
elseif isempty(dirMWSC) && isempty(dirUTSapp)
    error(['Cannot find directories for Variance data']);
end