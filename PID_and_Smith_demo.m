% Demonstrates a PID controller that commands velocities of a 2D cursor trying to reach a target.
% Can incorporate feedback latency to illustrate the challenges of control with delayed feedback,
% and use a Smith Predictor to compensate for this.
% (this is written for a teaching demo).
%
% Sergey D. Stavisky March 2021


function pidDemo
    % STUDENTS: START HERE
    % This is the main script; run this for the simulation. Various parameters are defined
    % below, and you can adjust them to see different scenarios play out.
    fprintf('Starting...\n')
    
    % --------------------------------
    %        DEFINE SIMULATION
    % --------------------------------
    % Define simulation parameters
    dt = 0.010; % Step size of the simulation, in seconds. E.g., use 10 ms time steps
    Tmax = 10; % total simulation time (seconds)
    
    % toggle true or false to visualize the controller's (delayed) feedback of where the cursor is 
    % as well as its forward model prediction of where the cursor is.
    showObservedAndPredicted = true; 
%     showObservedAndPredicted = false;

  
    % Latency
    feedbackDelay = 0.250; % The controller has access to the cursor position this many seconds ago.
                           % Fun other thing to play with: Delays of 400 ms or more and it gets unstable using the
                           % default PID controller parameters (if no feedforward model)
%     feedbackDelay = 0; % use this for no delay scenario

    % Define the "Task"
    targetPos = [8; 4]; % in cm desired endpoint (2-d vector is x,y position)
    startPos = [3; 8]; % cursor starts here
    

    % --------------------------------
    %        DEFINE CONTROLLER
    % --------------------------------
    % Define the controller
    K_p = 1.5;
    T_i = 0.35; % Integral time (s)
    T_d = 0.050;

    % Uncomment below for a PI or P Controller
%     T_i = 9999999; % Essentially no Integration
%     T_d = 0; % no Derivative control (note to students: this is often skipped in the
%                                       real-world due to the likelihood of large errors in calculating derivatives)

    % Whether or not to use a Smith predictor?
    % Note: when implemented below, we'll assume the Smith Predictor knows the 
    % true feedbackDelay.
    useSmithPredictor = true;
    modeledFeedbackDelay = feedbackDelay; % what the Smith Predictor thinks the feedback delay is
%     useSmithPredictor = false;
 
    % Define a perturbation
    % The matrix below defines what 2D perturbation vector is applied to the cursor at each time step of the simulation.
    % For this example, having a perturbation that pushes the cursor orthgonally away from the
    % path towards the target helps more vividly demonstrate the problem that feedback latency
    % creates.
    perturbOnsetTime = 0.150; % when the perturbation starts (in seconds)
    perturnOffsetTime = 0.350; % when the perturbation stops (in seconds)
    perturbVec = [-7, -6];
%     perturbVec = [0, 0]; % use this to have no  perturbation

    % now implement this perturbation into the time x steps matrix that gets applied during the simulation
    perturbations = zeros( Tmax/dt + 1, 2 );
    startStep = ceil( perturbOnsetTime / dt ); % ensures it's an integer, for indexing
    endStep = ceil( perturnOffsetTime / dt ); % ensures it's an integer, for indexing
    perturbations(startStep:endStep,:) = repmat( perturbVec, endStep-startStep+1, 1  ) ; % repmat replicates the 1x2 vector across Tx2 matrix so this assignment works


    % --------------------------------
    %        INITIALIZE SIMULATION
    % --------------------------------
    % We're going to save the state of this toy system at every time step for the duration of
    % the simulation.
    % Here I preallocate variables that record the state of the simulation (made code run faster in
    % the past; nowadays the just-in-time compiler does this but it's good practice).
    xLog = zeros( Tmax/dt, 2 ); % will store plant (cursor) position at every time step; this is also used for delayed feedback.
    P = zeros( Tmax/dt, 2 );
    I = zeros( Tmax/dt, 2 );
    D = zeros( Tmax/dt, 2 );
    U = zeros( Tmax/dt, 2 );
    Ypredicted = zeros( Tmax/dt, 2 ); % will store each time step's Smith Predictor Controller's forward model (prediction) of where the cursor is. 
    
    % Initialize the simulation
    t = 0;
    x = startPos;
    xLog(1,:) = startPos;
    
    
    % Initialize the controller
    % Recall that it keeps an integral of error; we'll store that in variable integrErr
    integrErr = [0; 0];  
    prevErr = [0; 0]; % Also record error from previous time step; used to calculate derivative of error ('D' in PID).
    u = [0; 0]; % Manipulated variable; what velocity command output to the cursor
    
    % Creates the figure (it'll be updated at each simulation step later)
    sAx = initFigure( Tmax );
    
    
    % --------------------------------
    %        RUN SIMULATION
    % --------------------------------
    step = 1;
    for t = 0 : dt : Tmax
        % --------------------------------
        % FEEDBACK AVAILABLE will be y
        % --------------------------------
        % Here we simulate what feedback about the plant's state (that is, the cursor's position).
        % is available to the controller.
        observedStep = round( (t - feedbackDelay)/dt ); %round to make it an integer so we can index into past history of positions
        if observedStep < 1
            % trying to look into the past before there's history available (this happens at the start
            % of the simulation). So just use the first available position (we're assuming it was
            % measuring from this position before the simulation started)
            y_observed = xLog(1,:)'; % transpose so it's a column vector as used elsewhere
        else
            y_observed = xLog(observedStep,:)'; % transpose so it's a column vector as used elsewhere
        end

        % --------------------------------
        % PID CONTROLLER IMPLEMENTED HERE
        % --------------------------------
        % note: for convenience and to tie into future state-space model, we're using dimension [2,1] vectors for
        % horizontal and vertical position. However, for this example you can think of each
        % of these dimensions as separate systems, so it's essnetially two parallel single-input,
        % single-output (SISO) systems.
        % Redefine some of the simulation variables in control terms
        SP = targetPos; % Setpoint; where we want to be
        PV = y_observed; % Process Variable; what we measure about the plant we're controlling
        err = SP - PV; % for the vanilla PID controller; this will be overwritten below if the Smith Predictor is used
        
        
        if useSmithPredictor
            % Forward model where it thinks the cursor is. Here we use a simple predictive model:
            % take the recent history of commands we gave since the last observed position of the cursor,
            % integrate them, and add that vector to the last seen position. In other words, based on the commands
            % we've given, where did we move the cursor? This does NOT take into account potential perturbations
            % (which we don't know about and cannot predict).

            % Look back modeledFeedbackDelay ago; what time step was that?
            pastPredictionStep = round( (t - modeledFeedbackDelay)/dt ); %round to make it an integer so we can index into past history of positions
            % What were all the velocity commands we gave between then and now? Dont' allow negative
            % indices, since this is before we have records (i.e., before the simulation started).
            % That's what max( pastPredictionStep, 1 ) accomplishes.
            recentCommandHistory = U( max( pastPredictionStep, 1 ):step-1, : );
            % take the sum of these (and multiply by dt) to get the integrated past history of
            % commands.
            recentSummedCommands = dt.* sum( recentCommandHistory, 1 )'; % sum across columns, element-wise multiply; note transpose into column vector
            y_predicted = PV + recentSummedCommands;            
            
            % log the prediction; this is also used for the Smith Predictor outer loop on line 169
            Ypredicted(step,:) = y_predicted';
            
            % Also calculate the errorOfPrediction; this is the difference between our forward model
            % from modeledFeedbackDelay ago, and PV as observed now (which reveals where the cursor really was
            % feedbackDelay ago, and thus we *hope* matches y_predicted from modeledFeedbackDelay ago.
            if pastPredictionStep < 1
                % trying to look into the past before there's history available (this happens at the start
                % of the simulation). So just use start position; we can assume in the steady-state before
                % the simulation, the system predicted the (stationary) cursor was there.                
                previouslyPredictedY = xLog(1,:)'; % transpose so it's a column vector as used elsewhere
            else
                previouslyPredictedY = Ypredicted(pastPredictionStep,:)'; % transpose so it's a column vector as used elsewhere                
            end
            errorOfPrediction = PV - previouslyPredictedY;
              
            err = SP - (y_predicted + errorOfPrediction);
        end
                

        % Update integral of error
        integrErr = integrErr + (err * dt);
        
        % Calculate derivative of error
        % Note: in the real-world, this is a terrible way of doing it becuase it's prone to
        % numerical instability. One would want to low-pass filter or perhaps even skip this
        % entirely (i.e., just a PI Controller).
        derivErr = (err - prevErr) / dt;
        prevErr = err; % this will be previous error on next step.
        
        % Tracking these if I want to plot the internal components of the PID controller later
        P(step,:) = err;
        I(step,:) = (1/T_i)*integrErr;
        D(step,:) = T_d*derivErr;
        
        % Key step: command a velocity (i.e., manipulated variable).
        % note this is the Standard Form which looks a bit different than the continuous form in
        % the notes.
        u = K_p .* (err + (1/T_i)*integrErr + T_d*derivErr); 
        
        U(step,:) = u; % log commands      
        
        
        % --------------------------------
        %  SIMULATION UPDATES HERE ("physics")
        % --------------------------------
        % Apply the perturbation here
        thisStepPerturbation = perturbations(step,:)'; % trabspose so it's a column vector like other variables we're using
        u_out = u + thisStepPerturbation; % total applied input to the plant is what the controller commands + the noise.

                
        % Display the current state of the simulation
        sAx = plotCurrentState( sAx, t, x, u, thisStepPerturbation, targetPos );
        if showObservedAndPredicted
            if useSmithPredictor
                % It doesn't make sense to plot the forward prediction if there is one, hence this if
                % statement
                plotForwardPrediction( sAx, y_predicted )
            end
            plotObservedCursor( sAx, y_observed )
        end
        xLog(step,:) = x;
        
        
        % Simulation update; input takes effect on next step
        x = x + u_out*dt;
        step = step + 1;
    end
    

    fprintf('Finished\n')
    
    % Uncomment below to see what the three components of the PID controller contributed at
    % each step:
%     figure;
%     tplot = 0 : dt : Tmax;
%     subplot(3,1,1);
%     plot( tplot, P(:,1) );
%     ylabel('P (hor)')
%     
%     subplot(3,1,2);
%     plot( tplot, I(:,1) );
%     ylabel('I (hor)')
%     
%     subplot(3,1,3);
%     plot( tplot, D(:,1) );
%     ylabel( 'D (hor)' )
%     xlabel( 'T (s)' )
end





% --------------------------------
%        HELPER FUNCTIONS
% --------------------------------
% The below functions handle the graphics for visualizing the simulation. You don't need
% to understand them to learn the core lesson of this demonstration, but you may find this
% to be a helpful example of how to exert precise control of graphics in MATLAB.

function sAx = initFigure( Tmax )
    % Initiates the figure used for visualizing the simulation.
    % 
    % Inputs:  
    %   Tmax    how long simulation will run; used to pre-scale the time-plots on left.
    %   
    % Outputs: 
    %   sAx     structure of different handles for various pieces of the figure.
    
    % Visualization assumptions
    xLimits = [0 15]; % horizontal limits of shown workspance
    yLimits = [-2 13]; % vertical limits of shown workspance
    targetDiameter = 1.5; % how big to draw target
    cursorDiameter = 1; % how big to draw cursor(s)
    
     % just to initialize graphics, will update based on simulation in main loop
    cursorPos = [1; 1];
    targetPos = [5; 5]; 
    u = [2; 1];
    
    sAx.figh = figure;
    sAx.figh.Name = 'Controller simulation';
    sAx.figh.Color = 'w';
    
    sAx.axh2D = axes( 'Position', [0.55 0.11 0.4 0.8] ); % puts it on the right of the plot, leaving room for plotting time-varying x and y positions.
    axis square % horizontal and vertical are spaced equally
    title('Overhead view')
    xlabel('Horizontal (cm)')
    ylabel('Vertical (cm)')
    xlim( xLimits )
    ylim( yLimits )
    box on
    sAx.axh2D.FontSize = 16;
        hold on; % otherwise new plotting will overwrite existing objects.

    
    % Initiate the scatter points object that will show the history of where the cursor went.
    % Do this before target and cursor so they are layered visually below and so cursor/target
    % remain visible.
    sAx.hTracks = scatter( nan, nan, 'Marker', '.', 'CData', [0.8 0.8 0.8]  );
    
    % cursor/target will be updated during simulation, this is just to plot them initially
    % note: diameter of the target and cursor are just for visualization; the controller's goal is to go
    % to its center.
    sAx.hTarget = rectangle('Position',[targetPos(1)-0.5*targetDiameter targetPos(2)-0.5*targetDiameter targetDiameter targetDiameter],'Curvature',[1,1]); % That's right, the questionably named rectangle function can be used to draw a circle...                                                               % corner
    sAx.hTarget.FaceColor = [.7 .7 .7];
    sAx.hTarget.EdgeColor = 'none';
    
    sAx.hCursor = rectangle('Position',[cursorPos(1)-0.5*cursorDiameter cursorPos(2)-0.5*cursorDiameter cursorDiameter cursorDiameter],'Curvature',[1, 1]); % That's right, the questionably named rectangle function can be used to draw a circle...
    sAx.hCursor.FaceColor = 'k';
    sAx.hCursor.EdgeColor = 'none';
    
    % Draw the forward-model of cursor prediction
    % initially off-screen; showing it is optional
    sAx.hCursorPredicted = rectangle('Position',[-100-0.5*cursorDiameter -100-0.5*cursorDiameter cursorDiameter cursorDiameter],'Curvature',[1,1]); 
    sAx.hCursorPredicted.FaceColor = [1 0.5 0];
    sAx.hCursorPredicted.EdgeColor = 'none';
    
    % Draw the sensory feedback (delayed) cursor
    % initially off-screen; showing it is optional
    sAx.hCursorObserved = rectangle('Position',[-100-0.5*cursorDiameter -100-0.5*cursorDiameter cursorDiameter cursorDiameter],'Curvature',[1,1]);
    sAx.hCursorObserved.FaceColor = 'none';
    sAx.hCursorObserved.EdgeColor = 'k';
    sAx.hCursorObserved.LineWidth = 1.5;

    % Draw a vector showing the control input u(t)
    % and the addition perturbation vector u_external(t)
    % Using the built-in quiver function to do this,    
    % Make x(t) and y(t) plots
    sAx.arrow = quiver( cursorPos(1), cursorPos(2), u(1), u(2) );
    sAx.arrow.LineWidth = 2;
    sAx.arrow.Color = [1 0.5 0];
    sAx.arrow.MaxHeadSize = 1;
    sAx.arrow2 = quiver( cursorPos(1), cursorPos(2), u(1), u(2) );
    sAx.arrow2.LineWidth = 3;
    sAx.arrow2.Color = [1 0 0];
    sAx.arrow2.MaxHeadSize = 1;
    
    % Put up the time in the simulation    
    sAx.hTime = text( xLimits(1) + 0.02 * range( xLimits ), yLimits(2) - 0.01 * range( yLimits ), sprintf('t=%.2f', 0 ) );
    sAx.hTime.VerticalAlignment = 'top';
    sAx.hTime.FontSize = 14;
    

    % Make X and Y position and target plots
    sAx.axhX = axes( 'Position', [0.08 0.58 0.35 0.4] );
    sAx.xPlot = plot( nan, nan ); % will be updated during simulation
    sAx.xPlot.LineWidth = 2;    
    xlim( [0 Tmax] )
    ylim( xLimits )
    hold on;
    sAx.axhX.FontSize = 14;
    ylabel('Hori. Position')
    % now draw the target coordinate
    sAx.xTargetPlot = plot( xLimits, [targetPos(1), targetPos(1)], 'Color', [0.5 0.5 0.5], 'LineWidth', 1 );    
    
    sAx.axhY = axes( 'Position', [0.08 0.1 0.35 0.4] ); 
    sAx.yPlot = plot( nan, nan ); % will be updated during simulation
    sAx.yPlot.LineWidth = 2;
    xlim( [0 Tmax] )
    ylim( yLimits )
    hold on;
    sAx.axhY.FontSize = 14;
    ylabel( 'Vert. Position' )
    xlabel( 'Time (s)' )
    % now draw the target coordinate
    sAx.yTargetPlot = plot( yLimits, [targetPos(2), targetPos(2)], 'Color', [0.5 0.5 0.5], 'LineWidth', 1 );
    
end

function sAx = plotCurrentState( sAx, t, x, u, u_external, targetPos )
    % Updates the plot with the current state of the simulation
     % 
    % Inputs:  
    %   sAx          Structure of different graphics object handles created by initFigure subfunction.
    %   t            Current simulation time step.
    %   x            2x1 vector of the state of the cursor (it's horizontal and vertical position).
    %   u            The manipulated variable, i.e., velocity commanded to the cursor.
    %   u_external   External velocity applied to the cursor (i.e., perturbation).
    %   targetPos    Where to draw the target.
    %   
    % Outputs: 
    %   sAx          structure of different handles for various pieces of the figure (same as the input;
    %                the handles should not have changed, just their underlying values).
    
    scaleCommandsBy = 0.5; % graphically scales the vectors u and u_external (the drawn arrows) by this amount; helps keep them visible on screen.
    
    
    % update target and cursor position (note: I pull out the target and cursor's widths from their current graphics
    % object.
    sAx.hTarget.Position(1:2) = [targetPos(1) - 0.5*sAx.hTarget.Position(3), targetPos(2) - 0.5*sAx.hTarget.Position(4)];
    sAx.hCursor.Position(1:2) = [x(1) - 0.5*sAx.hCursor.Position(3), x(2) - 0.5*sAx.hCursor.Position(4)];

    % Add "tracks" showing where the cursor went.
    % Note: I do this only every 50 ms to reduce clutter on the plot (this makes it easier to
    % gauge speeds; otherwise at low speeds it looks like a continuous line).
    if ~mod( t, 0.050 )
        sAx.hTracks.XData(end+1) = x(1);
        sAx.hTracks.YData(end+1) = x(2);
    end
    
    % Update the manipulated variable u(t) 
    sAx.arrow.XData = x(1);
    sAx.arrow.YData = x(2);
    sAx.arrow.UData = u(1)*scaleCommandsBy;
    sAx.arrow.VData = u(2)*scaleCommandsBy;
    % and the perturbation vector u_external
    sAx.arrow2.XData = x(1);
    sAx.arrow2.YData = x(2);
    sAx.arrow2.UData = u_external(1)*scaleCommandsBy;
    sAx.arrow2.VData = u_external(2)*scaleCommandsBy;
    
    % Update the time displayed
    sAx.hTime.String =  sprintf('t=%.2f', t );
    
    % Update the plot; I do it directly in the graphics object (instead of replotting a large
    % data vector each time) for performance, but the simpler way would work too.
    sAx.xPlot.XData(end+1) = t;
    sAx.xPlot.YData(end+1) = x(1);
    
    sAx.yPlot.XData(end+1) = t;
    sAx.yPlot.YData(end+1) = x(2);
    
    % Update the target (note: for now it assumes the target does not change during the
    % simulation; this reduces the number of points drawn. Will need to be updated and plotted
    % like the cursor position above if this is going to be time-varying).
    sAx.xTargetPlot.YData = [targetPos(1) targetPos(1)];
    sAx.yTargetPlot.YData = [targetPos(2) targetPos(2)];

    drawnow %pushes the graphics to screen; without this it can appear to "freeze" until the end of the whole simulation.
end

function plotForwardPrediction( sAx, y )
    % Updates the graphics of the forward prediction cursor with input coordinate y
    sAx.hCursorPredicted.Position(1:2) = [y(1) - 0.5*sAx.hCursorPredicted.Position(3), y(2) - 0.5*sAx.hCursorPredicted.Position(4)];
end

function plotObservedCursor( sAx, y )
    % Updates the graphics of the where the controller "sees" the (delayed) cursor position with input coordinate y
    sAx.hCursorObserved.Position(1:2) = [y(1) - 0.5*sAx.hCursorObserved.Position(3), y(2) - 0.5*sAx.hCursorObserved.Position(4)];
end
