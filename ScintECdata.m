%Average of all towers for Scintillometer processing from UTESpac Output
%Need Timestamp, Cp, Lv [J / g], rho, T [K], P [Pa], q [kg / kg], u_star

function ScintECdata(rootDir,height, saveDir)

dirInfo = dir(rootDir);
fileNames = extractfield(dirInfo, 'name');
isSite = cellfun(@(x) ~isempty(strfind(x, 'site')), fileNames);

sites = fileNames(isSite);

if isempty(sites)
   error(['Could not find any UTESpac formatted sites in directory:', ...
       newline, rootDir]);
end

for ii=1:length(sites)
    SOI = input(['Use site: ', sites{ii}, '?']);
    if SOI
        EC.(sites{ii}) = getUTESpacData(rootDir);
        if ii==1
            timeStamp = EC.(sites{ii}).H(:, 1);
        end

        fields = fieldnames(EC.(sites{ii}));

        %%%%%%%% TEMP
        if ii==3
            offset = 420/30;

            Datafields = cell2mat(cellfun(@(x) ~iscell(EC.(sites{3}).(x)), fields, 'uni', 0));
            tmp = cellfun(@(x) ...
                [EC.(sites{3}).(x)(:, 1), ...
                    [EC.(sites{3}).(x)(1:(4*48), 2:end); ...
                    nan*ones(offset, size(EC.(sites{3}).(x)(:, 2:end),2));...
                    EC.(sites{3}).(x)((4*48+1):(end-offset), 2:end)]],...
                fields(Datafields), 'uni', 0);

            cntr = 1;
            for jj=1:length(Datafields)
                if Datafields(jj)
                    EC.(sites{3}).(fields{jj}) = tmp{cntr};
                    cntr = cntr+1;
                end
            end
        end
        %%%%%%%% TEMP

        %Mean tables
        meanTables = find(cellfun(@(x) ~isempty(strfind(x, sites{ii}(5:end))), fields));

        %Find Correct Data Columns
        LvCol = find(cellfun(@(x) ~isempty(strfind(x, [num2str(height), 'm Lv(J/g)'])), EC.(sites{ii}).LHfluxHeader));

        PCol = find(cellfun(@(x) ~isempty(strfind(x, ['Pressure_',num2str(height)])), EC.(sites{ii}).(fields{meanTables(2)})(1, :)));

        H2O_Col = find(cellfun(@(x) ~isempty(strfind(x, ['H2O_',num2str(height)])), EC.(sites{ii}).(fields{meanTables(2)})(1, :)));

        T_fwCol = find(cellfun(@(x) ~isempty(strfind(x, ['fw_', num2str(height)])), EC.(sites{ii}).(fields{meanTables(2)})(1, :)));
        T_sonCol = find(cellfun(@(x) ~isempty(strfind(x, ['T_Sonic_', num2str(height)])), EC.(sites{ii}).(fields{meanTables(2)})(1, :)));

        tableNum = 1;

        if isempty(PCol)
            PCol = find(cellfun(@(x) ~isempty(strfind(x, ['Pressure_',num2str(height)])), EC.(sites{ii}).(fields{meanTables(6)})(1, :)));
            H2O_Col = find(cellfun(@(x) ~isempty(strfind(x, ['H2O_',num2str(height)])), EC.(sites{ii}).(fields{meanTables(6)})(1, :)));

            T_fwCol = find(cellfun(@(x) ~isempty(strfind(x, ['fw_', num2str(height)])), EC.(sites{ii}).(fields{meanTables(6)})(1, :)));
            T_sonCol = find(cellfun(@(x) ~isempty(strfind(x, ['T_Sonic_', num2str(height)])), EC.(sites{ii}).(fields{meanTables(6)})(1, :)));

            tableNum = 5;
        end

        uStar_Col = find(cellfun(@(x) ~isempty(strfind(x, [num2str(height), 'm :sqrt(uPF''wPF''^2+vPF''wPF''^2)'])), EC.(sites{ii}).tauHeader));

        %Air Density
        rho(:, ii) = EC.(sites{ii}).H(:, 2);
        %Air heat capacity
        Cp(:, ii) = EC.(sites{ii}).H(:, 3);
        %Finewire
        T(:, ii) = EC.(sites{ii}).(fields{meanTables(tableNum)})(:, T_fwCol);    
        %Use sonic temperature if finewire does not exist
        T(isnan(T(:, ii)), ii) = EC.(sites{ii}).(fields{meanTables(tableNum)})(isnan(T(:, ii)), T_sonCol);   
        %Convert temperature to Kelvin
        if nanmean(T(:, ii))<200
            T(:, ii) = T(:, ii)+273.15;
        end
        %Latent heat of vaporization
        Lv(:, ii) = EC.(sites{ii}).LHflux(:, LvCol);
        %Pressure
        P(:, ii) = EC.(sites{ii}).(fields{meanTables(tableNum)})(:, PCol).*1000;

        %H2O
        H2O(:, ii) = EC.(sites{ii}).(fields{meanTables(tableNum)})(:, H2O_Col)./rho(:, ii)./1000;

        %u_star
        uStar(:, ii) = EC.(sites{ii}).tau(:, uStar_Col);
    end
end

ScintEC.data = [timeStamp, nanmean(rho, 2), nanmean(Cp, 2), nanmean(Lv, 2), nanmean(T, 2), nanmean(P, 2), nanmean(H2O, 2), nanmean(uStar, 2)];
ScintEC.dataSTD = [timeStamp, nanstd(rho, 1, 2), nanstd(Cp, 1, 2), nanstd(Lv, 1, 2), nanstd(T, 1, 2), nanstd(P, 1, 2), nanstd(H2O, 1, 2), nanstd(uStar, 1, 2)];
ScintEC.dataHeader = {'TIMESTAMP', 'rho', 'Cp', 'Lv', 'T', 'P', 'H2O', 'u_star'};

save([saveDir, filesep, 'EC_MetParams'], 'ScintEC');