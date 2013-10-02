% This demo shows the very basics of using SexyAxes.
%
% Created by Sergey D. Stavisky, October 2013
% sergey.d.stavisky@gmail.com
% https://github.com/sstavisk
%
%
% 



% Make some data
x = 1:100;
y = 50.*rand(100,1);

% Make a plot
plot( x, y )
xlabel('Time')
ylabel('Widgets')

fprintf('A simple plot has been generated.\nIt''s ugly...\nBut press enter to use SexyAxes to make it nicer...\n')
pause;

%% ------------------------------
%     Turn- key usage 
% -------------------------------
% All you need is the axis handle of your plot, and you're good to go!
axh = gca;
axh = SexyAxes( axh );
fprintf('\nBAM! Sexified. The command that would do this is as easy as ''SexyAxes( gca );''\n' )
fprintf('   (''gca'' just means ''get current axis'', whatever you last made or clicked on. Even better would be to keep track of your plot''s axis handle and send in that)\n')

% that's it! Let's just change to title to reflect the fact that it's now sexy
% note that the if you had a title, it's default size wouldn't change. You should use bigger fonts
% for EXTRA SEXYNESS


%%
%% ------------------------------
%     Custom setting of ticks
% ------------------------------
% By default SexyAxes just draws axis ticks at the limits of your original plot.
% You can also easily tell it where to put ticks, like so.
fprintf('\n\nYou can also easily tell it where to draw tick labels. Say you want x ticks every 25 and y ticks from 0 to 100 with 50 also labelled.\n')
fprintf('Press enter to see this applied...\n')
pause

close( get( axh, 'Parent') );
axh = axes; plot( x, y, 'Parent', axh ); xlabel('Time'); ylabel('Widgets');
axh = SexyAxes( axh, 'xTicks', [0 25 50 75 100], 'yTicks', [0 50 100] );



fprintf('Voila!\n')
fprintf('This was done with command ''SexyAxes( axh, ''xTicks'', [0 25 50 75 100], ''yTicks'', [0 50 100] );''\n' );
fprintf('Further protip: If you take a second output of SexyAxes like this: ''[axh, handles] = SexyAxes( axh )'' then you get the handles to all the tick labels and axes it created\n')
% Protip: you can also set custom string labels using the 'xTickLabels' optional argument.

fprintf('End of Demo.\n')