function assignans(input)
% assign and display input to base workspace in variable named 'ans'

assignin('base','ans',input);
evalin('base','ans');

end

