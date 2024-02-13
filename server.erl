-module(server).
-import(lists,[delete/2]).
-export([start/1,stop/1]).
-export([handle/2]).

-record(serverstate, {
    channels
}).
initialStateServer() -> 
    #serverstate{
        channels = []
    }.

-record(channelstate, {
    users
}).

initialStateChannel(PId) -> 
    #channelstate{
        users = [PId]
        }.
% Start a new server process with the given name
% Do not change the signature of this function.
start(ServerAtom) ->
    % TODO Implement function
    % - Spawn a new process which waits for a message, handles it, then loops infinitely
    % - Register this process to ServerAtom
    genserver:start(ServerAtom, initialStateServer(), fun handle/2).


handle(St, {join, Channel, PId}) ->
    case lists:member(Channel, St#serverstate.channels) of
        true -> 
            R = genserver:request(list_to_atom(Channel), {join, PId}),
            {reply, R, St#serverstate.channels};
        false ->
            NewChannelList = [Channel | St#serverstate.channels],
            UpdatedChannelState = St#serverstate{channels = NewChannelList},
            R = genserver:start(list_to_atom(Channel), initialStateChannel(PId), fun channelHandle/2),
            {reply, R, UpdatedChannelState}
    end.
% Stop the server process registered to the given name,
channelHandle(St, {join, PId}) ->
    io:format("du är inne i channelHandle"),
    case lists:member(PId, St#channelstate.users) of
        true -> 
            io:format("användaren finns redan!"),
            {reply, {error, user_already_joined, "User is already in this channel"}, St};
        false -> 
            io:format("försöker lägga till"),
            NewUsersList = [PId | St#channelstate.users],
            UpdatedUserList = St#channelstate{users = NewUsersList},
            {reply, ok , UpdatedUserList}
    end;
channelHandle(St, {leave, PId}) ->
    io:format("Du är inne i leave"),
    case lists:member(PId, St#channelstate.users) of
        true ->
            io:format("användaren finns i kanalen och tas bort"),
            NewUsersList = [delete(PId, St#channelstate.users)],
            UpdatedUserList = St#channelstate{users = NewUsersList},
            {reply, ok, UpdatedUserList};
        false ->
            io:format("användaren finns inte i kanalen"),
            {reply, {error, user_not_joined, "User has not joined this channel"}, St}
        end.

% together with any other associated processes
stop(ServerAtom) ->
    % TODO Implement function
    % Return ok
    Pid = whereis(ServerAtom),
case Pid of
    %ett till case som felhanterar
    _ ->
        unregister(ServerAtom),
        exit(ServerAtom, normal)
end.

