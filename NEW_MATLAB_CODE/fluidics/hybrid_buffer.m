function hybrid_buffer(handles, mega, MVP2, MVP3, fluid_num, hybrid_t, hybrid_fr)
%             ---Hybridization---
%             (Syringe pump already at very bottom)
%             MVP2 switches to valve position 3. (MVP3)
%             MVP3 switches to valve position with the fluid number.
%             Syringe pump goes to top. (withdrawing)
%             MVP2 switches to valve position 1. (chamber inlet)
%             Syringe pump goes down, with specified flowrate and duration.
%             (hybridizing)
%             After duration has passed, stop the pump.

    fprintf(MVP2, 'aLP03R');
    fprintf(MVP3, ['aLP0', num2str(fluid_num), 'R']);
    % state2, state1, speed2, speed1, onoff
    writeMega(mega, 10, 0, 0, 0, 0, 1);
    fprintf(MVP2, 'aLP08R');
    writeMega(mega, 10, 0, 1, 0, 0, 1);
    fprintf(MVP2, 'aLP01R');
    startTime = clock;
    
    switch hybrid_fr
        case 0
            writeMega(mega, 10, 1, 0, 0, 0, 1);
        case 1
            writeMega(mega, 10, 1, 0, 0, 1, 1);
        case 2
            writeMega(mega, 10, 1, 0, 1, 0, 1);
        case 3
            writeMega(mega, 10, 1, 0, 1, 1, 1);
    end
    
    % TODO: verify that waterSensor(mega) == 0 means no leak is present
    while etime(clock, startTime) < hybrid_t && waterSensor(mega) == 0 && hasPower(mega)     % keep down until wash time is reached, or leak is detected, or power has been cut  
        if bubbleSensor(mega) == 1
            disp('Detected air. Logging the time...');
            fprintf(handles.logfile, '%s: %s\r\n', datestr(now, 0), 'Detected air. Logging the time...');
        end
    end
    
    if ~hasPower(mega)
        % if power has been cut, record the status
        disp('Power has been cut. Waiting to resume...');
        fprintf(handles.logfile, '%s: %s\r\n', datestr(now, 0), 'Power has been cut. Waiting to resume...');
    end
    while ~hasPower(mega)
        % wait until power supply comes back up
    end
    
   % stop the pump
    writeMega(mega, 10, 1, 1, 1, 1, 1);
    pause(1);
    
    if waterSensor(mega) == 1
        % emergency stop
        writeMega(mega, 10, 1, 1, 1, 1, 0);
        drain(handles, mega)
    end
end