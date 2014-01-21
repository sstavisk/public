% CreateMfunction.m
%
% Creates a template .m file with a header such as this one containing
% a description, USAGE:, INPUTS:, EXAMPLE:, OUTPUTS, and signature section.
% Then opens the file for editing using the editor specified in the last 
% cell.
%
% USAGE: mfilePath = CreateFunction( funcName )
%
% EXAMPLE:
%         CreateMfunction( 'AddEndOfMovementTime', 'path', [pwd '/Kinematics_Analysis'], 'inputs', {'Robj', 'alignParams'}, 'outputs', 'Robj')
%
% INPUTS:
%         funcName    name of the function you want create. 
%         (funcpath)  (optional) where you want this to be created. Default
%                     is current working directory.
%         (inputs)    (optional) Cell array of names of input arguments
%         (outputs)   (outputs)  Cell array of names of output arguments
%
% OUTPUTS:
%         mfilePathname   pathname of where this functon was created.
%
% Created by Sergey Stavisky on 6 February 2012
% Last modified by Sergey Stavisky on 14 February 2012

function mfilePath = CreateMfunction( funcName, varargin )
    % HARDCODED PARAMETERS
    AUTHOR = 'Sergey Stavisky'; % Set this to be your name for author signature.
    

    %% Process optional and default parameters
    def.funcpath = pwd;
    def.inputs = {'in1'};
    def.outputs = {'out1'};
    assignargs( def, varargin ); % Uses Dan's assignargs package
    
    if funcpath(end) ~= filesep %#ok<NODEF>
        funcpath(end+1) = filesep;
    end
    
    if ~iscell( inputs )
        inputs = {inputs}; % sometimes happens if there is just 1 and user forgot to put it into a cell
    end
    if ~iscell( outputs )
        outputs = {outputs};
    end
    
    
    %% Create a .m file for writing
    mfilePath = [funcpath funcName '.m'];

    % Error if this function already exists in the target path
    uhoh = dir( mfilePath );
    if ~isempty( uhoh )
        error('A file %s already exists. Aborting!', mfilePath);
    else
        % Warn if this function already exists somewhere else on the path
        uhoh = which( funcName );
        if ~isempty( uhoh )
            fprintf('Warning! The <funcName> you''ve specified might shadow/be shadowed by %s.\n', uhoh )
            reply = input(' o you still want to create this function? (y/n) ', 's');
            if ~strcmpi( reply, 'y') 
                fprintf('Aborting.\n')
                mfilePath = [];
                return
            end
        end %f ~isempty( uhoh )
    end %if ~isempty( uhoh )
    
    % Create the file
    fid = fopen( mfilePath, 'w' );
    
    %% Write the various sections
    
    fprintf( fid, '%% %s.m\n%', funcName );
    fprintf( fid, '%%\n' );
    fprintf( fid, '%% (description to come)\n');
    fprintf( fid, '%%\n' );
    
    % USAGE:
    fprintf( fid, '%% USAGE: [ ');
    for i = 1 : numel( outputs )
        if i > 1 
            fprintf( fid, ', ');
        end
        fprintf( fid, '%s', outputs{i} ) ;
    end    
    fprintf( fid, ' ] = %s( ', funcName );
    
    for i = 1 : numel( inputs )
        if i > 1 
            fprintf( fid, ', ');
        end
        fprintf( fid, '%s', inputs{i} );
    end
    fprintf( fid, ' )\n');


    % EXAMPLE
    fprintf( fid, '%%\n%% EXAMPLE:\n%%\n' );
    

    
    % INPUTS:
    fprintf( fid, '%% INPUTS:\n' );
    for i = 1 : numel( inputs )
        
        if strcmp( inputs{i}, 'varargin' )
            fprintf( fid, '%%   %-25s \n', 'OPTIONAL ARGUMENT-VALUE PAIRS:' ); 
            fprintf( fid, '%%     %-25s \n', '' );
        else
            fprintf( fid, '%%     %-25s \n', inputs{i} );
        end
       
    end
    fprintf( fid, '%%\n' );
    
    % OUTPUTS:
    fprintf( fid, '%% OUTPUTS:\n' );
    for i = 1 : numel( outputs )
        fprintf( fid, '%%     %-25s \n', outputs{i} );
    end
    fprintf( fid, '%%\n' );
    
    % AUTHOR SIGNATURE
    fprintf( fid, '%% Created by %s on %s\n\n', ...
        AUTHOR, datestr( now, 'dd mmm yyyy' ) );
    
    % FUNCTION SIGNATURE AND END
    fprintf( fid, 'function [ ' );
    for i = 1 : numel( outputs )
        if i > 1 
            fprintf( fid, ', ');
        end
        fprintf( fid, '%s', outputs{i} ) ;
    end    
    fprintf( fid, ' ] = %s( ', funcName );
    
    for i = 1 : numel( inputs )
        if i > 1 
            fprintf( fid, ', ');
        end
        fprintf( fid, '%s', inputs{i} );
    end
    fprintf( fid, ' )\n' );
    
    fprintf( fid, '\n\n\n\n\n\n\n' );
    fprintf( fid, 'end' );
    
    
    %% Close out the file 
    fclose( fid );
    fprintf( 1, '[%s] Created file %s\n', mfilename, mfilePath );
    
    %% Open the file for editing
    % ATTN: Non-Matlab Editor (e.g. Vim) users will want to do change this
    % line to do a system call to their editor of choice.
    edit( mfilePath )
    
    
end %function mfilePath = CreateFunction( funcName, varargin )
