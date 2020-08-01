duration(a, 10).
duration(b, 20).
duration(c, 20).
duration(e, 35).
duration(d, 10).

prerequisite(b, a).
prerequisite(c, b).
prerequisite(e, a).
prerequisite(d, c).
prerequisite(d, e).

append([], X, X). 														% Append Base Case
append([X|Y], Z, [X|W]) :- append(Y,Z,W).								% Append Recursive Algorithm

getduration(Task,Duration):- 											% Find Duration of a given task
	duration(Task, Duration).

calcEF([],Temp,EF):- EF is Temp. 										% Early finish base case - store final value in EF.
	
calcEF([Head|Tail],Temp,EF):- 											% Calculate early finish.
	getduration(Head,Duration),											% Gets the duration.
	calcEF(Tail,(Temp+Duration),EF). 									% Recursive call.

isfirst(Task):-
    not(prerequisite(Task,_)).											% Checking if task is the first task of graph.

findPath([Head|Tail], L):-												% Finds path from the given task to the starting task.
    isfirst(Head),														% Check if first task.
    L = [Head|Tail].

findPath([Head|Tail], L):-												% Find path to first task in graph
    prerequisite(Head,Pre),
    append([Pre], [Head|Tail], NL),                                     % Appending each prerequisite to the list
    findPath(NL, L). 

max_l([Head],Head) :- !, true.                                          % Base case for finding Max number

max_l([Head|Tail], Max):- 
	max_l(Tail, Max), 
	Max >= Head.

max_l([Head|Tail], Head):- 												% Find Max Number in the list
	max_l(Tail, Max), 
	Head >  Max.

earlyFinish(Task,EF):-
    findall(EF, (findPath([Task], L), calcEF(L,0,EF)), NL),             % Find early finish time using all possibe paths and then find the maximum
    max_l(NL,EF).                                                       % Find Maximum EF Time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

min_l([Head],Head) :- !, true.											% Base case for finding Min number

min_l([Head|Tail], Min):- 
	min_l(Tail, Min), 
	Min =< Head.

min_l([Head|Tail], Head):- 												% Find Min Number in the list
	min_l(Tail, Min), 
	Head <  Min.

calcLS([],Temp,LS):- LS is Temp.										% Base case for calculating late start - store value in ls

calcLS([Head|Tail],Temp,LS):- 											% Calculating lateStart values
	getduration(Head,Duration),											% Get Duration
	calcLS(Tail,(Temp-Duration),LS).									% Recursive call to itself 

islast(Task):-
    not(prerequisite(_,Task)).											% Is the task last task?

findGoalPath([Head|Tail], L):-                                          % Finding the goal path
    islast(Head),                                                       % Is the task last task?
    L = [Head|Tail].

findGoalPath([Head|Tail], L):-
    prerequisite(Next,Head),
    append([Next], [Head|Tail], NL),
    findGoalPath(NL, L).                                                % Calculating the path from current to last path

lateStart(Task,LS):-													% Calculating all possible minimum values and then find the minimum
	findall(LS, (findGoalPath([Task], L), L = [Head|_], earlyFinish(Head, EF), calcLS(L,EF,LS)), NL), 
	min_l(NL,LS).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

calc_slack([],Temp,Max_slack):- max_l(Temp, Max_slack).					% Base case for calculating slack values.

calc_slack([Head|Tail],Temp, Max_slack):-								% Calculating slack values for the given list of tasks
	earlyFinish(Head,EF),												% Calculate EF 
	lateStart(Head,LS),													% Calculate LS
	duration(Head,T),													%  Calculate duration
	LF is LS + T, 
	Slack is LF - EF,
	append([Slack], Temp, NL),											% Append Calculated value to list
	calc_slack(Tail,NL, Max_slack).

maxSlack(Task, Time):-
	findall(Tasks, prerequisite(_,Tasks), Task_list), 					% Find all set of tasks
	sort(Task_list, New_list),											% Remove duplicates and sort the list
	calc_slack(New_list, [], Max_slack),                                % Calculate Max
	calc_slack([Task], [], Time),
	Max_slack = Time.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_times([],_).												        % Recursion base case - List is empty 

check_times([Head|Tail],Task):-                                         % Compare the LF and EF times.  
	earlyFinish(Head,EF),                                               % Calculate the EF
	taskLS(Head,Task,LS),												% Calculate the LS with 'Task' as last state
	duration(Head,T),                                                   % Get Duration
	LF is LS + T,                                                       % Calculate late finish
	EF = LF,                                                            % Calculate Early Finish
	check_times(Tail,Task).                                             % calculate for next

is_member([]):- !, false.

is_member([Head|Tail],Path):-                                           % Check if task is in the list
	Head = Path;
	is_member(Tail, Path).

isTask(X,Task):-                                                        % Check if task is goal task
    X = Task.											

findTaskPath([Head|Tail], Task, L):-                                    % Find path from starting node to the given task                              
    isTask(Head, Task),                                                      
    L = [Head|Tail].

findTaskPath([Head|Tail], Task, L):-
    prerequisite(Next,Head),
    append([Next], [Head|Tail], NL),
    findTaskPath(NL, Task, L). 

taskLS(X,Task,LS):-							                            % Find late start considering the given task as goal						
	findall(LS, (findTaskPath([X], Task, L), L = [Head|_], earlyFinish(Head, EF), calcLS(L,EF,LS)), NL), 
	min_l(NL,LS).

criticalPath(Task,Path):-                                               % Finds candidate Path to given task.
	findPath([Task], Path),
	check_times(Path,Task).                                             % Check if path is crtical.                             
