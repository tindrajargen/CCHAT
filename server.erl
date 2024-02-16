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
%stop the server

stop(ServerAtom) ->
    % TODO Implement function
    % Return ok
    genserver:request(ServerAtom, {stop}),
    genserver:stop(ServerAtom).


handle(St, {stop}) ->
lists:foreach(fun(C) -> 
    genserver:stop(list_to_atom(C)) end, St#serverstate.channels),
    {reply, ok, St#serverstate{channels = []}};

% serverns "join" kanal funktion
%gå med i en kanal, om den inte redan finns skapa kanalen , om den finns skickas man till kanalens join 
handle(St, {join, Channel, PId}) ->
    ExistingChannels = St#serverstate.channels,
    Server = list_to_atom(Channel),
    case lists:member(Channel, ExistingChannels) of
        true -> 
            io:format("kanalen finns, skickar till channelHandle"),
            R = (catch genserver:request(Server, {join, PId})),
            {reply, R, St};
        false ->
            io:format("skapar en ny kanal"),           
            spawn(genserver, start,[Server,initialStateChannel(PId), fun channelHandle/2]),
            {reply, ok, St#serverstate{channels = [Channel | ExistingChannels]}}
    end.

%Lägger till en användare i en kanal, om användaren redan är med läggs den inte till   
channelHandle(St, {join, PId}) ->
    Users = St#channelstate.users,
    case lists:member(PId, Users) of
        true -> 
            {reply, {error, user_already_joined, "User is already in this channel"}, St};
        false -> 
            {reply,ok,St#channelstate{users = [PId | Users]}}
    end;

channelHandle(St, {leave, PId, Nick}) ->
    case lists:member(PId, St#channelstate.users) of
        true ->
            NewUsersList = lists:delete(PId, St#channelstate.users),
            UpdatedUserList = St#channelstate{users = NewUsersList},
            {reply, ok, UpdatedUserList};
        false ->
            {reply, {error, user_not_joined, "User has not joined this channel"}, St}
        end;

    channelHandle(St, {message_send, PId, Channel, Nick, Msg}) ->
        case lists:member(PId, St#channelstate.users) of 
            true ->
                Receivers = lists:delete(PId, St#channelstate.users),
                spawn(fun() -> lists:foreach(fun(P) ->
                     genserver:request(P, {message_receive, Channel, Nick, Msg})
                end, Receivers) end),
                {reply, ok, St};
            false ->
                {reply, {error, user_not_joined, "User can not write messages in channel it has not joined"}, St}
        end.


% together with any other associated processes



       


