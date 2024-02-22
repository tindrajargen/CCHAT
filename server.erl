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
    genserver:start(ServerAtom, initialStateServer(), fun handle/2).

%Stops all Channels via the stop function below and then stops the ServerAtom.
stop(ServerAtom) ->
    genserver:request(ServerAtom, {stop}),
    genserver:stop(ServerAtom).

%Loops through all channels and stops them.
handle(St, {stop}) ->
lists:foreach(fun(C) -> 
    genserver:stop(list_to_atom(C)) end, St#serverstate.channels),
    {reply, ok, St#serverstate{channels = []}};

% Join function of the server. Checks if a channel exists, if not it creates a new Channel.
% If it exists it calls the Join function of the channel.
handle(St, {join, Channel, PId}) ->
    ExistingChannels = St#serverstate.channels,
    Server = list_to_atom(Channel),
    case lists:member(Channel, ExistingChannels) of
        true -> 
            R = (catch genserver:request(Server, {join, PId})),
            {reply, R, St};
        false ->        
            spawn(genserver, start,[Server,initialStateChannel(PId), fun channelHandle/2]),
            {reply, ok, St#serverstate{channels = [Channel | ExistingChannels]}}
    end.

% Adds a user to a channel, if the user already exists it does not add it.  
channelHandle(St, {join, PId}) ->
    Users = St#channelstate.users,
    case lists:member(PId, Users) of
        true -> 
            {reply, {error, user_already_joined, "User is already in this channel"}, St};
        false -> 
            {reply,ok,St#channelstate{users = [PId | Users]}}
    end;

%Makes a user leave a channel. If the user hasn't joined the channel, an error message is shown.
channelHandle(St, {leave, PId, Nick}) ->
    case lists:member(PId, St#channelstate.users) of
        true ->
            NewUsersList = lists:delete(PId, St#channelstate.users),
            UpdatedUserList = St#channelstate{users = NewUsersList},
            {reply, ok, UpdatedUserList};
        false ->
            {reply, {error, user_not_joined, "User has not joined this channel"}, St}
        end;

%The message function of the channel. It deletes the sender from the reciever list which is then looped through.
% If a user is tryging to send a message to a channel it has not joined an error message is shown.
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



       


