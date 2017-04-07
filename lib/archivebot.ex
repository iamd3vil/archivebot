defmodule Archivebot do
  use Slack
  require Logger
  alias Archivebot.{Record, Repo}

  def handle_connect(slack, state) do
    IO.puts "Connected as #{inspect slack.me}"
    {:ok, state}
  end

  def handle_event(%{type: "message", user: user_id}, %{me: %{id: user_id}}, state) do
    {:ok, state}
  end
  def handle_event(message = %{type: "message", channel: "D" <> _}, slack, state) do
    send_message("Hey. I got a message from you!. Text: #{message.text}", message.channel, slack)
    {:ok, state}
  end
  def handle_event(message = %{type: "message", user: _user_id}, slack, state) do
    Logger.info "Channel: #{message.channel}, timestamp: #{message.ts}, message: #{message.text}"
    :ok = dump_in_db(message)
    # send_message("Hey. I got a message from you.!. Text: #{message.text}", message.channel, slack)
    {:ok, state}
  end
  def handle_event(_, _, state) do
    {:ok, state}
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}

  defp dump_in_db(message) do
    username = message.user |> get_username()
    channel = message.channel |> get_channel_name()
    timestamp = 
      extract_float(message.ts) * 10_00_000
      |> convert_to_int
      |> DateTime.from_unix!(:microsecond)

    changeset = %Record{} 
    |> Record.changeset(%{
      user_id: message.user,
      username: username,
      channel: channel,
      channel_id: message.channel,
      timestamp: timestamp,
      message: message.text
    })

    if changeset.valid? == true do
      Repo.insert(changeset)
      |> case do
        {:ok, _} -> :ok
        {:error, _} -> Logger.warn "Got error inserting."
      end
    end
  end

  defp get_username(user_id) do
    Slack.Web.Users.info(user_id)
    |> Map.get("user")
    |> Map.get("name")
  end

  defp get_channel_name("C" <> _ = channel_id) do
    Slack.Web.Channels.info(channel_id)
    |> IO.inspect
    |> Map.get("channel")
    |> Map.get("name")
  end

  defp get_channel_name("G" <> _ = channel_id) do
    Slack.Web.Groups.info(channel_id)
    |> IO.inspect
    |> Map.get("group")
    |> Map.get("name")
  end

  defp extract_float(float) do
    {num, _} = Float.parse(float)
    num
  end

  defp convert_to_int(float) do
    bin = to_string(float)
    {num, _} = Integer.parse(bin)
    num
  end
end
