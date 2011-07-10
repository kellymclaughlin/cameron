%% @author Leandro Silva <leandrodoze@gmail.com>
%% @copyright 2011 Leandro Silva.

%% @doc Supervisor for the workers of the Cameron application.

-module(cameron_worker_sup).
-author('Leandro Silva <leandrodoze@gmail.com>').

-behaviour(supervisor).

% admin api
-export([start_link/0, upgrade/0]).
% public api
-export([start_child/1, stop_child/1, which_child/1, which_children/0]).
% supervisor callback
-export([init/1]).

%%
%% Admin API --------------------------------------------------------------------------------------
%%

%% @spec start_link() -> Result = {ok, Pid} | ignore | {error, Error}
%% @doc API for starting the supervisor.
start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @spec upgrade() -> ok
%% @doc Remove and add processes if necessary.
upgrade() ->
  supervisor_utility:upgrade(?MODULE).

%%
%% Public API -------------------------------------------------------------------------------------
%%

%% @spec start_child(Ticket) -> {ok, ChildPid} | {ok, ChildPid, Info} | {error, Error}
%% @dynamic Start a cameron_worker_{ShortUUID} process to diagnostic a Ticket given.
start_child(Ticket) ->
  WorkerName = build_worker_name(Ticket),

  WorkerSpec = {WorkerName, {cameron_worker, start_link, [Ticket]}, temporary, 5000, worker, dynamic},
  supervisor:start_child(cameron_worker_sup, WorkerSpec).

%% @spec stop_child(Ticket) -> ok | {error, Error}
%% @dynamic Stop a cameron_worker_{ShortUUID}.
stop_child(Ticket) ->
  WorkerName = build_worker_name(Ticket),
  
  supervisor:terminate_child(cameron_worker_sup, WorkerName),
  supervisor:delete_child(cameron_worker_sup, WorkerName).

%% @spec which_chil(Ticket) -> WorkerName | {error, Error}
%% @dynamic Which worker is handling a ticket given.
which_child(Ticket) ->
  build_worker_name(Ticket).

%% @spec which_children() -> [ChildSpec] | {error, Error}
%% @dynamic List of children workers.
which_children() ->
  supervisor:which_children(cameron_worker_sup).
  
%%
%% Supervisor Callback ----------------------------------------------------------------------------
%%

%% @spec init([]) -> SupervisorTree = {ok, {SupervisorSpec, [ChildSpec]}} | ignore
%%
%% Types:
%%
%%     SupervisorSpec = {RestartStrategy, AllowedRestarts, MaxSeconds}
%%     ChildSpec = {Id, {Module, Function, Arguments}, Restart, Shutdown, Type, ModuleList}
%%
%% @doc supervisor callback.
init([]) ->
  {ok, {{one_for_one, 10, 10}, []}}.

%%
%% Internal Functions -----------------------------------------------------------------------------
%%

build_worker_name(Ticket) ->
  WorkerName = "cameron_worker_" ++ Ticket,
  list_to_atom(WorkerName).
  