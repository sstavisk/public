% SexyAxes.m
%
% Makes pretty axes out of the axes of a regular MATLAB plot.
% The new axes are drawn as line objects and consist of outward tick, 
% non-connecting X and Y axes.
%
% USAGE: [ axh ] = SexyAxes( axh, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     axh                       handle of MATLAB figure axis you want spruced up
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%     xTicks                    Draw custom ticks here
%     yTicks                    Draw custom ticks here
%     xTickLabels               Custom labels for custom xTicks
%     yTickLabels               Custom labels for custom yTicks
%     xInvisLim                 the true x limits (but shown limits will range from input axis uses)
%     yInvisLim                 the true y limits (but shown limits will be what input axis uses)
%     
%                               
%
% OUTPUTS:
%     axh                       the axis handle
%     h                         structure of handles created
%
% Created by Sergey Stavisky on 20 Sep 2013

function [ axh, h ] = SexyAxes( axh, varargin )

    %% Parameters that can be overwritten when calling this funciton
    def.xTicks = get( axh, 'XLim' );
    def.yTicks = get( axh, 'YLim' );
    def.xTickLabels = [];
    def.yTickLabels = [];
    def.xColor = get( axh, 'XColor' );
    def.yColor = get( axh, 'YColor' );
  
    def.xInvisLim = [];
    def.yInvisLim = [];
    
    % aesthetics
    def.expandFactor = 1.15; % by default, expand the space by 15% to create the invisible limits
    def.axisExpandFactor = 1.05; % by default, the new axes will be at the 5% expanded of input limits
    def.LineWidth = 2;
    def.tickLength = 0.01; % fraction of total invsible limits range
    def.tickFontSize = 18;
    
    
    % Plumbing
    def.defaultMATLABfontsize = 10; % when you see this fontsize, make it bigger.
    
    assignargs( def, varargin );
    if isempty( xTickLabels )
         xTickLabels = arrayfun(@mat2str, xTicks, 'UniformOutput', false);
    end
    if isempty( yTickLabels )
        yTickLabels = arrayfun(@mat2str, yTicks, 'UniformOutput', false);
    end
    %% 
    % Compute what the new invisible axes limits will be (this will determine how much 'empty
    % space' there is around the visible axes
    if isempty( xInvisLim )
        inXrange =  max( xTicks) - min( xTicks );
        xInvisLim = [min(xTicks) - (expandFactor-1) * inXrange, max(xTicks) + (expandFactor-1) * inXrange];
    end
    if isempty( yInvisLim )
        inYrange =  max( yTicks) - min( yTicks );
        yInvisLim = [min(yTicks) - (expandFactor-1) * inYrange, max(yTicks) + (expandFactor-1) * inYrange];
    end
    
    
    % Make existing axes invisible
    % If a default MATLAB figure is sent to here with the ugly gray figure background, then
    % removing axis visibility will make the whole thing gray. As a workaround, if it detects
    % gray figure color, it sets it to white.
    if ~any( get( gcf, 'Color' ) ~= [.8 .8 .8] )
        set( gcf, 'Color', [1 1 1] )
    end
    set( axh, 'Visible', 'off' );
    % Expand to invisible limits
    set( axh, 'XLim', xInvisLim, 'YLim', yInvisLim)
   
    % Where new axes are going
    xAxLoc = [min(xTicks) - (axisExpandFactor-1) * inXrange, max(xTicks) + (axisExpandFactor-1) * inXrange];
    yAxLoc = [min(yTicks) - (axisExpandFactor-1) * inYrange, max(yTicks) + (axisExpandFactor-1) * inYrange];
    
    
    % Draw the X axis
    h.xbase = line( [min(xTicks) max(xTicks)], [yAxLoc(1) yAxLoc(1)], 'Color', xColor, ...
        'LineWidth', LineWidth, 'LineSmoothing', 'on');
    % how long should each tick be?
    xTickLen = range( yInvisLim ) * tickLength;
    for i = 1 : numel( xTicks )
        h.xticks(i) = line( [xTicks(i) xTicks(i)], [yAxLoc(1)-xTickLen yAxLoc(1)], 'Color', xColor, ...
            'LineWidth', LineWidth', 'LineSmoothing', 'on');
        % tick label
        h.xtickLabels(i) = text( xTicks(i), yAxLoc(1)-xTickLen, xTickLabels{i}, ...
            'Color', xColor, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
            'FontSize', tickFontSize );  
    end
    
    % Draw X label
    % pull what the text should be from the (invisible) original x label
    % and just make it visible
    h.xlabel = get(axh, 'XLabel');
    % where to put it - just under the y value of the tick, and centered
    newPos = [(max(xTicks)+min(xTicks))/2, yInvisLim(1), 1];
    set( h.xlabel, 'Visible', 'on', 'Position', newPos, 'VerticalAlignment', 'top', ...
        'HorizontalAlignment', 'center' );
    % Also make it the same font size as the tick labels if it's still the default size
    if get( h.xlabel, 'FontSize') ==  defaultMATLABfontsize 
        set( h.xlabel, 'FontSize', tickFontSize )
    end
   
    
    
    % Draw the Y axis
    h.ybase = line( [xAxLoc(1) xAxLoc(1)], [min(yTicks) max(yTicks)], 'Color', yColor, ...
        'LineWidth', LineWidth, 'LineSmoothing', 'on');
    yTickLen = range( xInvisLim ) * tickLength;       
    for i = 1 : numel( yTicks )
        h.yticks(i) = line( [xAxLoc(1)-yTickLen xAxLoc(1)], [yTicks(i) yTicks(i)], 'Color', yColor, ...
            'LineWidth', LineWidth', 'LineSmoothing', 'on');
        % tick label
        h.ytickLabels(i) = text( xAxLoc(1)-yTickLen, yTicks(i), yTickLabels{i}, ...
            'Color', yColor, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'mid', ...
            'FontSize', tickFontSize );
    end
    
    
    % Draw Y label
    % pull what the text should be from the (invisible) original x label
    % and just make it visible
    h.ylabel = get(axh, 'YLabel');
    % where to put it - just under the y value of the tick, and centered
    newPos = [xInvisLim(1), (max(yTicks)+min(yTicks))/2, 1];

    set(h.ylabel, 'Visible', 'on', 'Position', newPos, 'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'center'); % note that because it's rotated, VerticalAlignment
                                          % and HorizontalAlignment refer to the counterintuitive one
    if get( h.ylabel, 'FontSize' ) == defaultMATLABfontsize 
        set( h.ylabel, 'FontSize', tickFontSize )
    end

                                          
    % Make Title Visible
    h.title = get( axh, 'Title' );
    set(h.title, 'Visible', 'on');
end



% This function uses the assignargs helper function written by Daniel J O'Shea
% (dan@djoshea.com). I've included them here to make this function self-contained.
% Please see Dan's github page for more information and his other very useful code.
% (https://github.com/djoshea)
function par = assignargs(varargin)
% par = assignargs(defaults, varargin)
%
%   Like structargs except additionally assigns values individually by their names in
%   caller.
%
%   Overwrites fields in struct defaults with those specified by:
%    - if arg(1) is a structure, the values therein
%    - the values specified in 'name', value pairs in the arguments list
%      (these values take precedence over arg(1)
%   Assigns new values or old defaults in caller workspace
%
% par = structargs(varargin)
%
%   Same functionality as above, except uses all existing variables in the 
%   calling workspace as defaults
%
% Author: Dan O'Shea (dan@djoshea.com), (c) 2008


par = structargs(varargin{:});

fields = fieldnames(par);
for i = 1:length(fields)
    assignin('caller', fields{i}, par.(fields{i}))
end

end

function par = structargs(varargin)
% par = structargs(defaults, varargin)
%
% Overwrites fields in struct defaults with those specified by:
%  - if arg(1) is a structure, the values therein
%  - the values specified in 'name', value pairs in the arguments list
%    (these values take precedence over arg(1)
%  - 
% Returns defaults with its values overwritten or new values added
%
% par = structargs(varargin)
% 
% Same functionality as above, except uses all existing variables in the 
% calling workspace as defaults
%
% Author: Dan O'Shea (dan@djoshea.com), (c) 2008

if(nargin < 1)
    error('You must provide at least 1 arguments. Call help structargs');
end

if(nargin == 1) 
    
    defaults = varargin{1};
    arg = {};
else
    defaults = varargin{1};
    arg = varargin{2:end};
end

if(iscell(defaults))
    % construct defaults from all variables in the calling workspace
    arg = defaults;
    defaults = [];
    callingWorkspaceVars = evalin('caller', 'who');
    
    for i = 1:length(callingWorkspaceVars)
        defaults.(callingWorkspaceVars{i}) = evalin('caller', callingWorkspaceVars{i});
    end
end

% no overrides?
if(isempty(arg))
    par = defaults;
    return;
end

% start with the defaults
par = defaults;

% SDS: 
if isstruct( arg )
    newval = arg;
    fields = fieldnames(newval);
    
    for i = 1:length(fields)
        par.(fields{i}) = newval.(fields{i});
    end
    
    return
end
% /SDS

% overwrite with struct values from arg(1)
if(isstruct(arg{1})) 
    newval = arg{1};
    fields = fieldnames(newval);
    
    for i = 1:length(fields)
        par.(fields{i}) = newval.(fields{i});
    end
    
    if(length(arg) > 1)
        arg = arg(2:end);
    else
        return;
    end
end

% overwrite with name/value pairs
for i = 1:2:length(arg)
    if(ischar(arg{i}))
        if(length(arg) >= i+1)
            par.(arg{i}) = arg{i+1};
        else
           warning('STRUCTARGS:argParseError', 'Cannot find value for field "%s"', arg(i));
        end
    else
       warning('STRUCTARGS:argParseError', 'Cannot parse arg(%d) as a field name', i); 
    end 
end

end


