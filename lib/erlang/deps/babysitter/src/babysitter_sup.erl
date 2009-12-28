%%%-------------------------------------------------------------------
%%% File    : babysitter_sup.erl
%%% Author  : Ari Lerner
%%% Description : 
%%%
%%% Created :  Thu Dec 24 15:08:41 PST 2009
%%%-------------------------------------------------------------------

-module (babysitter_sup).
-behaviour(supervisor).

%% API
-export([
  start_link/0,
  start_child/3
]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================
start_child(Name, Command, Opts) -> 
  supervisor:start_child(babysitter_process_sup, [Name, Command, Opts]).
  
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the supervisor
%%--------------------------------------------------------------------
start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% Func: init(Args) -> {ok,  {SupFlags,  [ChildSpec]}} |
%%                     ignore                          |
%%                     {error, Reason}
%% Description: Whenever a supervisor is started using
%% supervisor:start_link/[2,3], this function is called by the new process
%% to find out about restart strategy, maximum restart frequency and child
%% specifications.
%%--------------------------------------------------------------------
init([]) ->
  AppSrv = {the_babysitter_srv,{babysitter, start_link,[]}, permanent,2000,worker,dynamic},
  % ChildrenSpecs = {
  %   babysitter_process_sup, 
  %   {supervisor, start_link, [{local, babysitter_process_sup}, babysitter_process_sup, []]},
  %   permanent, infinity, supervisor, []
  % },
  {ok,{{one_for_one,5,10}, [AppSrv]}}.

%%====================================================================
%% Internal functions
%%====================================================================