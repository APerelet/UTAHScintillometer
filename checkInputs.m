function done = checkInputs(info)

done = 0;
validInputs = ['1'; '0'];

R_Loc = utm2ll(info.Coord_Rx(2), info.Coord_Rx(3), info.Coord_Rx(1));
T_Loc = utm2ll(info.Coord_Tx(2), info.Coord_Tx(3), info.Coord_Tx(1));

fprintf(['\nAre the following values correct?\n', ...
    '\tPath Length: ', num2str(info.L), 'm\n',...
    '\tPath Orientation: ', num2str(info.BeamOrient), 'deg\n',...
    '\tBLS Height [Rx, Tx]: [', num2str(info.LAS_hRx), ', ',num2str(info.LAS_hTx), ']m AGL\n',...
    '\tMWS Height [Rx, Tx]: [', num2str(info.MWS_hRx), ', ',num2str(info.MWS_hTx), ']m AGL\n',...
    '\tRx Location: ', num2str(R_Loc(1)), ' , ', num2str(R_Loc(2)),'\n'...
    '\tTx Location: ', num2str(T_Loc(1)), ' , ', num2str(T_Loc(2)),'\n\n'...
    ]);


while ~done
    check = input('Yes [1] / No [0]:  ', 's');
    
    if isempty(check) | ~any(check==validInputs)
        fprintf('\nInvalid Input, Enter 1 for Yes and 0 for No\n');
    else
        if strcmp(check, '1')
            done = 1;
        else
            error('Please Check siteInfo.m and adjust incorrect values');
        end
    end
end