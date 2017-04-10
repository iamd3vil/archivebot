defmodule Archivebot.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    token = Application.fetch_env!(:slack, :api_token)

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Archivebot.Worker.start_link(arg1, arg2, arg3)
      # worker(Archivebot.Worker, [arg1, arg2, arg3]),
      supervisor(Archivebot.Repo, []),
      worker(Task, [fn -> run_migrations() end], restart: :temporary),
      worker(Slack.Bot, [Archivebot, [], token]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Archivebot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp run_migrations() do
    Logger.info("Running migrations")
    Ecto.Migrator.run(Archivebot.Repo, "#{:code.priv_dir(:archivebot)}/repo/migrations", :up, [all: true])
  end
end
