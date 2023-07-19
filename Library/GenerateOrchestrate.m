function GenerateOrchestrate(path, Sats)
% Description: this function generates the Orchestrate File given the
% satellites data structure and file path.

N = length(Sats);
M = length(Sats(1).Observable(:));

fileID = fopen(path, "w");


for i = 1 : N

    % Exposure Time -> 2 sec for LEO , otherwise 10
    if Sats(i).SemiMajorAxis < 2
        exposureTime = 2;
    else
        exposureTime = 10;
    end


    % Avoid the Satellite if Observation is too short
    if seconds(Sats(i).Obs_Duration) < minutes(3)
        continue
    end


    % Orchestrate File Generation
    fprintf(fileID,'%s \n',Sats(i).Name);

    takePicture = true;

    count = 0;

    for j = 1 : M

        if Sats(i).Observable(j) && takePicture
            
            RaH = Ra2HHMMSS(Sats(i).Ra(j));
            DecH = degrees2dms(Sats(i).Dec(j));
            DecH(3) = round(DecH(3));

            epoch = Sats(i).Epoch(j) + hours(2) - seconds(exposureTime/2);

            epochH = hour(epoch);
            epochM = minute(epoch);
            epochS = second(epoch);

            fprintf(fileID,'SlewToRaDec,%dh%dm%ds %dd%dm%ds,\n',[RaH, DecH]);
            fprintf(fileID,'WaitUntil,%s %dh%dm%ds \n',datestr(Sats(i).Epoch(j),'mm/dd/yyyy'), [epochH, epochM, epochS]);
            fprintf(fileID,'TakeImage,%d \n',exposureTime);

        end

        takePicture = false;

        count = count + 1;

            if rem(count, 60) == 0
                takePicture = true;
            end

    end

    fprintf(fileID,'\n \n');

end

fclose(fileID);


end